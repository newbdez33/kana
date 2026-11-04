package jp.jacky.kana.practice

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.assertFalse
import org.junit.Test

class PracticeFeedbackTest {
    @Test fun `rapid haptics are dropped without extending the gate`() {
        val gate = FeedbackPulseGate()
        assertTrue(gate.accept(0))
        assertFalse(gate.accept(100))
        assertFalse(gate.accept(179))
        assertTrue(gate.accept(180))
    }

    @Test fun `stages use the approved boundaries and cap rhythm at 120 bpm`() {
        listOf(Triple(0, 0, 0), Triple(4, 0, 0), Triple(5, 1, 0), Triple(9, 1, 0), Triple(10, 2, 80),
            Triple(19, 2, 80), Triple(20, 3, 100), Triple(29, 3, 100), Triple(30, 4, 120), Triple(100, 4, 120))
            .forEach { (streak, stage, bpm) ->
                assertEquals(stage, PracticeFeedback.stage(streak))
                assertEquals(bpm, PracticeFeedback.bpm(stage))
            }
    }

    @Test fun `record appears once per run and resets after failure`() {
        val run = PracticeFeedback(10)
        assertEquals(FeedbackKind.MILESTONE, run.correct(10).kind)
        assertEquals(FeedbackKind.RECORD, run.correct(11).kind)
        assertEquals(FeedbackKind.HIT, run.correct(12).kind)
        assertNull(run.broken(12).strength)
        assertEquals(FeedbackKind.RECORD, run.correct(13).kind)
    }

    @Test fun `haptics follow stage and milestone strength without rewarding corrections`() {
        val run = PracticeFeedback(0)
        assertEquals(FeedbackKind.HIT, run.correct(1).kind)
        assertEquals(FeedbackStrength.LIGHT, run.correct(4).strength)
        assertEquals(FeedbackStrength.MEDIUM, run.correct(5).strength)
        assertEquals(FeedbackStrength.MEDIUM, run.correct(11).strength)
        assertEquals(FeedbackStrength.HEAVY, run.correct(20).strength)
        assertEquals(FeedbackStrength.HEAVY, run.correct(40).strength)
        assertNull(FeedbackEvent(FeedbackKind.CORRECTION).strength)
    }
}
