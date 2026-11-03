package jp.jacky.kana.practice

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import jp.jacky.kana.ads.AdsManager
import jp.jacky.kana.di.AppContainer
import jp.jacky.kana.feedback.FeedbackPlayer
import jp.jacky.kana.stats.StatStore
import jp.jacky.kana.stats.StatSummary
import jp.jacky.kana.store.CoffeeStore
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

enum class Sheet { CHART, COFFEE }

data class PracticeUiState(
    val question: Question,
    val revealCorrect: Boolean = false,
    val stats: StatSummary = StatSummary(),
    val menuExpanded: Boolean = false,
    val sheet: Sheet? = null,
    val bannerRequested: Boolean = false,
    val bannerAllowed: Boolean = false,
    val adsRemoved: Boolean = false,
    val privacyOptionsAvailable: Boolean = false,
    val feedbackSettings: FeedbackSettings = FeedbackSettings(),
    val feedback: FeedbackEvent? = null,
    val feedbackSequence: Long = 0,
    val beatSequence: Long = 0,
    val remainingFraction: Float = 1f,
    val paused: Boolean = false,
) {
    val showBanner: Boolean get() = bannerRequested && bannerAllowed
}

/**
 * The practice loop: one question at a time with a five second limit. Time spent with the menu,
 * a sheet, or the app in the background is not answer time.
 */
class PracticeViewModel(
    private val engine: QuestionEngine,
    private val statStore: StatStore,
    private val feedbackPlayer: FeedbackPlayer,
    private val clock: Clock,
    coffeeStore: CoffeeStore,
    adsManager: AdsManager,
    private val timeLimitMillis: Long = 5_000L,
) : ViewModel() {

    private val _state = MutableStateFlow(PracticeUiState(question = engine.next(), stats = statStore.summary.value))
    val state: StateFlow<PracticeUiState> = _state.asStateFlow()

    private var questionStartedAt = clock.nowMillis()
    private var pausedAt: Long? = null
    private var inBackground = false
    private var consentFormVisible = false
    private var timerJob: Job? = null
    private val feedbackRun = PracticeFeedback(statStore.summary.value.bestStreak)
    private var hasInteracted = false
    private var lastBeat = clock.nowMillis()

    init {
        viewModelScope.launch {
            statStore.summary.collect { summary -> _state.update { it.copy(stats = summary) } }
        }
        viewModelScope.launch {
            combine(coffeeStore.adsRemoved, adsManager.isReady, adsManager.privacyOptionsRequired) { removed, ready, privacy ->
                Triple(removed, ready, privacy)
            }.collect { (removed, ready, privacy) ->
                _state.update {
                    it.copy(
                        adsRemoved = removed,
                        bannerAllowed = ready && !removed,
                        bannerRequested = it.bannerRequested && !removed,
                        privacyOptionsAvailable = privacy && !removed,
                    )
                }
            }
        }
        viewModelScope.launch {
            adsManager.consentFormVisible.collect { visible ->
                consentFormVisible = visible
                refreshPause()
            }
        }
        startTimer()
    }

    fun answer(index: Int) {
        val current = _state.value
        if (inBackground || consentFormVisible || current.sheet != null) return
        val chosen = current.question.answers.getOrNull(index) ?: return
        if (current.menuExpanded) setMenuExpanded(false)
        hasInteracted = true
        val isCorrect = chosen.kana == current.question.kana
        if (current.revealCorrect) {
            emitFeedback(FeedbackEvent(FeedbackKind.CORRECTION))
            if (isCorrect) nextQuestion()
            return
        }
        if (clock.nowMillis() - questionStartedAt >= timeLimitMillis) {
            onTimeout()
            return
        }
        cancelTimer()
        val costSeconds = (clock.nowMillis() - questionStartedAt) / 1000.0
        statStore.recordStreak(isCorrect)
        statStore.recordAnswer(costSeconds)
        if (isCorrect) {
            nextQuestion()
            emitFeedback(feedbackRun.correct(statStore.summary.value.currentStreak))
        } else {
            reveal()
            emitFeedback(feedbackRun.broken(statStore.summary.value.bestStreak))
        }
    }

    fun setFeedbackSettings(settings: FeedbackSettings) {
        feedbackPlayer.stop()
        lastBeat = clock.nowMillis()
        _state.update { it.copy(feedbackSettings = settings, feedback = null) }
    }

    private fun emitFeedback(event: FeedbackEvent) {
        _state.update { it.copy(feedback = event, feedbackSequence = it.feedbackSequence + 1) }
        feedbackPlayer.play(event, _state.value.feedbackSettings)
    }

    fun toggleMenu() = setMenuExpanded(!_state.value.menuExpanded)

    fun openChart() = setSheet(Sheet.CHART)

    fun openCoffee() = setSheet(Sheet.COFFEE)

    fun closeSheet() = setSheet(null)

    fun setInBackground(background: Boolean) {
        inBackground = background
        refreshPause()
    }

    fun bannerFailed() {
        _state.update { it.copy(bannerRequested = false) }
    }

    private fun onTimeout() {
        if (isPaused() || _state.value.revealCorrect) return
        cancelTimer()
        statStore.recordStreak(false)
        reveal()
        emitFeedback(feedbackRun.broken(statStore.summary.value.bestStreak))
    }

    private fun reveal() {
        feedbackPlayer.stop()
        _state.update { it.copy(revealCorrect = true, bannerRequested = true, remainingFraction = 0f) }
    }

    private fun nextQuestion() {
        _state.update { it.copy(question = engine.next(), revealCorrect = false, bannerRequested = false, remainingFraction = 1f) }
        questionStartedAt = clock.nowMillis()
        pausedAt = if (isPaused()) questionStartedAt else null
        startTimer()
    }

    private fun setMenuExpanded(expanded: Boolean) {
        _state.update { it.copy(menuExpanded = expanded) }
        refreshPause()
    }

    private fun setSheet(sheet: Sheet?) {
        _state.update { it.copy(sheet = sheet) }
        refreshPause()
    }

    private fun isPaused(): Boolean =
        _state.value.menuExpanded || _state.value.sheet != null || inBackground || consentFormVisible

    private fun refreshPause() {
        val paused = isPaused()
        val now = clock.nowMillis()
        _state.update { it.copy(paused = paused, feedback = if (paused) null else it.feedback) }
        val pauseStart = pausedAt
        if (paused && pauseStart == null) {
            pausedAt = now
            cancelTimer()
            feedbackPlayer.stop()
        } else if (!paused && pauseStart != null) {
            questionStartedAt += now - pauseStart
            pausedAt = null
            lastBeat = now
            startTimer()
        }
    }

    private fun startTimer() {
        cancelTimer()
        if (pausedAt != null || _state.value.revealCorrect) return
        timerJob = viewModelScope.launch {
            while (true) {
                val now = clock.nowMillis()
                val remaining = timeLimitMillis - (now - questionStartedAt)
                if (remaining <= 0) { onTimeout(); break }
                _state.update { it.copy(remainingFraction = (remaining.toFloat() / timeLimitMillis).coerceIn(0f, 1f)) }
                val bpm = PracticeFeedback.bpm(PracticeFeedback.stage(statStore.summary.value.currentStreak))
                val settings = _state.value.feedbackSettings
                if (hasInteracted && settings.sound && settings.rhythm && bpm > 0 && now - lastBeat >= 60_000L / bpm) {
                    lastBeat = now
                    feedbackPlayer.beat()
                    _state.update { it.copy(beatSequence = it.beatSequence + 1) }
                }
                delay(minOf(50, remaining))
            }
        }
    }

    override fun onCleared() {
        feedbackPlayer.stop()
    }

    private fun cancelTimer() {
        timerJob?.cancel()
        timerJob = null
    }

    companion object {
        fun factory(container: AppContainer): ViewModelProvider.Factory = viewModelFactory {
            initializer {
                PracticeViewModel(
                    engine = QuestionEngine(container.random),
                    statStore = container.statStore,
                    feedbackPlayer = container.feedbackPlayer,
                    clock = container.clock,
                    coffeeStore = container.coffeeStore,
                    adsManager = container.adsManager,
                    timeLimitMillis = container.timeLimitMillis,
                )
            }
        }
    }
}
