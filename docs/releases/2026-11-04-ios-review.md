# iOS release: 1.2.0 (22)

Build 22 was uploaded on 2026-11-04 at 10:55 JST and processed successfully.
It is available to the existing TestFlight testers (`IN_BETA_TESTING`).
App Store Connect confirmed **Waiting for Review** at 11:05 JST.
The earlier build 20 review was canceled before review. Build 21 was superseded
by the fix for unresponsive answers after a Home-screen return.

- App: `1195345471`, bundle `com.salmonapps.app.kana`.
- Version ID: `3feb665d-5af0-4b29-b50d-446cdad5075d`.
- Build ID: `cebb394f-9b21-48c5-b0dd-deb376c44734`.
- Review submission: `7251fe88-8d8e-4301-92f5-af3123f10698`.
- Binary source: `d0f5ef24ab7bee89d0e921dec0631b079c8a9bfa`.
- Release mode: automatic after approval, as in the previous release.
- [App Store Connect](https://appstoreconnect.apple.com/apps/1195345471/distribution/ios/version/inflight).
- [Implementation PR](https://github.com/newbdez33/kana/pull/12), based on
  [the adaptive layout PR](https://github.com/newbdez33/kana/pull/9).

## Changes

The version includes adaptive layouts and [native practice feedback](../practice-feedback.md).
Visible kana and romaji glyphs are centered by their ink bounds. Background
suspension can leave an audio interruption without an end notification. Build 22
releases the audio session in the background, ignores delayed suspension notices,
and lets a foreground return or visible answer tap clear a stale audio pause.
Menu, consent, and background pauses keep their own guards.

TestFlight notes in English, Japanese, and Simplified Chinese describe the
Home-return regression check. App Store release notes were saved and read back in English, Japanese, Simplified Chinese,
Traditional Chinese, and Korean. The 40 inherited screenshots remain complete.
Reviewer contact information, privacy settings, production AdMob IDs, and the
existing permanent coffee purchase were preserved.

## Validation

- The new audio regressions failed before the fix and passed afterward.
- The final iOS unit/layout run passed 51 tests; one optional screenshot fixture
  was skipped because its capture environment was absent.
- The Home-return UI test passed two cycles with eight seconds in the background
  and accepted answers after each return.
- Ad triggers, purchase/restore, stored statistics, pause overlap, the five-second
  deadline, and glyph alignment are covered by passing tests.
- The release archive contains all 18 feedback WAV files and production ad IDs.
- The app dSYM is present. Apple reports missing dSYMs for six bundled vendor SDKs;
  these warnings did not block upload.

The submission response and a separate version read-back both returned
`WAITING_FOR_REVIEW`, with build 22 linked.

Local API and test evidence is in `build/app-store-1.2.0/`; archive and upload
logs are in `build/native-feedback/`. These directories are not committed and
may contain private review contact information. Native PRs remain open.
