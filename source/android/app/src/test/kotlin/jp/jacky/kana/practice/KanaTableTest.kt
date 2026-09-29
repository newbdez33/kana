package jp.jacky.kana.practice

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class KanaTableTest {
    @Test
    fun `practice pool has the 46 basic kana with unique romaji`() {
        assertEquals(46, KanaTable.practicePool.size)
        assertEquals(46, KanaTable.practicePool.map { it.romaji }.toSet().size)
    }

    @Test
    fun `rows keep the chart layout`() {
        assertEquals(11, KanaTable.rows.size)
        assertEquals(5, KanaTable.rows[0].size)
        assertNull(KanaTable.rows[7][1]) // や行 second slot is empty
        assertNull(KanaTable.rows[9][2]) // わ行 middle slot is empty
        assertEquals(1, KanaTable.rows[10].size) // ん
        assertEquals(Kana("n", "ん", "ン"), KanaTable.rows[10][0])
    }

    @Test
    fun `text picks the requested form`() {
        val ne = Kana("ne", "ね", "ネ")
        assertEquals("ne", ne.text(KanaForm.ROMAJI))
        assertEquals("ね", ne.text(KanaForm.HIRAGANA))
        assertEquals("ネ", ne.text(KanaForm.KATAKANA))
    }
}
