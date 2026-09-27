package jp.jacky.kana.testing

import android.app.Activity
import jp.jacky.kana.ads.AdsManager
import jp.jacky.kana.practice.Clock
import jp.jacky.kana.share.ShareActions
import jp.jacky.kana.sound.SoundPlayer
import jp.jacky.kana.store.AdsRemovedStorage
import jp.jacky.kana.store.BillingGateway
import jp.jacky.kana.store.CoffeeProduct
import jp.jacky.kana.store.CoffeeStore
import jp.jacky.kana.store.PurchaseOutcome
import jp.jacky.kana.store.PurchaseRecord
import jp.jacky.kana.store.PurchaseUpdate
import jp.jacky.kana.store.StoreException
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestCoroutineScheduler

class FakeSoundPlayer : SoundPlayer {
    var correctCount = 0
    var incorrectCount = 0
    override fun playCorrect() { correctCount++ }
    override fun playIncorrect() { incorrectCount++ }
}

class FakeClock(private val scheduler: TestCoroutineScheduler) : Clock {
    override fun nowMillis(): Long = scheduler.currentTime
}

class FakeCoffeeStore(initialAdsRemoved: Boolean = false, var productPrice: String? = "¥300") : CoffeeStore {
    override val adsRemoved = MutableStateFlow(initialAdsRemoved)
    override val price = MutableStateFlow<String?>(null)
    var purchaseOutcome = PurchaseOutcome.PURCHASED
    var purchaseError: StoreException? = null
    var restoreResult = false
    var loadCount = 0

    override suspend fun loadProduct() {
        loadCount++
        price.value = productPrice
    }

    override suspend fun purchase(activity: Activity): PurchaseOutcome {
        purchaseError?.let { throw it }
        if (purchaseOutcome == PurchaseOutcome.PURCHASED) adsRemoved.value = true
        return purchaseOutcome
    }

    override suspend fun restore(): Boolean {
        if (restoreResult) adsRemoved.value = true
        return restoreResult
    }
}

class FakeAdsManager : AdsManager {
    override val isReady = MutableStateFlow(false)
    override val privacyOptionsRequired = MutableStateFlow(false)
    var gatherConsentCalls = 0
    var showPrivacyOptionsCalls = 0
    override fun gatherConsent(activity: Activity) { gatherConsentCalls++ }
    override fun showPrivacyOptions(activity: Activity) { showPrivacyOptionsCalls++ }
}

class FakeShareActions(private val feedbackAvailable: Boolean = true) : ShareActions {
    var shareCalls = 0
    var feedbackCalls = 0
    override fun share(activity: Activity) { shareCalls++ }
    override fun canSendFeedback(): Boolean = feedbackAvailable
    override fun sendFeedback(activity: Activity) { feedbackCalls++ }
}

class InMemoryAdsRemovedStorage(private var value: Boolean = false) : AdsRemovedStorage {
    override fun read(): Boolean = value
    override fun write(value: Boolean) { this.value = value }
}

class FakeBillingGateway : BillingGateway {
    override val purchaseUpdates = MutableSharedFlow<PurchaseUpdate>(extraBufferCapacity = 8)
    var connectResult = 0 // BillingResponseCode.OK
    var purchases: List<PurchaseRecord> = emptyList()
    var product: CoffeeProduct? = CoffeeProduct("¥300", null)
    var launchResult = 0
    /** Runs inside launchBillingFlow, so tests can emit the Play callback. */
    var onLaunch: (() -> Unit)? = null
    val acknowledged = mutableListOf<String>()
    var connectCalls = 0

    override suspend fun connect(): Int { connectCalls++; return connectResult }
    override suspend fun queryCoffeePurchases(): List<PurchaseRecord> = purchases
    override suspend fun queryCoffeeProduct(): CoffeeProduct? = product
    override suspend fun acknowledge(token: String): Int { acknowledged += token; return 0 }
    override fun launchBillingFlow(activity: Activity, product: CoffeeProduct): Int {
        onLaunch?.invoke()
        return launchResult
    }
}
