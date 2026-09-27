package jp.jacky.kana.coffee

import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onAllNodesWithText
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
class CoffeeSheetTest {
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

    private fun openSheet() {
        compose.onNodeWithTag("menuToggle").performClick()
        compose.onNodeWithTag("coffeeMenu").performClick()
        compose.onNodeWithTag("coffeeSheet").assertIsDisplayed()
    }

    private fun waitForText(text: String) {
        compose.waitUntil(5_000) { compose.onAllNodesWithText(text).fetchSemanticsNodes().isNotEmpty() }
    }

    @Test
    fun purchaseShowsThePriceThenTheThankYou() {
        openSheet()
        waitForText("Buy me a coffee · ¥300")
        compose.onNodeWithTag("coffeeTitle").assert(hasText("Buy me a coffee"))
        compose.onNodeWithTag("coffeePurchase").assertIsEnabled().performClick()
        waitForText("Thanks for the coffee")
        compose.onNodeWithTag("coffeeTitle").assert(hasText("Thanks for the coffee"))
        compose.onNodeWithTag("coffeePurchase").assert(hasText("Back to practice"))
        compose.onNodeWithTag("coffeeRestore").assertDoesNotExist()
        compose.onNodeWithTag("coffeePurchase").performClick()
        compose.onNodeWithTag("coffeeSheet").assertDoesNotExist()
    }

    @Test
    fun restoreWithoutPurchaseShowsTheAlert() {
        openSheet()
        waitForText("Buy me a coffee · ¥300")
        compose.onNodeWithTag("coffeeRestore").performClick()
        waitForText("Nothing to restore")
        compose.onNodeWithText("No previous purchase was found for this Google account.").assertIsDisplayed()
        compose.onNodeWithText("OK").performClick()
        compose.onNodeWithText("Nothing to restore").assertDoesNotExist()
    }
}
