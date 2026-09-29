package jp.jacky.kana.stats

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class StatStoreTest {
    @get:Rule
    val tmp = TemporaryFolder()

    private fun file() = File(tmp.root, "stats.json")

    @Test
    fun `empty store has no averages`() {
        val store = StatStore(file())
        assertEquals(0, store.summary.value.totalCount)
        assertNull(store.summary.value.averageSeconds)
        assertNull(store.summary.value.recentSeconds)
    }

    @Test
    fun `record answer updates count and averages`() {
        val store = StatStore(file())
        store.recordAnswer(1.5)
        store.recordAnswer(2.5)
        assertEquals(2, store.summary.value.totalCount)
        assertEquals(2.0, store.summary.value.averageSeconds!!, 1e-9)
        assertEquals(2.0, store.summary.value.recentSeconds!!, 1e-9)
    }

    @Test
    fun `answers outside the time limit are ignored`() {
        val store = StatStore(file())
        store.recordAnswer(0.0)
        store.recordAnswer(-1.0)
        store.recordAnswer(5.01)
        assertEquals(0, store.summary.value.totalCount)
        store.recordAnswer(5.0)
        assertEquals(1, store.summary.value.totalCount)
    }

    @Test
    fun `recent costs keep the last ten`() {
        val store = StatStore(file())
        (1..12).forEach { store.recordAnswer(it / 10.0) }
        assertEquals((3..12).map { it / 10.0 }, store.summary.value.recentCosts)
    }

    @Test
    fun `streak counts and best streak persist`() {
        val store = StatStore(file())
        store.recordStreak(true)
        store.recordStreak(true)
        assertEquals(2, store.summary.value.currentStreak)
        assertEquals(2, store.summary.value.bestStreak)
        store.recordStreak(false)
        assertEquals(0, store.summary.value.currentStreak)
        assertEquals(2, store.summary.value.bestStreak)
    }

    @Test
    fun `values survive a reload`() {
        StatStore(file()).apply {
            recordAnswer(1.0)
            recordStreak(true)
        }
        val reloaded = StatStore(file()).summary.value
        assertEquals(StatSummary(totalCount = 1, totalCost = 1.0, recentCosts = listOf(1.0), currentStreak = 1, bestStreak = 1), reloaded)
    }

    @Test
    fun `a corrupt file starts from zero`() {
        file().writeText("{not json")
        assertEquals(StatSummary(), StatStore(file()).summary.value)
    }

    @Test
    fun `record keeps working when the file cannot be written`() {
        val blocked = File(tmp.newFile("blocker"), "stats.json") // parent is a file, so writes fail
        val store = StatStore(blocked)
        store.recordAnswer(1.0)
        assertEquals(1, store.summary.value.totalCount)
    }
}
