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
