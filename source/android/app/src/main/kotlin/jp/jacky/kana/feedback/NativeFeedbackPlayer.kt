package jp.jacky.kana.feedback

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Build
import android.os.SystemClock
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import jp.jacky.kana.R
import jp.jacky.kana.practice.FeedbackEvent
import jp.jacky.kana.practice.FeedbackKind
import jp.jacky.kana.practice.FeedbackSettings
import jp.jacky.kana.practice.FeedbackStrength
import jp.jacky.kana.practice.FeedbackPulseGate
import java.util.concurrent.ConcurrentHashMap

/** Short effects mix with other audio. Missed loads and haptics are never queued. */
class NativeFeedbackPlayer(private val context: Context) : FeedbackPlayer {
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_GAME)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
    private val pool = SoundPool.Builder().setMaxStreams(2).setAudioAttributes(attributes).build()
    private val ready = ConcurrentHashMap.newKeySet<Int>()
    private val vibrator = context.getSystemService(Vibrator::class.java)
    private var effectStream = 0
    private var beatStream = 0
    private val pulseGate = FeedbackPulseGate()

    init { pool.setOnLoadCompleteListener { _, id, status -> if (status == 0) ready.add(id) } }

    private fun load(id: Int) = pool.load(context, id, 1)
    private val hits = listOf(R.raw.feedback_hit_0, R.raw.feedback_hit_1, R.raw.feedback_hit_2, R.raw.feedback_hit_3, R.raw.feedback_hit_4).map(::load)
    private val milestones = listOf(R.raw.feedback_milestone_0, R.raw.feedback_milestone_1, R.raw.feedback_milestone_2, R.raw.feedback_milestone_3, R.raw.feedback_milestone_4).map(::load)
    private val records = listOf(R.raw.feedback_record_0, R.raw.feedback_record_1, R.raw.feedback_record_2, R.raw.feedback_record_3, R.raw.feedback_record_4).map(::load)
    private val broken = load(R.raw.feedback_broken)
    private val correction = load(R.raw.feedback_correction)
    private val beat = load(R.raw.feedback_beat)

    override fun play(event: FeedbackEvent, settings: FeedbackSettings) {
        if (settings.sound) {
            val stage = event.stage.coerceIn(0, 4)
            val id = when (event.kind) {
                FeedbackKind.HIT -> hits[stage]
                FeedbackKind.MILESTONE -> milestones[stage]
                FeedbackKind.RECORD -> records[stage]
                FeedbackKind.BROKEN -> broken
                FeedbackKind.CORRECTION -> correction
            }
            pool.stop(effectStream)
            effectStream = playSound(id)
        }
        if (settings.haptics) event.strength?.let(::pulse)
    }

    private fun playSound(id: Int): Int = if (id in ready) pool.play(id, 1f, 1f, 1, 0, 1f) else 0

    override fun beat() {
        pool.stop(beatStream)
        beatStream = playSound(beat)
    }

    @Suppress("DEPRECATION")
    private fun pulse(strength: FeedbackStrength) {
        val now = SystemClock.elapsedRealtime()
        if (vibrator?.hasVibrator() != true) return
        if (Settings.System.getInt(context.contentResolver, Settings.System.HAPTIC_FEEDBACK_ENABLED, 1) == 0) return
        if (!pulseGate.accept(now)) return
        val effect = if (Build.VERSION.SDK_INT >= 29) {
            VibrationEffect.createPredefined(when (strength) {
                FeedbackStrength.LIGHT -> VibrationEffect.EFFECT_TICK
                FeedbackStrength.MEDIUM -> VibrationEffect.EFFECT_CLICK
                FeedbackStrength.HEAVY -> VibrationEffect.EFFECT_HEAVY_CLICK
            })
        } else {
            val duration = when (strength) { FeedbackStrength.LIGHT -> 12L; FeedbackStrength.MEDIUM -> 20L; FeedbackStrength.HEAVY -> 30L }
            val amplitude = if (!vibrator.hasAmplitudeControl()) VibrationEffect.DEFAULT_AMPLITUDE else when (strength) {
                FeedbackStrength.LIGHT -> 70; FeedbackStrength.MEDIUM -> 140; FeedbackStrength.HEAVY -> 220
            }
            VibrationEffect.createOneShot(duration, amplitude)
        }
        try {
            if (Build.VERSION.SDK_INT >= 33) {
                vibrator.vibrate(effect, VibrationAttributes.Builder().setUsage(VibrationAttributes.USAGE_TOUCH).build())
            } else {
                vibrator.vibrate(effect, AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION).build())
            }
        } catch (_: SecurityException) {
            // Visual and audio feedback still work when vibration is unavailable.
        }
    }

    override fun stop() {
        pool.stop(effectStream)
        pool.stop(beatStream)
        vibrator?.cancel()
    }
}
