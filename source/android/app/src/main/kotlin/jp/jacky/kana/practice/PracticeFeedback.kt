package jp.jacky.kana.practice

enum class FeedbackKind { HIT, MILESTONE, RECORD, BROKEN, CORRECTION }
enum class FeedbackStrength { LIGHT, MEDIUM, HEAVY }

data class FeedbackEvent(val kind: FeedbackKind, val streak: Int = 0, val stage: Int = 0) {
    val strength: FeedbackStrength? get() = when (kind) {
        FeedbackKind.BROKEN, FeedbackKind.CORRECTION -> null
        FeedbackKind.RECORD -> FeedbackStrength.HEAVY
        FeedbackKind.MILESTONE -> if (stage >= 3) FeedbackStrength.HEAVY else FeedbackStrength.MEDIUM
        FeedbackKind.HIT -> if (stage >= 2) FeedbackStrength.MEDIUM else FeedbackStrength.LIGHT
    }
}

class PracticeFeedback(bestStreak: Int) {
    private var recordTarget = bestStreak
    private var recordShown = false

    fun correct(streak: Int): FeedbackEvent {
        val record = recordTarget >= 5 && streak > recordTarget && !recordShown
        if (record) recordShown = true
        val milestone = streak >= 5 && (streak == 5 || streak % 10 == 0)
        return FeedbackEvent(when {
            record -> FeedbackKind.RECORD
            milestone -> FeedbackKind.MILESTONE
            else -> FeedbackKind.HIT
        }, streak, stage(streak))
    }

    fun broken(bestStreak: Int): FeedbackEvent {
        recordTarget = bestStreak
        recordShown = false
        return FeedbackEvent(FeedbackKind.BROKEN)
    }

    companion object {
        fun stage(streak: Int): Int = listOf(5, 10, 20, 30).count { streak >= it }
        fun bpm(stage: Int): Int = listOf(0, 0, 80, 100, 120)[stage.coerceIn(0, 4)]
    }
}

data class FeedbackSettings(
    val sound: Boolean = true,
    val rhythm: Boolean = true,
    val haptics: Boolean = true,
    val reducedMotion: Boolean = false,
)

class FeedbackPulseGate {
    private var lastPulse = -180L

    fun accept(timeMillis: Long): Boolean {
        if (timeMillis - lastPulse < 180) return false
        lastPulse = timeMillis
        return true
    }
}
