package jp.jacky.kana

import android.graphics.Bitmap
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assume.assumeTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

/** Opt-in store captures use the app UI with deterministic local data. */
@RunWith(AndroidJUnit4::class)
class StoreScreenshotTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    @Test
    fun captureStoreScreens() {
        assumeTrue(InstrumentationRegistry.getArguments().getString("storeScreenshots") == "true")
        val app = TestKanaApplication.get()
        val container = app.resetContainer()
        repeat(48) {
            container.statStore.recordAnswer(1.8)
            container.statStore.recordStreak(it % 12 != 0)
        }
        ActivityScenario.launch(MainActivity::class.java).use {
            capture("02-practice.png")
            compose.onNodeWithTag("menuToggle").performClick()
            capture("03-menu.png")
            compose.onNodeWithTag("chartMenu").performClick()
            compose.onNodeWithTag("kanaChart").assertIsDisplayed()
            capture("05-chart.png")
        }
        ActivityScenario.launch(MainActivity::class.java).use {
            compose.onNodeWithTag("menuToggle").performClick()
            compose.onNodeWithTag("coffeeMenu").performClick()
            compose.onNodeWithTag("coffeeSheet").assertIsDisplayed()
            capture("04-coffee.png")
        }
    }

    private fun capture(name: String) {
        compose.waitForIdle()
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val directory = File(instrumentation.targetContext.getExternalFilesDir(null), "store")
        check(directory.isDirectory || directory.mkdirs())
        val bitmap = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
        File(directory, name).outputStream().use { output ->
            check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, output))
        }
        bitmap.recycle()
    }
}
