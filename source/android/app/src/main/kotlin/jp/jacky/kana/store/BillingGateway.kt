package jp.jacky.kana.store

import android.app.Activity
import com.android.billingclient.api.ProductDetails
import kotlinx.coroutines.flow.SharedFlow

/** The coffee product with its Play details; the details stay internal so fakes need none. */
class CoffeeProduct(val price: String, internal val details: ProductDetails?)

data class PurchaseRecord(
    val purchased: Boolean,
    val pending: Boolean,
    val acknowledged: Boolean,
    val token: String,
)

/** One PurchasesUpdatedListener callback, reduced to the coffee product. */
data class PurchaseUpdate(val responseCode: Int, val records: List<PurchaseRecord>)

/** Thin wrapper over BillingClient so the store logic can be unit tested. Response codes are BillingClient.BillingResponseCode values. */
interface BillingGateway {
    val purchaseUpdates: SharedFlow<PurchaseUpdate>
    suspend fun connect(): Int
    suspend fun queryCoffeePurchases(): List<PurchaseRecord>
    suspend fun queryCoffeeProduct(): CoffeeProduct?
    suspend fun acknowledge(token: String): Int
    fun launchBillingFlow(activity: Activity, product: CoffeeProduct): Int
}
