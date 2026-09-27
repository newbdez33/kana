# Kana for Android

Kotlin + Jetpack Compose port of the iOS app. Design spec: `docs/specs/2026-09-27-android-app-design.md`.

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
./gradlew :app:connectedDebugAndroidTest   # needs a running emulator, see below
```

## Ads and billing IDs

Debug builds use Google's test AdMob IDs. Release builds read `kana.admob.appId` and
`kana.admob.bannerId` from `gradle.properties` and fail until both are set. The coffee
product ID is `jp.jacky.kana.coffee`. Release signing reads `key.properties`
(`keyAlias`, `keyPassword`, `storeFile`, `storePassword`), which is not committed.

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

## Consent form testing

Set `kana.ads.debugGeography=eea` in `gradle.properties` and rebuild the debug app to force the
EEA consent form on the emulator.
