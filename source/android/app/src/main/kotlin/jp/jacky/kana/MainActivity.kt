package jp.jacky.kana

import android.graphics.Color
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import jp.jacky.kana.practice.PracticeViewModel
import jp.jacky.kana.ui.theme.KanaTheme

class MainActivity : ComponentActivity() {

    private val container get() = (application as KanaApplication).container
    private val practiceViewModel: PracticeViewModel by viewModels { PracticeViewModel.factory(container) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT),
        )
        setContent {
            KanaTheme { KanaApp(container = container, viewModel = practiceViewModel) }
        }
    }

    override fun onStart() {
        super.onStart()
        if (!container.coffeeStore.adsRemoved.value) container.adsManager.gatherConsent(this)
    }

    override fun onResume() {
        super.onResume()
        practiceViewModel.setInBackground(false)
    }

    override fun onPause() {
        practiceViewModel.setInBackground(true)
        super.onPause()
    }
}
