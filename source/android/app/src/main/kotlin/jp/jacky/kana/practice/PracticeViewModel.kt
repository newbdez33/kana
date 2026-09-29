package jp.jacky.kana.practice

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import jp.jacky.kana.ads.AdsManager
import jp.jacky.kana.di.AppContainer
import jp.jacky.kana.sound.SoundPlayer
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
    private val sound: SoundPlayer,
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
        val chosen = current.question.answers.getOrNull(index) ?: return
        if (current.menuExpanded) setMenuExpanded(false)
        val isCorrect = chosen.kana == current.question.kana
        if (current.revealCorrect) {
            if (isCorrect) {
                sound.playCorrect()
                nextQuestion()
            } else {
                sound.playIncorrect()
            }
            return
        }
        cancelTimer()
        val costSeconds = (clock.nowMillis() - questionStartedAt) / 1000.0
        statStore.recordStreak(isCorrect)
        statStore.recordAnswer(costSeconds)
        if (isCorrect) {
            sound.playCorrect()
            nextQuestion()
        } else {
            sound.playIncorrect()
            reveal()
        }
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
        statStore.recordStreak(false)
        sound.playIncorrect()
        reveal()
    }

    private fun reveal() {
        _state.update { it.copy(revealCorrect = true, bannerRequested = true) }
    }

    private fun nextQuestion() {
        _state.update { it.copy(question = engine.next(), revealCorrect = false, bannerRequested = false) }
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
        val pauseStart = pausedAt
        if (paused && pauseStart == null) {
            pausedAt = now
            cancelTimer()
        } else if (!paused && pauseStart != null) {
            questionStartedAt += now - pauseStart
            pausedAt = null
            startTimer()
        }
    }

    private fun startTimer() {
        cancelTimer()
        if (pausedAt != null || _state.value.revealCorrect) return
        val remaining = timeLimitMillis - (clock.nowMillis() - questionStartedAt)
        timerJob = viewModelScope.launch {
            delay(remaining.coerceAtLeast(1))
            onTimeout()
        }
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
                    sound = container.soundPlayer,
                    clock = container.clock,
                    coffeeStore = container.coffeeStore,
                    adsManager = container.adsManager,
                    timeLimitMillis = container.timeLimitMillis,
                )
            }
        }
    }
}
