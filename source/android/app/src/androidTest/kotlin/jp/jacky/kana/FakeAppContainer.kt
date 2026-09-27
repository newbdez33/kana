package jp.jacky.kana

import android.app.Application
import android.os.SystemClock
import jp.jacky.kana.di.AppContainer
import jp.jacky.kana.practice.Clock
import jp.jacky.kana.stats.StatStore
import jp.jacky.kana.testing.FakeAdsManager
import jp.jacky.kana.testing.FakeCoffeeStore
import jp.jacky.kana.testing.FakeShareActions
import jp.jacky.kana.testing.FakeSoundPlayer
import java.io.File
import kotlin.random.Random

class FakeAppContainer(app: Application, seed: Int = 42) : AppContainer {
    override val random: Random = Random(seed)
    override val clock: Clock = Clock { SystemClock.elapsedRealtime() }
    override val timeLimitMillis: Long = 60_000L
    override val statStore = StatStore(File(app.cacheDir, "test-stats-${System.nanoTime()}.json"), timeLimitSeconds = 60.0)
    override val coffeeStore = FakeCoffeeStore()
    override val adsManager = FakeAdsManager()
    override val soundPlayer = FakeSoundPlayer()
    override val shareActions = FakeShareActions()
}
