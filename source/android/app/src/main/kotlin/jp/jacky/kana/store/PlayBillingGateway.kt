package jp.jacky.kana.store

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClient.BillingResponseCode
import com.android.billingclient.api.BillingClient.ProductType
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

class PlayBillingGateway(context: Context, private val productId: String) : BillingGateway {

    private val _updates = MutableSharedFlow<PurchaseUpdate>(extraBufferCapacity = 8)
    override val purchaseUpdates: SharedFlow<PurchaseUpdate> = _updates.asSharedFlow()

    private val client: BillingClient = BillingClient.newBuilder(context)
        .setListener { result, purchases ->
            _updates.tryEmit(PurchaseUpdate(result.responseCode, purchases.orEmpty().toRecords()))
        }
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
        .enableAutoServiceReconnection()
        .build()

    override suspend fun connect(): Int {
        if (client.isReady) return BillingResponseCode.OK
        return suspendCancellableCoroutine { continuation ->
            client.startConnection(object : BillingClientStateListener {
                override fun onBillingSetupFinished(result: BillingResult) {
                    if (continuation.isActive) continuation.resume(result.responseCode)
                }

                override fun onBillingServiceDisconnected() {
                    // Auto reconnection is enabled on the client.
                }
            })
        }
    }

    override suspend fun queryCoffeePurchases(): List<PurchaseRecord>? = suspendCancellableCoroutine { continuation ->
        val params = QueryPurchasesParams.newBuilder().setProductType(ProductType.INAPP).build()
        client.queryPurchasesAsync(params) { result, purchases ->
            val records = if (result.responseCode == BillingResponseCode.OK) purchases.toRecords() else null
            if (continuation.isActive) continuation.resume(records)
        }
    }

    override suspend fun queryCoffeeProduct(): CoffeeProduct? = suspendCancellableCoroutine { continuation ->
        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(
                listOf(
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(productId)
                        .setProductType(ProductType.INAPP)
                        .build()
                )
            )
            .build()
        client.queryProductDetailsAsync(params) { result, details ->
            val product = details.productDetailsList.firstOrNull { it.productId == productId }
            val price = product?.oneTimePurchaseOfferDetails?.formattedPrice
            val coffee = if (result.responseCode == BillingResponseCode.OK && product != null && price != null) {
                CoffeeProduct(price, product)
            } else {
                null
            }
            if (continuation.isActive) continuation.resume(coffee)
        }
    }

    override suspend fun acknowledge(token: String): Int = suspendCancellableCoroutine { continuation ->
        val params = AcknowledgePurchaseParams.newBuilder().setPurchaseToken(token).build()
        client.acknowledgePurchase(params) { result ->
            if (continuation.isActive) continuation.resume(result.responseCode)
        }
    }

    override fun launchBillingFlow(activity: Activity, product: CoffeeProduct): Int {
        val details = product.details ?: return BillingResponseCode.ITEM_UNAVAILABLE
        val params = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(
                listOf(BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(details).build())
            )
            .build()
        return client.launchBillingFlow(activity, params).responseCode
    }

    private fun List<Purchase>.toRecords(): List<PurchaseRecord> = filter { productId in it.products }.map {
        PurchaseRecord(
            purchased = it.purchaseState == Purchase.PurchaseState.PURCHASED,
            pending = it.purchaseState == Purchase.PurchaseState.PENDING,
            acknowledged = it.isAcknowledged,
            token = it.purchaseToken,
        )
    }
}
