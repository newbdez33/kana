package jp.jacky.kana.share

import android.app.Activity
import android.content.Context
import android.content.Intent
import androidx.core.net.toUri
import jp.jacky.kana.R

class AndroidShareActions(private val context: Context) : ShareActions {

    override fun share(activity: Activity) {
        val text = context.getString(R.string.intro_text) + "\n" + PLAY_URL
        val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
        activity.startActivity(Intent.createChooser(send, context.getString(R.string.share)))
    }

    override fun canSendFeedback(): Boolean = feedbackIntent().resolveActivity(context.packageManager) != null

    override fun sendFeedback(activity: Activity) {
        runCatching { activity.startActivity(feedbackIntent()) }
    }

    private fun feedbackIntent(): Intent = Intent(Intent.ACTION_SENDTO, "mailto:$FEEDBACK_EMAIL".toUri())
        .putExtra(Intent.EXTRA_SUBJECT, context.getString(R.string.feedback))

    companion object {
        const val PLAY_URL = "https://play.google.com/store/apps/details?id=jp.jacky.kana"
        const val FEEDBACK_EMAIL = "newbdez33+kana.feedback@gmail.com"
    }
}
