package jp.jacky.kana.sound

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import jp.jacky.kana.R

/** Plays the two short effects without taking audio focus, so other audio keeps playing. */
class SoundPoolPlayer(context: Context) : SoundPlayer {
    private val pool = SoundPool.Builder()
        .setMaxStreams(2)
        .setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
        )
        .build()
    private val correct = pool.load(context, R.raw.correct, 1)
    private val incorrect = pool.load(context, R.raw.incorrect, 1)

    override fun playCorrect() {
        pool.play(correct, 1f, 1f, 1, 0, 1f)
    }

    override fun playIncorrect() {
        pool.play(incorrect, 1f, 1f, 1, 0, 1f)
    }
}
