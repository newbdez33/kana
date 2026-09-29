package jp.jacky.kana.share

import android.app.Activity

interface ShareActions {
    fun share(activity: Activity)
    fun canSendFeedback(): Boolean
    fun sendFeedback(activity: Activity)
    fun openPrivacyPolicy(activity: Activity)
}
