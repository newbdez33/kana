package jp.jacky.kana.testing

import kotlinx.coroutines.test.TestCoroutineScheduler
import org.junit.Assert.assertEquals
import org.junit.Test

class FakesTest {
    @Test
    fun `fake clock follows the scheduler`() {
        val scheduler = TestCoroutineScheduler()
        val clock = FakeClock(scheduler)
        scheduler.advanceTimeBy(1234)
        assertEquals(1234L, clock.nowMillis())
    }
}
