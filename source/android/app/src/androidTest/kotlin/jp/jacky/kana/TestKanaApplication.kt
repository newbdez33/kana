package jp.jacky.kana

import androidx.test.core.app.ApplicationProvider
import jp.jacky.kana.di.AppContainer

class TestKanaApplication : KanaApplication() {
    override fun createContainer(): AppContainer = FakeAppContainer(this)

    /** Gives every test a fresh set of fakes. Call before launching the activity. */
    fun resetContainer(): FakeAppContainer = FakeAppContainer(this).also { container = it }

    companion object {
        fun get(): TestKanaApplication = ApplicationProvider.getApplicationContext()
    }
}
