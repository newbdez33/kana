package jp.jacky.kana

import android.content.res.Configuration
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test
import org.junit.runner.RunWith
import java.util.Locale

@RunWith(AndroidJUnit4::class)
class LocalizationTest {
    private fun string(locale: Locale, id: Int): String {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val configuration = Configuration(context.resources.configuration).apply { setLocale(locale) }
        return context.createConfigurationContext(configuration).getString(id)
    }

    @Test
    fun everyLanguageTranslatesTheChartTitle() {
        val english = string(Locale.ENGLISH, R.string.chart)
        assertEquals("Kana chart", english)
        listOf("ja", "zh-Hans", "zh-Hant", "ko", "de", "fr", "es").forEach { tag ->
            assertNotEquals(tag, english, string(Locale.forLanguageTag(tag), R.string.chart))
        }
    }

    @Test
    fun restoreMessageMentionsGoogle() {
        listOf("en", "ja", "zh-Hans", "zh-Hant", "ko", "de", "fr", "es").forEach { tag ->
            val text = string(Locale.forLanguageTag(tag), R.string.restore_none_message)
            assert(text.contains("Google")) { "$tag: $text" }
            assert(!text.contains("Apple")) { "$tag: $text" }
        }
    }

    @Test
    fun formatArgumentsWork() {
        assertEquals("Last 10 avg.", string(Locale.ENGLISH, R.string.stat_recent).format(10))
        assertEquals("1.23s", string(Locale.ENGLISH, R.string.stat_seconds).format("1.23"))
    }
}
