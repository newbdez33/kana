package jp.jacky.kana.practice

import androidx.compose.foundation.layout.size
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.unit.dp
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class QuestionAlignmentTest {
    @get:Rule val compose = createComposeRule()

    @Test
    fun centersVisibleGlyphsForKanaAndRomaji() {
        val prompt = mutableStateOf("mo")
        val height = mutableStateOf(320.dp)
        val kana = KanaTable.practicePool.first()
        compose.setContent {
            QuestionArea(
                state = PracticeUiState(Question(kana, prompt.value, emptyList(), 0)),
                modifier = Modifier.size(360.dp, height.value),
            )
        }
        for (areaHeight in listOf(320.dp, 180.dp)) {
            for (text in listOf("mo", "shi", "a", "ふ", "あ", "ニ", "く", "を")) {
                compose.runOnIdle { prompt.value = text; height.value = areaHeight }
                val pixels = compose.onNodeWithTag("questionLabel").captureToImage().toPixelMap()
                var left = pixels.width
                var top = pixels.height
                var right = -1
                var bottom = -1
                for (y in 0 until pixels.height) for (x in 0 until pixels.width) {
                    val color = pixels[x, y]
                    if (color.alpha > 0.75f && color.red < 0.2f && color.green < 0.2f && color.blue < 0.2f) {
                        left = minOf(left, x)
                        top = minOf(top, y)
                        right = maxOf(right, x)
                        bottom = maxOf(bottom, y)
                    }
                }
                assertTrue("$text must remain visible", right >= left && bottom >= top)
                assertEquals("$text vertical center at $areaHeight", pixels.height / 2f, (top + bottom + 1) / 2f, 1.5f)
                assertEquals("$text horizontal center at $areaHeight", pixels.width / 2f, (left + right + 1) / 2f, 1.5f)
                assertTrue("$text must not touch the top or bottom edge", top > 0 && bottom < pixels.height - 1)
            }
        }
    }
}
