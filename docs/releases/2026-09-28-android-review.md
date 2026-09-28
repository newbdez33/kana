# Android production review: 1.0.0 (2)

Submitted on **2026-09-29 at 00:10 JST**. Google Play submission **1** shows
**In review** for Production, Store Listing, App Content, and Store settings.
The 15 submitted changes include the version 2 bundle, five store languages,
IARC ratings, the **13+** target audience, and the final Data safety declaration.
Quick checks were still running when the submission was recorded. The same
candidate remains available to internal testers.

[Google Play submission](https://play.google.com/console/u/0/developers/4896965748454075126/app/4975495341700861726/publishing/submission-activity/1/details)

## Candidate and release state

- Package: `jp.jacky.kana`; version `1.0.0`, version code `2`.
- Internal release: `1.0.0 (2) - Review candidate`, published on 2026-09-28 at **20:00 JST**;
  status **Available to internal testers**, full rollout.
- Production release: `1.0.0 (2) - First Android release`, submitted with the
  existing version 2 bundle and release notes in five languages.
- Distribution: 176 listed countries/regions plus Rest of World, pending review.
- Production bundle validation has no errors. The one warning concerns missing
  debug symbols for third-party native code. The R8 mapping is attached.
- Managed publishing is off. After review approval, the saved full rollout is
  configured to publish automatically.

[Internal test invitation](https://play.google.com/apps/internaltest/4701215213082302872)
requires an account in `Kana internal testers`.

Version 2 adds a permanent Privacy policy menu item. It stays visible after the
coffee purchase removes ads and opens the Japanese, Chinese, or English policy
based on the app locale. The existing conditional ad privacy options remain.

## Artifact identity

The local archive is `build/android-production-20260928/` and is not committed.
It contains the bundle, bundletool APK set, universal APK, mapping, build logs,
signature checks, test results, and screenshots. Credentials are not included.

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `kana-1.0.0-2.aab` | 11,140,030 | `9aa084343352072b897a5189ddbc4358b8a7a55d4ab2d6063afc2b1902828c56` |
| `kana-1.0.0-2.apk` | 7,140,266 | `688fc088e41fecd0f956b9a23e425cb27e9fb7578cf988acdc5fb63c38a4099e` |

The bundle targets API 36 and supports API 26+. The universal APK uses the upload
signature. The S22 installation from Play uses the Play signing certificate:

```text
C3:F8:71:F3:A5:3C:EC:2E:D5:45:19:58:26:B0:84:F7:48:36:6A:3D:B1:55:7B:BB:05:C1:92:CD:57:D7:F2:3B
```

## Validation

- All **51 unit tests**, debug lint, and release lint passed.
- All **10 instrumented UI tests** passed on the dedicated API 36 emulator
  in 11.471 seconds. The new privacy-link test first failed without the menu item,
  then passed with the implementation. UI tests use service fakes.
- The exact bundle-generated release APK passed phone and tablet-size cold start
  and process restart checks, with 10 seconds observed per launch. APK signature
  verification and 16 KB ZIP alignment passed.
- On the S22 Ultra, the upload-signed version 1 to version 2 upgrade retained the
  test purchase. The privacy policy opened correctly.
- The earlier Play `Item not found` issue was resolved later the same day. After
  removal of this session's sideloaded app, Play installed version 1 and then
  updated it to version 2. Package metadata reports `com.android.vending` as the
  installer and version code 2. The pulled APK has the Play certificate above.
- Play version 2 cold start took **222 ms**. The test purchase remained restored,
  the permanent privacy link opened the deployed page, and no Kana crash was
  found in the recorded crash buffer.
- Live UMP testing used a separate debug build with the real AdMob app ID,
  Google's test banner ID, and EEA debug geography. The Kana consent form loaded.
  Refusal returned to practice; ad privacy options reopened the form; acceptance
  returned to practice. The release configuration was not changed.
- The exact release APK displayed a **Test Ad** on the emulator after timeout.
  No advertisement was clicked. The default debug build configuration was restored.

The original [S22 test record](2026-09-28-android-s22.md) covers the nine physical
device instrumented tests, release interaction checks, and real no-charge Play
test-card cancellation, decline, pending approval, purchase, and restoration.

## Store and declarations

The five store languages are saved: en-US, ja-JP, zh-CN, zh-TW, and ko-KR. Each
has a name, short and full descriptions, icon, localized feature graphic, and
four screenshots in each phone, 7-inch tablet, and 10-inch tablet slot. The same
tablet captures are used for both tablet slots. They are emulator captures with
fixture data, not physical tablet evidence. The capture scripts and copy are in
[`store/android/`](../../store/android/README.md).

The category is Education. Support email is
`newbdez33+kana.feedback@gmail.com`; website is `https://kana.jacky.jp`.
The privacy policy, ads, app access, government, financial, health, and
advertising ID declarations are saved.

The submitted Data safety declaration records the following Android SDK behavior:

| Type | Handling | Purpose |
| --- | --- | --- |
| Approximate location, app interactions, diagnostics, device or other IDs | Collected and shared; not ephemeral; required | Ads/marketing, analytics, fraud/security/compliance |
| Purchase history | Collected; optional; not ephemeral | App functionality |

The declaration states encryption in transit, no account creation or external login,
and no app-controlled data deletion request mechanism. Practice statistics stay
on the device. The disclosure was checked against the
[AdMob Android disclosure guide](https://developers.google.com/admob/android/privacy/play-data-disclosure)
and the [Play Data safety definitions](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en).
The five data types and the store preview were checked before the final save.

## Content rating update: 2026-09-29

The user authorized acceptance of the IARC terms. The saved questionnaire treats
Kana as an educational app with a fixed digital purchase. It declares no mature
content in the app package, native user-to-user content sharing, remote content
catalog, age-restricted sales, precise location sharing, randomized purchases,
cash or crypto rewards, or browser/search functionality. The system share sheet
uses other apps; it is not a native user-content service.

The resulting ratings are ESRB Everyone, PEGI 3, ClassInd All ages, USK All ages,
and IARC/Google Play 3+ for the remaining displayed regions. All include In-App
Purchases. USK also lists Contents for Different Age Groups. The ratings are
included in the production submission.

Content ratings describe content suitability. Target audience declarations
separately describe the users the app is designed for. The user chose a teen and
adult audience on 2026-09-29. The saved age groups are **13–15, 16–17, and 18+**,
consistent with the privacy policy. See the
[target audience guidance](https://support.google.com/googleplay/android-developer/answer/9867159?hl=en).
The age declaration does not guarantee higher ad revenue. Google's
[teen ad protections](https://support.google.com/admob/answer/12171027?hl=en)
still restrict personalization for eligible users under 18.

## Remaining work

1. Monitor the submitted release and address any Google Play review findings.
2. Keep a separate secure backup of the upload key in the user's chosen location.
3. Recheck live consent and banners on physical hardware where the UMP endpoint
   is reachable. The S22's existing DNS path resolves it to loopback; settings
   were not changed. Audible sound and full physical tablet interaction remain
   separate checks.
4. After publication, verify the listing, purchase availability, AdMob store
   association, app-ads.txt, and production health.
