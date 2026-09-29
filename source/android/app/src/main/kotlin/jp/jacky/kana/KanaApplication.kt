package jp.jacky.kana

import android.app.Application
import jp.jacky.kana.di.AppContainer
import jp.jacky.kana.di.DefaultAppContainer

open class KanaApplication : Application() {
    lateinit var container: AppContainer
        protected set

    override fun onCreate() {
        super.onCreate()
        container = createContainer()
    }

    protected open fun createContainer(): AppContainer = DefaultAppContainer(this)
}
