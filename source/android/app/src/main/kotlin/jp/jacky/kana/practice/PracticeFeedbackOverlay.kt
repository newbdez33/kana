package jp.jacky.kana.practice

import android.animation.ValueAnimator
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import jp.jacky.kana.R
import jp.jacky.kana.ui.theme.KanaColors
import kotlinx.coroutines.delay

internal val stageNames = listOf(R.string.feedback_stage0, R.string.feedback_stage1, R.string.feedback_stage2,
    R.string.feedback_stage3, R.string.feedback_stage4)

@Composable
fun PracticeFeedbackOverlay(state: PracticeUiState) {
    val stage = PracticeFeedback.stage(state.stats.currentStreak)
    val pulse = remember { Animatable(0f) }
    val beat = remember { Animatable(0f) }
    var lastBeat by remember { mutableLongStateOf(state.beatSequence) }
    var message by remember { mutableStateOf<FeedbackEvent?>(null) }
    val reduced = state.feedbackSettings.reducedMotion || !ValueAnimator.areAnimatorsEnabled()
    LaunchedEffect(state.feedbackSequence, state.paused, reduced, state.feedback) {
        pulse.snapTo(0f)
        message = if (state.paused) null else state.feedback
        if (message != null) {
            if (!reduced && message?.strength != null) {
                pulse.snapTo(1f)
                pulse.animateTo(0f, tween(250))
                delay(400)
            } else delay(650)
            message = null
        }
    }
    LaunchedEffect(state.beatSequence, state.paused, reduced) {
        beat.snapTo(0f)
        val newBeat = state.beatSequence != lastBeat
        lastBeat = state.beatSequence
        if (!state.paused && !reduced && newBeat) {
            beat.snapTo(1f)
            beat.animateTo(0f, tween(250))
        }
    }
    Box(Modifier.fillMaxSize().graphicsLayer { alpha = if (state.paused) 0.65f else 1f }) {
        Canvas(Modifier.fillMaxSize()) {
            val radius = minOf(size.width * 0.32f, size.height / 2 - 44.dp.toPx()).coerceAtLeast(0f)
            drawCircle(KanaColors.accent.copy(alpha = (0.035f + stage * 0.025f + pulse.value * 0.18f + beat.value * 0.06f).coerceAtMost(1f)),
                radius, style = Stroke((1 + stage).dp.toPx()))
        }
        Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 10.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(stringResource(R.string.feedback_combo, state.stats.currentStreak), color = KanaColors.accent,
                    fontSize = 11.sp, fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f).testTag("currentStreak").graphicsLayer {
                        scaleX = 1 + pulse.value * 0.08f; scaleY = scaleX
                    })
                Text(stringResource(stageNames[stage]), color = KanaColors.accent, fontSize = 11.sp,
                    fontWeight = FontWeight.SemiBold, modifier = Modifier.testTag("feedbackStage"))
            }
            Spacer(Modifier.height(5.dp))
            LinearProgressIndicator(progress = { state.remainingFraction }, modifier = Modifier.fillMaxWidth().height(2.dp),
                color = if (!state.paused && !state.revealCorrect && state.remainingFraction < 0.4f && stage >= 2) KanaColors.accent else KanaColors.secondary,
                trackColor = KanaColors.divider, drawStopIndicator = {})
        }
        message?.let { event ->
            val key = when (event.kind) {
                FeedbackKind.RECORD -> R.string.feedback_record
                FeedbackKind.MILESTONE -> stageNames[event.stage]
                FeedbackKind.BROKEN -> R.string.feedback_try_again
                FeedbackKind.CORRECTION -> R.string.feedback_correction
                FeedbackKind.HIT -> R.string.feedback_combo
            }
            Text(stringResource(key, event.streak), color = KanaColors.accent, fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center,
                modifier = Modifier.align(Alignment.BottomCenter).padding(horizontal = 20.dp, vertical = 8.dp)
                    .testTag("feedbackMessage").semantics { liveRegion = LiveRegionMode.Polite })
        }
    }
}
