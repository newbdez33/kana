package jp.jacky.kana.practice

/** Monotonic time in milliseconds; injected so tests can drive it. */
fun interface Clock {
    fun nowMillis(): Long
}
