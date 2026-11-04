package jp.jacky.kana.practice

import android.graphics.Paint
import android.graphics.Matrix
import android.graphics.Path
import android.graphics.RectF
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.text
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.unit.dp
import androidx.core.content.res.ResourcesCompat
import jp.jacky.kana.R
import jp.jacky.kana.ui.theme.KanaColors

@Composable
internal fun QuestionGlyph(prompt: String) {
    val context = LocalContext.current
    val typeface = remember(context) { ResourcesCompat.getFont(context, R.font.hosohuwa) }
    Spacer(
        Modifier.fillMaxSize()
            .testTag("questionLabel")
            .semantics { text = AnnotatedString(prompt) }
            .drawWithCache {
                val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    this.typeface = typeface
                    color = KanaColors.ink.toArgb()
                    textSize = 155.dp.toPx()
                    isSubpixelText = true
                }
                val path = Path()
                paint.getTextPath(prompt, 0, prompt.length, 0f, 0f, path)
                val bounds = RectF()
                path.computeBounds(bounds, true)
                val maxWidth = minOf(size.width, 240.dp.toPx())
                val maxHeight = minOf(size.height, (size.height - 80.dp.toPx()).coerceAtLeast(40.dp.toPx()))
                val scale = minOf(1f, maxWidth / bounds.width().coerceAtLeast(1f), maxHeight / bounds.height().coerceAtLeast(1f))
                // The font's line box has unequal empty space around kana and romaji.
                path.transform(Matrix().apply {
                    setScale(scale, scale)
                    postTranslate(size.width / 2 - bounds.centerX() * scale, size.height / 2 - bounds.centerY() * scale)
                })
                onDrawBehind { drawContext.canvas.nativeCanvas.drawPath(path, paint) }
            },
    )
}
