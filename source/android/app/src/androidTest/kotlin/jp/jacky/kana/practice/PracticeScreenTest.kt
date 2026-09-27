package jp.jacky.kana.practice

import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.hasStateDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onNodeWithTag
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
import kotlin.random.Random

@RunWith(AndroidJUnit4::class)
class PracticeScreenTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    private lateinit var scenario: ActivityScenario<MainActivity>
    private lateinit var expected: QuestionEngine

    @Before
    fun launch() {
        TestKanaApplication.get().resetContainer()
        expected = QuestionEngine(Random(42))
        scenario = ActivityScenario.launch(MainActivity::class.java)
    }

    @After
    fun close() = scenario.close()

    @Test
    fun showsTheFirstQuestionAndCountsACorrectAnswer() {
        val first = expected.next()
        compose.onNodeWithTag("questionLabel").assertTextEquals(first.prompt)
        (0..3).forEach { compose.onNodeWithTag("answer$it").assert(hasText(first.answers[it].label)) }
        compose.onNodeWithTag("answer${first.correctIndex}").performClick()
        val second = expected.next()
        compose.onNodeWithTag("questionLabel").assertTextEquals(second.prompt)
        compose.onNodeWithTag("statTotal").assert(hasText("1"))
        compose.onNodeWithTag("statBest").assert(hasText("1"))
    }

    @Test
    fun wrongAnswerHighlightsTheCorrectOne() {
        val first = expected.next()
        val wrong = (0..3).first { it != first.correctIndex }
        compose.onNodeWithTag("answer$wrong").performClick()
        compose.onNodeWithTag("questionLabel").assertTextEquals(first.prompt)
        compose.onNodeWithTag("answer${first.correctIndex}").assert(hasStateDescription("correct"))
        compose.onNodeWithTag("statBest").assert(hasText("0"))
    }

    @Test
    fun menuTogglesAndShowsTheActions() {
        compose.onNodeWithTag("chartMenu").assertDoesNotExist()
        compose.onNodeWithTag("menuToggle").performClick()
        compose.onNodeWithTag("chartMenu").assertIsDisplayed()
        compose.onNodeWithTag("coffeeMenu").assertIsDisplayed()
        compose.onNodeWithTag("moreMenu").assertIsDisplayed()
        compose.onNodeWithTag("menuToggle").performClick()
        compose.onNodeWithTag("chartMenu").assertDoesNotExist()
    }
}
