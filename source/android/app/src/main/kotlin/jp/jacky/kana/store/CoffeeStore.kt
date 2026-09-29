package jp.jacky.kana.store

import android.app.Activity
import android.content.Context
import kotlinx.coroutines.flow.StateFlow

enum class PurchaseOutcome { PURCHASED, CANCELLED, PENDING }

sealed class StoreException(message: String) : Exception(message) {
    class ProductUnavailable : StoreException("The coffee product is unavailable")
    class Billing(val responseCode: Int, val debugMessage: String) :
        StoreException("Billing error $responseCode: $debugMessage")
}

/** "Buy me a coffee" one-time purchase that removes ads. */
interface CoffeeStore {
    val adsRemoved: StateFlow<Boolean>
    /** Localized price text, or null while unknown. */
    val price: StateFlow<String?>
    suspend fun loadProduct()
    suspend fun purchase(activity: Activity): PurchaseOutcome
    /** Returns true when a previous purchase was found. */
    suspend fun restore(): Boolean
}

interface AdsRemovedStorage {
    fun read(): Boolean
    fun write(value: Boolean)
}

class PrefsAdsRemovedStorage(context: Context) : AdsRemovedStorage {
    private val prefs = context.getSharedPreferences("kana", Context.MODE_PRIVATE)
    override fun read(): Boolean = prefs.getBoolean(KEY, false)
    override fun write(value: Boolean) {
        prefs.edit().putBoolean(KEY, value).apply()
    }

    private companion object {
        const val KEY = "user.purchase.adsRemoved"
    }
}
