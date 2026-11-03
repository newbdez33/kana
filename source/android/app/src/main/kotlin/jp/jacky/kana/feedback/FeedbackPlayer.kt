package jp.jacky.kana.feedback

import jp.jacky.kana.practice.FeedbackEvent
import jp.jacky.kana.practice.FeedbackSettings

interface FeedbackPlayer {
    fun play(event: FeedbackEvent, settings: FeedbackSettings)
    fun beat()
    fun stop()
}
