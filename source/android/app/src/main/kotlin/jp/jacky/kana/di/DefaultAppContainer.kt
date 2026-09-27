package jp.jacky.kana.di

import android.app.Application
import android.os.SystemClock
import jp.jacky.kana.BuildConfig
import jp.jacky.kana.ads.AdsManager
import jp.jacky.kana.ads.GoogleAdsManager
import jp.jacky.kana.practice.Clock
import jp.jacky.kana.share.AndroidShareActions
import jp.jacky.kana.share.ShareActions
import jp.jacky.kana.sound.SoundPlayer
import jp.jacky.kana.sound.SoundPoolPlayer
import jp.jacky.kana.stats.StatStore
import jp.jacky.kana.store.CoffeeStore
import jp.jacky.kana.store.PlayBillingGateway
import jp.jacky.kana.store.PlayCoffeeStore
import jp.jacky.kana.store.PrefsAdsRemovedStorage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import java.io.File
import kotlin.random.Random

class DefaultAppContainer(app: Application) : AppContainer {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override val random: Random = Random.Default
    override val clock: Clock = Clock { SystemClock.elapsedRealtime() }
    override val timeLimitMillis: Long = 5_000L
    override val statStore: StatStore = StatStore(File(app.filesDir, "stats.json"))
    override val coffeeStore: CoffeeStore = PlayCoffeeStore(
        gateway = PlayBillingGateway(app, BuildConfig.COFFEE_PRODUCT_ID),
        storage = PrefsAdsRemovedStorage(app),
        scope = scope,
    ).also { it.start() }
    override val adsManager: AdsManager = GoogleAdsManager(app, scope, BuildConfig.ADS_DEBUG_GEOGRAPHY_EEA)
    override val soundPlayer: SoundPlayer = SoundPoolPlayer(app)
    override val shareActions: ShareActions = AndroidShareActions(app)
}
