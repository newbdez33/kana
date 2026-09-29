package jp.jacky.kana.chart

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import jp.jacky.kana.MainActivity
import jp.jacky.kana.TestKanaApplication
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class KanaChartSheetTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    private lateinit var scenario: ActivityScenario<MainActivity>

    @Before
    fun launch() {
        TestKanaApplication.get().resetContainer()
        scenario = ActivityScenario.launch(MainActivity::class.java)
    }

    @After
    fun close() = scenario.close()

    @Test
    fun opensTheChartAndSwitchesToKatakana() {
        compose.onNodeWithTag("menuToggle").performClick()
        compose.onNodeWithTag("chartMenu").performClick()
        compose.onNodeWithTag("kanaChart").assertIsDisplayed()
        compose.onNodeWithText("か").assertIsDisplayed()
        compose.onNodeWithText("ka").assertIsDisplayed()
        compose.onNodeWithText("カ").assertDoesNotExist()
        compose.onNodeWithTag("chartKatakana").performClick()
        compose.onNodeWithText("カ").assertIsDisplayed()
        compose.onNodeWithText("か").assertDoesNotExist()
    }
}
