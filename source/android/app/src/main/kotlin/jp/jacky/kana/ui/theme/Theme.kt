package jp.jacky.kana.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import jp.jacky.kana.R

/** Colors ported from UIColor+Kana.swift. The app is light only. */
object KanaColors {
    val accent = Color(0xFFC93332)
    val secondary = Color(0xFF6E6963)
    val paper = Color(0xFFFCFAF5)
    val keyRed = Color(0xFFD0141B)
    val keyGray = Color(0xFFF7F7F7)
    val ink = Color(0xFF171412)
    val incorrect = Color(0xFFF08F8F)
    val divider = ink.copy(alpha = 0.09f)
}

object KanaFonts {
    val hosohuwa = FontFamily(Font(R.font.hosohuwa))
}

private val LightColors = lightColorScheme(
    primary = KanaColors.accent,
    onPrimary = Color.White,
    background = KanaColors.keyGray,
    onBackground = KanaColors.ink,
    surface = KanaColors.paper,
    onSurface = KanaColors.ink,
    onSurfaceVariant = KanaColors.secondary,
    secondary = KanaColors.secondary,
)

@Composable
fun KanaTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = LightColors, content = content)
}
