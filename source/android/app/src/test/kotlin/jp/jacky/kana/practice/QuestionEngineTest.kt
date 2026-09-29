package jp.jacky.kana.practice

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

class QuestionEngineTest {
    private fun forms(kana: Kana) = KanaForm.entries.map { kana.text(it) }

    @Test
    fun `every question has one correct answer and three distinct distractors`() {
        val engine = QuestionEngine(Random(1))
        repeat(500) {
            val q = engine.next()
            assertEquals(4, q.answers.size)
            assertTrue(q.correctIndex in 0..3)
            assertEquals(q.kana, q.answers[q.correctIndex].kana)
            assertEquals(1, q.answers.count { it.kana == q.kana })
            assertEquals(4, q.answers.map { it.kana }.toSet().size)
        }
    }

    @Test
    fun `prompt and labels are written in one of the three forms`() {
        val engine = QuestionEngine(Random(2))
        repeat(500) {
            val q = engine.next()
            assertTrue(q.prompt in forms(q.kana))
            assertNotEquals(q.prompt, q.answers[q.correctIndex].label)
            q.answers.forEach { assertTrue(it.label in forms(it.kana)) }
        }
    }

    @Test
    fun `every kana in the pool appears as a question`() {
        val engine = QuestionEngine(Random(3))
        val seen = (1..5000).map { engine.next().kana }.toSet()
        assertEquals(KanaTable.practicePool.toSet(), seen)
    }

    @Test
    fun `the same seed produces the same questions`() {
        val a = QuestionEngine(Random(7))
        val b = QuestionEngine(Random(7))
        repeat(20) { assertEquals(a.next(), b.next()) }
    }
}
