package jp.jacky.kana

import android.app.Application
import android.content.Context
import androidx.test.runner.AndroidJUnitRunner

class KanaTestRunner : AndroidJUnitRunner() {
    override fun newApplication(cl: ClassLoader, className: String, context: Context): Application =
        super.newApplication(cl, TestKanaApplication::class.java.name, context)
}
