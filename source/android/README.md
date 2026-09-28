# Kana for Android

Kotlin + Jetpack Compose port of the iOS app. Design spec: `docs/specs/2026-09-27-android-app-design.md`.

Version **1.0.0 (2)** is available on Google Play internal testing as of
2026-09-28 at 20:00 JST. [Join the test](https://play.google.com/apps/internaltest/4701215213082302872)
with an account in `Kana internal testers`, then install from Play. The first
release uses the temporary name `jp.jacky.kana (unreviewed)`.
See the [release record](../../docs/releases/2026-09-28-android-internal.md)
for artifacts and service setup. The
[S22 Ultra test record](../../docs/releases/2026-09-28-android-s22.md) covers the
9 passing instrumented tests, release interactions, and real Play test purchases.
Version 2 was installed and updated through Play on the S22; its Play signature,
purchase retention, privacy link, and startup passed. Live EEA consent and test
banner delivery passed on the emulator. The S22 consent endpoint remains blocked
by its existing network path. See the
[production preparation record](../../docs/releases/2026-09-28-android-review.md)
for the 10-test regression result and the declarations still needed for review.

## Environment

- Android SDK at `~/Library/Android/sdk` (`local.properties` sets `sdk.dir`; the file is not committed).
- JDK 21 from Homebrew. Gradle 9.6.0 is downloaded by the wrapper on first run.

```sh
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
```

## Build and test

```sh
./gradlew :app:testDebugUnitTest
./gradlew :app:lintDebug
./gradlew :app:assembleDebug
./gradlew :app:connectedDebugAndroidTest   # needs a dedicated emulator or test device
```

## Ads and billing IDs

Debug builds use Google's test AdMob IDs. Release builds read `kana.admob.appId` and
`kana.admob.bannerId` from `gradle.properties` and reject missing or test IDs. The coffee
product ID is `jp.jacky.kana.coffee`. Release signing reads `key.properties`
(`keyAlias`, `keyPassword`, `storeFile`, `storePassword`), which is not committed.

## Release checks

Build the signed bundle and APK, then check an APK generated from the bundle on a
dedicated emulator. The startup check installs Kana, stops its process, clears the
emulator crash log, and checks both cold start and process restart. It does not
clear app data. Use the JDK and Android SDK environment above.

```sh
./gradlew :app:testDebugUnitTest :app:lintDebug :app:lintRelease :app:bundleRelease :app:assembleRelease
cd ../..
python3 scripts/check-android-release.py PATH_TO_BUNDLE_APK \
  --serial emulator-5560 --output build/android-release/startup
```

The release ProGuard rules retain the Room database constructor used by
WorkManager, which AdMob brings in. Without this rule, the debug tests pass but
the release app crashes before its first screen. Keep the release startup check
when upgrading these dependencies.

The upload key stays outside the repository at
`~/.local/share/kana/android-signing/`. Keep a separate secure backup before using
the key for production. Release status and remaining acceptance tasks are in
[`TODO.md`](../../TODO.md#6-android-版实现与上架).

## Emulator

```sh
avdmanager create avd -n kana_api_36 -k "system-images;android-36;google_apis;arm64-v8a" -d pixel_7
$ANDROID_HOME/emulator/emulator -avd kana_api_36 -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect &
adb wait-for-device
ANDROID_SERIAL=emulator-5554 ./gradlew :app:connectedDebugAndroidTest   # pin the serial when several emulators run
```

Instrumented tests run against `TestKanaApplication`, which replaces the Play, AdMob, sound,
and share services with fakes and seeds the question order. The tests uninstall the app when
they finish; run `adb install -r app/build/outputs/apk/debug/app-debug.apk` to try the debug
build by hand afterwards.

## Icons and strings

`scripts/make-android-icons.py` renders the adaptive launcher icon from the iOS 1024 px icon.
`scripts/ios-strings-to-android.py` regenerates every `strings.xml` from the iOS
`Localizable.strings` files; edit the iOS files (or the script's overrides) and rerun it.

For reproducible phone and tablet store screenshots, see
[`store/android/README.md`](../../store/android/README.md). Captures use the real
Compose UI with deterministic data and fake services on a dedicated emulator.

## Consent form testing

Build with `-Pkana.ads.debugGeography=eea` to force EEA geography on the emulator.
To test this app's published consent message, the debug manifest must also use
the real AdMob application ID. Keep Google's test banner ID and use a temporary
build configuration; do not change the default debug or release settings.
