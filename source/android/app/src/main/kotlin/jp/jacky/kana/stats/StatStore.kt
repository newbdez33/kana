package jp.jacky.kana.stats

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.nio.file.Files
import java.nio.file.StandardCopyOption

data class StatSummary(
    val totalCount: Int = 0,
    val totalCost: Double = 0.0,
    val recentCosts: List<Double> = emptyList(),
    val currentStreak: Int = 0,
    val bestStreak: Int = 0,
) {
    val averageSeconds: Double? get() = if (totalCount > 0) totalCost / totalCount else null
    val recentSeconds: Double? get() = if (recentCosts.isEmpty()) null else recentCosts.average()

    fun toJson(): String = JSONObject()
        .put("totalCount", totalCount)
        .put("totalCost", totalCost)
        .put("recentCosts", JSONArray(recentCosts))
        .put("currentStreak", currentStreak)
        .put("bestStreak", bestStreak)
        .toString()

    companion object {
        const val RECENT_LIMIT = 10
        const val TIME_LIMIT_SECONDS = 5.0

        fun fromJson(text: String): StatSummary {
            val json = JSONObject(text)
            val recent = json.optJSONArray("recentCosts")
            return StatSummary(
                totalCount = json.optInt("totalCount"),
                totalCost = json.optDouble("totalCost", 0.0),
                recentCosts = if (recent == null) emptyList() else List(recent.length()) { recent.getDouble(it) },
                currentStreak = json.optInt("currentStreak"),
                bestStreak = json.optInt("bestStreak"),
            )
        }
    }
}

/** Practice statistics kept in a small JSON file. Writes are best effort. */
class StatStore(
    private val file: File,
    private val timeLimitSeconds: Double = StatSummary.TIME_LIMIT_SECONDS,
) {
    private val _summary = MutableStateFlow(load())
    val summary: StateFlow<StatSummary> = _summary.asStateFlow()

    /** Records an answer given within the time limit; costs outside (0, limit] are ignored. */
    fun recordAnswer(costSeconds: Double) {
        if (costSeconds <= 0.0 || costSeconds > timeLimitSeconds) return
        update { current ->
            current.copy(
                totalCount = current.totalCount + 1,
                totalCost = current.totalCost + costSeconds,
                recentCosts = (current.recentCosts + costSeconds).takeLast(StatSummary.RECENT_LIMIT),
            )
        }
    }

    fun recordStreak(correct: Boolean) {
        update { current ->
            val streak = if (correct) current.currentStreak + 1 else 0
            current.copy(currentStreak = streak, bestStreak = maxOf(current.bestStreak, streak))
        }
    }

    private fun update(transform: (StatSummary) -> StatSummary) {
        val next = transform(_summary.value)
        _summary.value = next
        save(next)
    }

    private fun load(): StatSummary = try {
        if (file.isFile) StatSummary.fromJson(file.readText()) else StatSummary()
    } catch (e: Exception) {
        StatSummary()
    }

    private fun save(summary: StatSummary) {
        try {
            file.parentFile?.mkdirs()
            val temp = File(file.parentFile, file.name + ".tmp")
            temp.writeText(summary.toJson())
            Files.move(temp.toPath(), file.toPath(), StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
        } catch (e: Exception) {
            // Losing one record is acceptable.
        }
    }
}
