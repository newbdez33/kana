//
//  AdsManager.swift
//  kana
//
//  Gathers ad consent (UMP), asks for tracking permission and starts the
//  Google Mobile Ads SDK exactly once. Banners may only be requested after
//  `isReady` is true.
//

import UIKit
import AppTrackingTransparency
import GoogleMobileAds
import UserMessagingPlatform

extension Notification.Name {
    static let adsReadyDidChange = Notification.Name("kana.adsReadyDidChange")
}

@MainActor
final class AdsManager {

    static let shared = AdsManager()

    private(set) var isReady = false
    private var isStarting = false
    private var hasGatheredConsent = false

    private init() {}

    /// True when the UMP SDK allows ad requests for this user.
    var canRequestAds: Bool {
        return ConsentInformation.shared.canRequestAds
    }

    /// True when Google requires the app to offer a privacy options entry point.
    var isPrivacyOptionsRequired: Bool {
        return ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    /// Call once from the first visible view controller on every launch.
    func gatherConsent(from viewController: UIViewController) {
        guard !Store.shared.adsRemoved, !hasGatheredConsent else { return }
        hasGatheredConsent = true

        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false

        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] _ in
            ConsentForm.loadAndPresentIfRequired(from: viewController) { [weak self] _ in
                self?.requestTrackingAuthorizationIfNeeded {
                    self?.startMobileAdsIfAllowed()
                }
            }
        }

        // Consent gathered on a previous launch is still valid: do not wait
        // for the network round trip before starting the SDK.
        startMobileAdsIfAllowed()
    }

    func presentPrivacyOptions(from viewController: UIViewController) {
        ConsentForm.presentPrivacyOptionsForm(from: viewController) { _ in }
    }

    private func startMobileAdsIfAllowed() {
        guard canRequestAds, !isReady, !isStarting else { return }
        isStarting = true
        MobileAds.shared.start { [weak self] _ in
            DispatchQueue.main.async {
                self?.isStarting = false
                self?.isReady = true
                NotificationCenter.default.post(name: .adsReadyDidChange, object: nil)
            }
        }
    }

    private func requestTrackingAuthorizationIfNeeded(_ completion: @escaping @MainActor () -> Void) {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined,
              UIApplication.shared.applicationState == .active else {
            completion()
            return
        }
        ATTrackingManager.requestTrackingAuthorization { _ in
            Task { @MainActor in
                completion()
            }
        }
    }
}
