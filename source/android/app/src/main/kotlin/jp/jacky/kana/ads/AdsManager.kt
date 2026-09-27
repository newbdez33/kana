package jp.jacky.kana.ads

import android.app.Activity
import kotlinx.coroutines.flow.StateFlow

interface AdsManager {
    /** True once the Mobile Ads SDK is initialized and consent allows ad requests. */
    val isReady: StateFlow<Boolean>
    /** True when Google requires a privacy options entry point. */
    val privacyOptionsRequired: StateFlow<Boolean>
    fun gatherConsent(activity: Activity)
    fun showPrivacyOptions(activity: Activity)
}
