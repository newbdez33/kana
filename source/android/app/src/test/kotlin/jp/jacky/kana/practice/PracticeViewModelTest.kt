package jp.jacky.kana.practice

import jp.jacky.kana.stats.StatStore
import jp.jacky.kana.testing.FakeAdsManager
import jp.jacky.kana.testing.FakeClock
import jp.jacky.kana.testing.FakeCoffeeStore
import jp.jacky.kana.testing.FakeFeedbackPlayer
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File
import kotlin.random.Random

@OptIn(ExperimentalCoroutinesApi::class)
class PracticeViewModelTest {
    @get:Rule
    val tmp = TemporaryFolder()

    private val dispatcher = StandardTestDispatcher()
    private val sound = FakeFeedbackPlayer()
    private val coffee = FakeCoffeeStore()
    private val ads = FakeAdsManager().apply { isReady.value = true }
    private lateinit var statStore: StatStore

    @Before
    fun setUp() {
        Dispatchers.setMain(dispatcher)
        statStore = StatStore(File(tmp.root, "stats.json"))
    }

    @After
    fun tearDown() = Dispatchers.resetMain()

    private fun TestScope.viewModel() = PracticeViewModel(
        engine = QuestionEngine(Random(1)),
        statStore = statStore,
        feedbackPlayer = sound,
        clock = FakeClock(testScheduler),
        coffeeStore = coffee,
        adsManager = ads,
    ).also { runCurrent() }

    private fun PracticeUiState.wrongIndex() = (0..3).first { it != question.correctIndex }

    @Test
    fun `tap at deadline before timer callback cannot extend streak`() = runTest(dispatcher) {
        val vm = viewModel()
        advanceTimeBy(5000)
        vm.answer(vm.state.value.question.correctIndex)
        runCurrent()
        assertTrue(vm.state.value.revealCorrect)
        assertEquals(0, vm.state.value.stats.currentStreak)
    }

    @Test
    fun `answers are ignored while a sheet or background pauses practice`() = runTest(dispatcher) {
        val vm = viewModel()
        val question = vm.state.value.question
        vm.openChart()
        vm.answer(question.correctIndex)
        vm.closeSheet()
        vm.setInBackground(true)
        vm.answer(question.correctIndex)
        runCurrent()
        assertEquals(question, vm.state.value.question)
        assertEquals(0, vm.state.value.stats.currentStreak)
    }

    @Test
    fun `rhythm stops during pauses and sound settings apply on resume`() = runTest(dispatcher) {
        val vm = viewModel()
        repeat(10) {
            advanceTimeBy(100)
            vm.answer(vm.state.value.question.correctIndex)
            runCurrent()
        }
        advanceTimeBy(800)
        runCurrent()
        assertTrue(sound.beatCount > 0)
        vm.toggleMenu()
        val beats = sound.beatCount
        advanceTimeBy(10_000)
        runCurrent()
        assertEquals(beats, sound.beatCount)
        assertNull(vm.state.value.feedback)
        vm.setFeedbackSettings(FeedbackSettings(sound = false))
        vm.toggleMenu()
        advanceTimeBy(800)
        runCurrent()
        assertEquals(beats, sound.beatCount)
        assertFalse(vm.state.value.revealCorrect)
    }

    @Test
    fun `correcting a timeout has no haptic and no new record`() = runTest(dispatcher) {
        val vm = viewModel()
        advanceTimeBy(5001)
        runCurrent()
        vm.answer(vm.state.value.question.correctIndex)
        runCurrent()
        assertEquals(FeedbackKind.CORRECTION, sound.events.last().kind)
        assertNull(sound.events.last().strength)
        assertEquals(0, vm.state.value.stats.currentStreak)
    }

    @Test
    fun `correct answer records the cost, extends the streak, and moves on`() = runTest(dispatcher) {
        val vm = viewModel()
        val first = vm.state.value.question
        advanceTimeBy(1500)
        vm.answer(first.correctIndex)
        runCurrent()
        val state = vm.state.value
        assertNotEquals(first, state.question)
        assertFalse(state.revealCorrect)
        assertEquals(1, state.stats.totalCount)
        assertEquals(1.5, state.stats.recentSeconds!!, 1e-9)
        assertEquals(1, state.stats.currentStreak)
        assertEquals(1, state.stats.bestStreak)
        assertEquals(FeedbackKind.HIT, sound.events.last().kind)
    }

    @Test
    fun `wrong answer reveals the correct one, requests the banner, and resets the streak`() = runTest(dispatcher) {
        val vm = viewModel()
        advanceTimeBy(1000)
        vm.answer(vm.state.value.question.correctIndex)
        runCurrent()
        advanceTimeBy(1000)
        val question = vm.state.value.question
        vm.answer(vm.state.value.wrongIndex())
        runCurrent()
        val state = vm.state.value
        assertEquals(question, state.question)
        assertTrue(state.revealCorrect)
        assertTrue(state.bannerRequested)
        assertTrue(state.showBanner)
        assertEquals(2, state.stats.totalCount)
        assertEquals(0, state.stats.currentStreak)
        assertEquals(1, state.stats.bestStreak)
        assertEquals(FeedbackKind.BROKEN, sound.events.last().kind)
    }

    @Test
    fun `timeout counts as wrong without a statistic`() = runTest(dispatcher) {
        val vm = viewModel()
        advanceTimeBy(5001)
        runCurrent()
        val state = vm.state.value
        assertTrue(state.revealCorrect)
        assertTrue(state.bannerRequested)
        assertEquals(0, state.stats.totalCount)
        assertEquals(FeedbackKind.BROKEN, sound.events.last().kind)
    }

    @Test
    fun `timeout fires at exactly the limit`() = runTest(dispatcher) {
        val vm = viewModel()
        advanceTimeBy(4999)
        runCurrent()
        assertFalse(vm.state.value.revealCorrect)
        advanceTimeBy(1)
        runCurrent()
        assertTrue(vm.state.value.revealCorrect)
        // A tap now is handled as a reveal-state tap: no statistic, no streak.
        vm.answer(vm.state.value.question.correctIndex)
        runCurrent()
        assertEquals(0, vm.state.value.stats.totalCount)
        assertEquals(0, vm.state.value.stats.currentStreak)
        assertFalse(vm.state.value.revealCorrect)
    }

    @Test
    fun `after a reveal the correct answer moves on without counting`() = runTest(dispatcher) {
        val vm = viewModel()
        advanceTimeBy(1000)
        vm.answer(vm.state.value.wrongIndex())
        runCurrent()
        val revealed = vm.state.value.question
        vm.answer(revealed.correctIndex)
        runCurrent()
        val state = vm.state.value
        assertNotEquals(revealed, state.question)
        assertFalse(state.revealCorrect)
        assertFalse(state.bannerRequested)
        assertEquals(1, state.stats.totalCount)
        assertEquals(0, state.stats.currentStreak)
        assertEquals(FeedbackKind.CORRECTION, sound.events.last().kind)
    }

    @Test
    fun `double tap on a wrong answer records one answer`() = runTest(dispatcher) {
        val vm = viewModel()
        advanceTimeBy(1000)
        val wrong = vm.state.value.wrongIndex()
        vm.answer(wrong)
        vm.answer(wrong)
        runCurrent()
        val state = vm.state.value
        assertTrue(state.revealCorrect)
        assertEquals(1, state.stats.totalCount)
        assertEquals(0, state.stats.currentStreak)
        assertEquals(listOf(FeedbackKind.BROKEN, FeedbackKind.CORRECTION), sound.events.map { it.kind })
    }

    @Test
    fun `menu pauses the timer and paused time is not answer time`() = runTest(dispatcher) {
        val vm = viewModel()
        vm.toggleMenu()
        runCurrent()
        assertTrue(vm.state.value.menuExpanded)
        advanceTimeBy(10_000)
        runCurrent()
        assertFalse(vm.state.value.revealCorrect)
        vm.toggleMenu()
        runCurrent()
        advanceTimeBy(1000)
        vm.answer(vm.state.value.question.correctIndex)
        runCurrent()
        assertEquals(1.0, vm.state.value.stats.recentSeconds!!, 1e-9)
    }

    @Test
    fun `sheets and background pause the timer`() = runTest(dispatcher) {
        val vm = viewModel()
        vm.openChart()
        runCurrent()
        assertEquals(Sheet.CHART, vm.state.value.sheet)
        advanceTimeBy(10_000)
        vm.closeSheet()
        runCurrent()
        assertNull(vm.state.value.sheet)
        vm.setInBackground(true)
        advanceTimeBy(10_000)
        runCurrent()
        assertFalse(vm.state.value.revealCorrect)
        vm.setInBackground(false)
        advanceTimeBy(5001)
        runCurrent()
        assertTrue(vm.state.value.revealCorrect)
    }

    @Test
    fun `consent form pauses the timer`() = runTest(dispatcher) {
        val vm = viewModel()
        ads.consentFormVisible.value = true
        runCurrent()
        advanceTimeBy(10_000)
        runCurrent()
        assertFalse(vm.state.value.revealCorrect)
        ads.consentFormVisible.value = false
        runCurrent()
        advanceTimeBy(4_999)
        runCurrent()
        assertFalse(vm.state.value.revealCorrect)
        advanceTimeBy(2)
        runCurrent()
        assertTrue(vm.state.value.revealCorrect)
    }

    @Test
    fun `answering collapses the menu`() = runTest(dispatcher) {
        val vm = viewModel()
        vm.toggleMenu()
        runCurrent()
        vm.answer(vm.state.value.question.correctIndex)
        runCurrent()
        assertFalse(vm.state.value.menuExpanded)
    }

    @Test
    fun `banner stays hidden until ads are ready`() = runTest(dispatcher) {
        ads.isReady.value = false
        val vm = viewModel()
        advanceTimeBy(1000)
        vm.answer(vm.state.value.wrongIndex())
        runCurrent()
        assertTrue(vm.state.value.bannerRequested)
        assertFalse(vm.state.value.showBanner)
        ads.isReady.value = true
        runCurrent()
        assertTrue(vm.state.value.showBanner)
    }

    @Test
    fun `removing ads hides the banner and the privacy entry`() = runTest(dispatcher) {
        ads.privacyOptionsRequired.value = true
        val vm = viewModel()
        runCurrent()
        assertTrue(vm.state.value.privacyOptionsAvailable)
        advanceTimeBy(1000)
        vm.answer(vm.state.value.wrongIndex())
        runCurrent()
        assertTrue(vm.state.value.showBanner)
        coffee.adsRemoved.value = true
        runCurrent()
        val state = vm.state.value
        assertTrue(state.adsRemoved)
        assertFalse(state.showBanner)
        assertFalse(state.bannerRequested)
        assertFalse(state.privacyOptionsAvailable)
    }

    @Test
    fun `banner failure collapses the slot`() = runTest(dispatcher) {
        val vm = viewModel()
        advanceTimeBy(1000)
        vm.answer(vm.state.value.wrongIndex())
        runCurrent()
        vm.bannerFailed()
        runCurrent()
        assertFalse(vm.state.value.showBanner)
    }
}
