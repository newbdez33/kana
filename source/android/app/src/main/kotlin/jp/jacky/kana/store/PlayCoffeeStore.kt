package jp.jacky.kana.store

import android.app.Activity
import com.android.billingclient.api.BillingClient.BillingResponseCode
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

/** Coffee purchase backed by Play Billing through a [BillingGateway]. */
class PlayCoffeeStore(
    private val gateway: BillingGateway,
    private val storage: AdsRemovedStorage,
    private val scope: CoroutineScope,
) : CoffeeStore {

    private val _adsRemoved = MutableStateFlow(storage.read())
    override val adsRemoved: StateFlow<Boolean> = _adsRemoved.asStateFlow()

    private val _price = MutableStateFlow<String?>(null)
    override val price: StateFlow<String?> = _price.asStateFlow()

    private var product: CoffeeProduct? = null
    private val acknowledgedTokens = mutableSetOf<String>()

    /** Call once at launch: listens for purchase updates, refreshes the entitlement, loads the price. */
    fun start() {
        scope.launch {
            gateway.purchaseUpdates.collect { update ->
                if (update.responseCode == BillingResponseCode.OK) applyRecords(update.records, fromQuery = false)
            }
        }
        scope.launch {
            // Play may be unreachable at launch: keep the cached entitlement and retry on the next
            // launch or on restore.
            try {
                refreshEntitlement()
            } catch (e: StoreException) {
                // keep the cached value
            }
            loadProduct()
        }
    }

    override suspend fun loadProduct() {
        if (gateway.connect() != BillingResponseCode.OK) return
        product = gateway.queryCoffeeProduct()
        _price.value = product?.price
    }

    override suspend fun purchase(activity: Activity): PurchaseOutcome {
        if (product == null) loadProduct()
        val current = product ?: throw StoreException.ProductUnavailable()
        return coroutineScope {
            // Subscribe before launching so a fast callback is not missed.
            val update = async(start = CoroutineStart.UNDISPATCHED) { gateway.purchaseUpdates.first() }
            val launch = gateway.launchBillingFlow(activity, current)
            if (launch != BillingResponseCode.OK) {
                update.cancel()
                throw StoreException.Billing(launch, "launchBillingFlow")
            }
            val result = update.await()
            when {
                result.responseCode == BillingResponseCode.OK && result.records.any { it.purchased } -> {
                    applyRecords(result.records, fromQuery = false)
                    PurchaseOutcome.PURCHASED
                }
                result.responseCode == BillingResponseCode.OK && result.records.any { it.pending } -> PurchaseOutcome.PENDING
                result.responseCode == BillingResponseCode.OK -> PurchaseOutcome.CANCELLED
                result.responseCode == BillingResponseCode.USER_CANCELED -> PurchaseOutcome.CANCELLED
                result.responseCode == BillingResponseCode.ITEM_ALREADY_OWNED -> {
                    refreshEntitlement()
                    if (_adsRemoved.value) PurchaseOutcome.PURCHASED
                    else throw StoreException.Billing(result.responseCode, "already owned but not found")
                }
                else -> throw StoreException.Billing(result.responseCode, "purchase")
            }
        }
    }

    override suspend fun restore(): Boolean {
        refreshEntitlement()
        return _adsRemoved.value
    }

    /** Asks Play for the coffee purchase; throws [StoreException.Billing] when Play cannot answer. */
    private suspend fun refreshEntitlement() {
        val connect = gateway.connect()
        if (connect != BillingResponseCode.OK) throw StoreException.Billing(connect, "connect")
        val records = gateway.queryCoffeePurchases()
            ?: throw StoreException.Billing(BillingResponseCode.ERROR, "queryPurchases")
        applyRecords(records, fromQuery = true)
    }

    /** Acknowledges new purchases and updates the entitlement. A full query may also revoke it. */
    private suspend fun applyRecords(records: List<PurchaseRecord>, fromQuery: Boolean) {
        val purchased = records.filter { it.purchased }
        for (record in purchased) {
            if (!record.acknowledged && acknowledgedTokens.add(record.token)) gateway.acknowledge(record.token)
        }
        if (purchased.isNotEmpty()) setAdsRemoved(true) else if (fromQuery) setAdsRemoved(false)
    }

    private fun setAdsRemoved(value: Boolean) {
        if (_adsRemoved.value == value) return
        _adsRemoved.value = value
        storage.write(value)
    }
}
