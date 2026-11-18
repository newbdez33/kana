# iOS release: 1.2.1 (23)

Build 23 was uploaded on 2026-11-17 at 21:32 JST. App Store Connect reports
`VALID` and `IN_BETA_TESTING`. The existing internal testers can install it.
App Store review was submitted at 21:44 JST. The submission response and a
separate version read-back both returned `WAITING_FOR_REVIEW`, with build 23
linked. On November 18, App Store Connect confirmed `READY_FOR_SALE` and a
`COMPLETE` review submission. Build 23 was released automatically after approval.

- App: `1195345471`, bundle `com.salmonapps.app.kana`.
- Build ID: `b176a9ba-e247-4b03-9798-2d867380d240`.
- Version ID: `a89ef65c-1613-4f99-af8c-711dbec0f2f4`.
- [Review submission](https://appstoreconnect.apple.com/apps/1195345471/distribution/reviewsubmissions/details/4ab096ca-f2de-426c-9247-7b47d9dcf53d).
- Source: the working tree on `newbdez33/fix-practice-layout-whitespace`, based on
  `8234717ec07d011cd8a9db0c2fc12c05a27e4540`. The release records include the source
  patch and SHA-256 hashes of the tracked iOS source files.
- Distribution: the existing internal TestFlight group, which has access to all
  builds.
- [TestFlight](https://appstoreconnect.apple.com/apps/1195345471/testflight/ios).

## Changes

The practice screen uses the space below the iPhone Duo side status bar, including
on a cold launch. Headers stay within the safe area. The question remains
centered, the ad banner remains fully visible, and the four answer cells resize
after rotation. Layout changes preserve the current question and pause state.

English, Japanese, and Simplified Chinese test notes were saved and read back.
They cover cold launch, folding, rotation, answer sizes, banner visibility, and
returning from the Home screen.

The 20 Duo store screenshots cover five languages, with four scenes per language.
All 60 screenshots, including the 40 inherited iPhone and iPad images, were
verified as complete before submission. Checksums and order match the recorded
files. Screenshot upload receipts are in `build/store-duo-upload/`.

The [App Store release notes](../../store/release-notes/1.2.1.json) were saved and
read back in English, Japanese, Simplified Chinese, Traditional Chinese, and
Korean. Review notes describe the Duo layout fix. Existing contact information,
sign-in settings, descriptions, and support URLs were preserved.

## Validation

- All 18 production geometry tests passed on macOS.
- iPhone Duo, iOS 27.1: 38 selected unit tests and three UI tests passed.
- iPhone 18 Pro, iOS 27.0: 37 selected unit tests passed; the iOS 27.1
  reserved-region test was skipped.
- Native visual review covered cold launch, portrait, open flat, book, tabletop,
  and live folding. See the [layout validation notes](../../design/iphone-duo/README.md).
- The signed Release archive passed strict signature verification. The bundle
  contains production ad IDs, all 18 feedback WAV files, and no StoreKit fixture.
  The app dSYM UUID matches its executable.
- Apple accepted the upload. Missing dSYMs for six bundled vendor SDKs produced
  warnings, as in the previous release.

The archive is stored at
`~/Library/Developer/Xcode/Archives/2026-11-17/Kana 1.2.1 (23) - Duo Layout.xcarchive`.
Source records, archive checks, regression logs, upload logs, API status, beta
test notes, and review submission receipts are stored outside the worktree at
`~/Library/Developer/Kana/releases/2026-11-17-1.2.1-23/`. This directory also holds
`kana-duo-app-store-2026-11-17.zip`, containing all 20 Duo screenshots and their
HTML preview, plus the screenshot upload receipts in `store-duo-upload/`.
