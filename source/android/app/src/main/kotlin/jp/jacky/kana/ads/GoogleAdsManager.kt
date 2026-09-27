package jp.jacky.kana.ads

import android.app.Activity
import android.app.Application
import com.google.android.gms.ads.MobileAds
import com.google.android.ump.ConsentDebugSettings
import com.google.android.ump.ConsentInformation
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.UserMessagingPlatform
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Gathers consent through the UMP SDK and starts the Mobile Ads SDK exactly once.
 * Mirrors the iOS AdsManager, without the App Tracking Transparency step.
 */
class GoogleAdsManager(
    private val app: Application,
    private val scope: CoroutineScope,
    private val debugGeographyEea: Boolean,
) : AdsManager {

    private val _isReady = MutableStateFlow(false)
    override val isReady: StateFlow<Boolean> = _isReady.asStateFlow()

    private val _privacyOptionsRequired = MutableStateFlow(false)
    override val privacyOptionsRequired: StateFlow<Boolean> = _privacyOptionsRequired.asStateFlow()

    private val consent: ConsentInformation by lazy { UserMessagingPlatform.getConsentInformation(app) }
    private var gathered = false
    private var starting = false

    override fun gatherConsent(activity: Activity) {
        if (gathered) return
        gathered = true

        val params = ConsentRequestParameters.Builder()
            .setTagForUnderAgeOfConsent(false)
            .apply {
                if (debugGeographyEea) {
                    setConsentDebugSettings(
                        ConsentDebugSettings.Builder(activity)
                            .setDebugGeography(ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_EEA)
                            .build()
                    )
                }
            }
            .build()

        consent.requestConsentInfoUpdate(
            activity,
            params,
            {
                UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity) { _ ->
                    updatePrivacyOptions()
                    startIfAllowed()
                }
            },
            { _ ->
                updatePrivacyOptions()
                startIfAllowed()
            },
        )

        // Consent gathered on a previous launch is still valid: do not wait for the network.
        updatePrivacyOptions()
        startIfAllowed()
    }

    override fun showPrivacyOptions(activity: Activity) {
        UserMessagingPlatform.showPrivacyOptionsForm(activity) { _ -> updatePrivacyOptions() }
    }

    private fun updatePrivacyOptions() {
        _privacyOptionsRequired.value =
            consent.privacyOptionsRequirementStatus == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED
    }

    private fun startIfAllowed() {
        if (!consent.canRequestAds() || _isReady.value || starting) return
        starting = true
        scope.launch(Dispatchers.IO) {
            MobileAds.initialize(app) {
                scope.launch(Dispatchers.Main) {
                    starting = false
                    _isReady.value = true
                }
            }
        }
    }
}
