# Kana Android 版实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `source/android/` 建出与 iOS 1.1.0 功能对齐、可上架 Google Play 的 Kana Android 版：练习、统计、五十音图、咖啡内购、带同意流程的 AdMob 横幅、8 种语言。

**Architecture:** 单模块 Kotlin + Jetpack Compose。纯 Kotlin 类承载出题、统计规则；`PracticeViewModel` / `CoffeeViewModel` 持有状态；Android 依赖（Billing、UMP、AdMob、SoundPool、Intent）都藏在接口后面，通过 `KanaApplication.container`（`AppContainer`）注入，测试用假实现整体替换。

**Tech Stack:** AGP 9.4.1（内置 Kotlin）、Gradle 9.6.0、Kotlin 2.4.20、Compose BOM 2026.09.00（Material 3 1.4.0）、play-services-ads 25.5.0、user-messaging-platform 4.0.0、billing-ktx 9.1.0、kotlinx-coroutines 1.11.0、JUnit 4、Compose UI Test、Pillow（图标脚本）。

**Spec:** `docs/specs/2026-09-27-android-app-design.md`

## Global Constraints

- applicationId / namespace `jp.jacky.kana`；Play 商品 ID `jp.jacky.kana.coffee`；分支 `newbdez33/android-app`，PR #6。
- minSdk 26；targetSdk 36；compileSdk 37.0（本机已装 `platforms;android-37.0`，写法 `compileSdk { version = release(37) { minorApiLevel = 0 } }`）。
- debug 固定用 Google 测试 ID：App ID `ca-app-pub-3940256099942544~3347511713`，横幅 `ca-app-pub-3940256099942544/9214589741`；release 从 `gradle.properties` 的 `kana.admob.appId` / `kana.admob.bannerId` 读取，为空或含 `3940256099942544` 时 release 构建失败。
- 固定浅色主题；假名与罗马音用 `res/font/hosohuwa.ttf`；iOS pt 按 1:1 换算 dp；假名字号用 dp 换算（`155.dp.toSp()`），界面文字用 sp。
- 8 种语言：`values`(en)、`values-ja`、`values-b+zh+Hans`、`values-b+zh+Hant`、`values-ko`、`values-de`、`values-fr`、`values-es`；39 个键 + `app_name`；`restore_none_message` 改为 Google 账号措辞。
- 不接 Firebase；不用 Hilt / Navigation / kotlinx.serialization（统计 JSON 用 Android 自带 `org.json`）。
- 提交信息用英文祈使句，不加 Co-Authored-By。所有 Gradle 命令在 `source/android/` 下执行，且先设置环境：

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
cd /Volumes/shit/orca/workspaces/kana/oarfish/source/android
```

## Review Focus

1. **购买回调返回 OK 但不含咖啡商品**（例如用户在 Play 面板买了别的东西）：`purchase()` 应返回 `CANCELLED`，不能抛错。→ Task 7 测试 `purchase returns CANCELLED when the update has no coffee record`。
2. **同意流程未完成或 `canRequestAds` 为 false 时答错**：横幅槽位不能出现，答题照常。→ Task 8 测试 `banner stays hidden until ads are ready`。
3. **统计文件不可写**（目录被占、磁盘满）：`recordAnswer` 不抛异常，内存中的数字照常更新。→ Task 5 测试 `record keeps working when the file cannot be written`。
4. **恰好在 5.000 秒边界点击**：计时已到，点击按「展示正确答案后」规则处理，不重复记统计。→ Task 8 测试 `timeout fires at exactly the limit`。
5. **答错后连续快速点击同一错误项**：只记一次统计，连对保持 0。→ Task 8 测试 `double tap on a wrong answer records one answer`。

---

### Task 1: Gradle 工程脚手架

**Files:**
- Create: `source/android/settings.gradle.kts`、`build.gradle.kts`、`gradle.properties`、`gradle/libs.versions.toml`、`gradle/wrapper/gradle-wrapper.properties`、`gradle/wrapper/gradle-wrapper.jar`（复制）、`gradlew`、`gradlew.bat`（复制）、`local.properties`（不提交）、`README.md`
- Create: `source/android/app/build.gradle.kts`、`app/proguard-rules.pro`、`app/src/main/AndroidManifest.xml`、`app/src/main/res/values/colors.xml`、`app/src/main/res/values/themes.xml`、`app/src/main/res/values/strings.xml`（临时，只含 `app_name`，Task 2 覆盖）
- Create: `app/src/main/kotlin/jp/jacky/kana/KanaApplication.kt`、`MainActivity.kt`
- Modify: `.gitignore`（仓库根）

**Interfaces:**
- Produces: `BuildConfig.COFFEE_PRODUCT_ID: String`、`BuildConfig.ADMOB_BANNER_ID: String`、`BuildConfig.ADS_DEBUG_GEOGRAPHY_EEA: Boolean`；manifest placeholder `admobAppId`；`KanaApplication`（Task 6 加 `container`）。

- [ ] **Step 1: 复制 wrapper 并写 Gradle 文件**

```bash
mkdir -p source/android/gradle/wrapper source/android/app/src/main/kotlin/jp/jacky/kana source/android/app/src/main/res/values
cp /Volumes/shit/projects/menkyo_practice/android/gradlew source/android/gradlew
cp /Volumes/shit/projects/menkyo_practice/android/gradlew.bat source/android/gradlew.bat
cp /Volumes/shit/projects/menkyo_practice/android/gradle/wrapper/gradle-wrapper.jar source/android/gradle/wrapper/gradle-wrapper.jar
chmod +x source/android/gradlew
printf 'sdk.dir=%s/Library/Android/sdk\n' "$HOME" > source/android/local.properties
```

`source/android/gradle/wrapper/gradle-wrapper.properties`：

```properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-9.6.0-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```

`source/android/settings.gradle.kts`：

```kotlin
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "kana"
include(":app")
```

`source/android/build.gradle.kts`：

```kotlin
buildscript {
    dependencies {
        // AGP 9 bundles the Kotlin Gradle plugin; pin it to the Compose compiler plugin version.
        classpath(libs.kotlin.gradle.plugin)
    }
}

plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.compose.compiler) apply false
}
```

`source/android/gradle.properties`：

```properties
org.gradle.jvmargs=-Xmx4g -Dfile.encoding=UTF-8
org.gradle.caching=true
android.useAndroidX=true
kotlin.code.style=official

# Production AdMob IDs. Fill in after creating the Android app in AdMob.
# Debug builds always use Google's test IDs.
kana.admob.appId=
kana.admob.bannerId=
# Set to "eea" to force the EEA consent form in debug builds.
kana.ads.debugGeography=
```

`source/android/gradle/libs.versions.toml`：

```toml
[versions]
agp = "9.4.1"
kotlin = "2.4.20"
composeBom = "2026.09.00"
activityCompose = "1.13.0"
lifecycle = "2.11.0"
coreKtx = "1.19.1"
coroutines = "1.11.0"
playServicesAds = "25.5.0"
ump = "4.0.0"
billing = "9.1.0"
junit = "4.13.2"
orgJson = "20260814"
androidxTestCore = "1.7.0"
androidxTestRunner = "1.7.0"
androidxTestRules = "1.7.0"
androidxTestExtJunit = "1.3.0"
espresso = "3.7.0"

[libraries]
kotlin-gradle-plugin = { module = "org.jetbrains.kotlin:kotlin-gradle-plugin", version.ref = "kotlin" }
androidx-core-ktx = { module = "androidx.core:core-ktx", version.ref = "coreKtx" }
androidx-activity-compose = { module = "androidx.activity:activity-compose", version.ref = "activityCompose" }
androidx-lifecycle-viewmodel-compose = { module = "androidx.lifecycle:lifecycle-viewmodel-compose", version.ref = "lifecycle" }
androidx-lifecycle-runtime-compose = { module = "androidx.lifecycle:lifecycle-runtime-compose", version.ref = "lifecycle" }
compose-bom = { module = "androidx.compose:compose-bom", version.ref = "composeBom" }
compose-foundation = { module = "androidx.compose.foundation:foundation" }
compose-material3 = { module = "androidx.compose.material3:material3" }
compose-material-icons-extended = { module = "androidx.compose.material:material-icons-extended" }
compose-ui-tooling-preview = { module = "androidx.compose.ui:ui-tooling-preview" }
compose-ui-tooling = { module = "androidx.compose.ui:ui-tooling" }
compose-ui-test-junit4 = { module = "androidx.compose.ui:ui-test-junit4" }
compose-ui-test-manifest = { module = "androidx.compose.ui:ui-test-manifest" }
kotlinx-coroutines-android = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-android", version.ref = "coroutines" }
kotlinx-coroutines-test = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-test", version.ref = "coroutines" }
play-services-ads = { module = "com.google.android.gms:play-services-ads", version.ref = "playServicesAds" }
user-messaging-platform = { module = "com.google.android.ump:user-messaging-platform", version.ref = "ump" }
billing-ktx = { module = "com.android.billingclient:billing-ktx", version.ref = "billing" }
junit = { module = "junit:junit", version.ref = "junit" }
org-json = { module = "org.json:json", version.ref = "orgJson" }
androidx-test-core = { module = "androidx.test:core-ktx", version.ref = "androidxTestCore" }
androidx-test-runner = { module = "androidx.test:runner", version.ref = "androidxTestRunner" }
androidx-test-rules = { module = "androidx.test:rules", version.ref = "androidxTestRules" }
androidx-test-ext-junit = { module = "androidx.test.ext:junit-ktx", version.ref = "androidxTestExtJunit" }
androidx-test-espresso-core = { module = "androidx.test.espresso:espresso-core", version.ref = "espresso" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
compose-compiler = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
```

- [ ] **Step 2: 写 app 模块构建文件**

`source/android/app/build.gradle.kts`：

```kotlin
import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.compose.compiler)
}

val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.isFile) file.inputStream().use { load(it) }
}
val admobAppId = providers.gradleProperty("kana.admob.appId").getOrElse("")
val admobBannerId = providers.gradleProperty("kana.admob.bannerId").getOrElse("")
val debugGeographyEea = providers.gradleProperty("kana.ads.debugGeography").getOrElse("") == "eea"
val testAdmobAppId = "ca-app-pub-3940256099942544~3347511713"
val testAdmobBannerId = "ca-app-pub-3940256099942544/9214589741"

android {
    namespace = "jp.jacky.kana"
    compileSdk {
        version = release(37) {
            minorApiLevel = 0
        }
    }

    defaultConfig {
        applicationId = "jp.jacky.kana"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
        testInstrumentationRunner = "jp.jacky.kana.KanaTestRunner"
        buildConfigField("String", "COFFEE_PRODUCT_ID", "\"jp.jacky.kana.coffee\"")
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { rootProject.file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        debug {
            manifestPlaceholders["admobAppId"] = testAdmobAppId
            buildConfigField("String", "ADMOB_BANNER_ID", "\"$testAdmobBannerId\"")
            buildConfigField("boolean", "ADS_DEBUG_GEOGRAPHY_EEA", "$debugGeographyEea")
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
            manifestPlaceholders["admobAppId"] = admobAppId
            buildConfigField("String", "ADMOB_BANNER_ID", "\"$admobBannerId\"")
            buildConfigField("boolean", "ADS_DEBUG_GEOGRAPHY_EEA", "false")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
    }

    sourceSets {
        getByName("test") { kotlin.directories += "src/sharedTest/kotlin" }
        getByName("androidTest") { kotlin.directories += "src/sharedTest/kotlin" }
    }
}

dependencies {
    val composeBom = platform(libs.compose.bom)
    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.compose.foundation)
    implementation(libs.compose.material3)
    implementation(libs.compose.material.icons.extended)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.play.services.ads)
    implementation(libs.user.messaging.platform)
    implementation(libs.billing.ktx)

    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.org.json)

    androidTestImplementation(libs.androidx.test.core)
    androidTestImplementation(libs.androidx.test.runner)
    androidTestImplementation(libs.androidx.test.rules)
    androidTestImplementation(libs.androidx.test.ext.junit)
    androidTestImplementation(libs.androidx.test.espresso.core)
    androidTestImplementation(libs.kotlinx.coroutines.test)
    androidTestImplementation(libs.compose.ui.test.junit4)
    debugImplementation(libs.compose.ui.test.manifest)
}

// Release builds must carry the production AdMob IDs and a signing key.
tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    doFirst {
        check(
            admobAppId.isNotBlank() && admobBannerId.isNotBlank() &&
                "3940256099942544" !in admobAppId && "3940256099942544" !in admobBannerId
        ) { "Set kana.admob.appId and kana.admob.bannerId in gradle.properties to the production AdMob IDs." }
        check(listOf("keyAlias", "keyPassword", "storeFile", "storePassword").all {
            !keystoreProperties.getProperty(it).isNullOrBlank()
        }) { "Set all release signing values in source/android/key.properties." }
    }
}
```

`source/android/app/proguard-rules.pro`：

```
# Google Mobile Ads, UMP and Play Billing ship their own consumer rules.
# org.json is part of the Android platform.
```

- [ ] **Step 3: Manifest、主题、最小 Application / Activity**

`app/src/main/AndroidManifest.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <queries>
        <intent>
            <action android:name="android.intent.action.SENDTO" />
            <data android:scheme="mailto" />
        </intent>
    </queries>

    <application
        android:name=".KanaApplication"
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.Kana">

        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="${admobAppId}" />

        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

Task 14 才生成图标；本任务先放一个临时的自适应图标让清单能编译。`app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` 与 `ic_launcher_round.xml`（内容相同）：

```xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@color/ic_launcher_background" />
</adaptive-icon>
```

`app/src/main/res/values/colors.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="key_gray">#F7F7F7</color>
    <color name="ic_launcher_background">#FFFFFF</color>
</resources>
```

`app/src/main/res/values/themes.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.Kana" parent="android:Theme.Material.Light.NoActionBar">
        <item name="android:windowBackground">@color/key_gray</item>
        <item name="android:windowLightStatusBar">true</item>
        <item name="android:windowLightNavigationBar">true</item>
    </style>
</resources>
```

`app/src/main/res/values/strings.xml`（临时）：

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name" translatable="false">Kana</string>
</resources>
```

`KanaApplication.kt`：

```kotlin
package jp.jacky.kana

import android.app.Application

open class KanaApplication : Application()
```

`MainActivity.kt`：

```kotlin
package jp.jacky.kana

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.Text

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { Text("Kana") }
    }
}
```

- [ ] **Step 4: 根 `.gitignore` 追加 Android 条目**

在仓库根 `.gitignore` 末尾追加：

```
# Android
source/android/.gradle/
source/android/.kotlin/
source/android/.idea/
source/android/local.properties
source/android/key.properties
*.iml
*.jks
*.keystore
```

- [ ] **Step 5: 首次构建（下载 Gradle 9.6.0 与依赖）**

Run:
```bash
./gradlew wrapper --gradle-version 9.6.0 --distribution-type bin && ./gradlew --version && ./gradlew :app:assembleDebug
```
Expected: `Gradle 9.6.0`；`BUILD SUCCESSFUL`，产物 `app/build/outputs/apk/debug/app-debug.apk`。若 `compileSdk { version = release(37) { minorApiLevel = 0 } }` 报错找不到平台，改为 `compileSdk = 37` 再试；两者都记录到 README。

- [ ] **Step 6: 写 README 骨架**

`source/android/README.md`：

```markdown
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
```

- [ ] **Step 7: Commit**

```bash
git add .gitignore source/android
git commit -m "Scaffold the Android app module"
```

---

### Task 2: 本地化字符串、字体、音效

**Files:**
- Create: `scripts/ios-strings-to-android.py`
- Create（脚本生成）: `app/src/main/res/values/strings.xml`、`values-ja/`、`values-b+zh+Hans/`、`values-b+zh+Hant/`、`values-ko/`、`values-de/`、`values-fr/`、`values-es/strings.xml`
- Create: `app/src/main/res/xml/locales_config.xml`、`app/src/main/res/font/hosohuwa.ttf`（复制）、`app/src/main/res/raw/correct.wav`、`raw/incorrect.wav`（复制）
- Modify: `app/src/main/AndroidManifest.xml`（加 `android:localeConfig`）

**Interfaces:**
- Produces: 字符串资源键（snake_case）：`intro_text, feedback, coffee, coffee_thanks, restore, ad_privacy, thanks_title, thanks_message, restore_none_title, restore_none_message, purchase_failed_title, ok, chart, practice, stat_answers, stat_average, stat_recent, stat_best, stat_seconds, menu, close_menu, close, more, share, support, coffee_message, coffee_benefit, coffee_supported, coffee_price, coffee_terms, coffee_loading, coffee_unavailable, coffee_pending, coffee_pending_message, coffee_purchasing, coffee_restoring, continue_practice, retry, purchase_unverified, app_name`；`R.font.hosohuwa`；`R.raw.correct`、`R.raw.incorrect`。

- [ ] **Step 1: 写转换脚本**

`scripts/ios-strings-to-android.py`：

```python
#!/usr/bin/env python3
"""Convert the iOS Localizable.strings files into Android strings.xml files.

Usage: python3 scripts/ios-strings-to-android.py
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
IOS_DIR = ROOT / "source/kana/kana"
RES_DIR = ROOT / "source/android/app/src/main/res"

LANGUAGES = {
    "en": "values",
    "ja": "values-ja",
    "zh-Hans": "values-b+zh+Hans",
    "zh-Hant": "values-b+zh+Hant",
    "ko": "values-ko",
    "de": "values-de",
    "fr": "values-fr",
    "es": "values-es",
}

# Android-specific wording; keyed by Android key, then iOS language.
OVERRIDES = {
    "restore_none_message": {
        "en": "No previous purchase was found for this Google account.",
        "ja": "この Google アカウントでの購入は見つかりませんでした。",
        "zh-Hans": "这个 Google 账号下没有找到之前的购买记录。",
        "zh-Hant": "這個 Google 帳戶下沒有找到先前的購買記錄。",
        "ko": "이 Google 계정에서 이전 구매를 찾을 수 없습니다.",
        "de": "Für dieses Google-Konto wurde kein früherer Kauf gefunden.",
        "fr": "Aucun achat précédent n'a été trouvé pour ce compte Google.",
        "es": "No se encontró ninguna compra anterior para esta cuenta de Google.",
    },
}

ENTRY = re.compile(r'^"([^"]+)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;')


def snake(key: str) -> str:
    return re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", key).lower()


def parse(path: pathlib.Path) -> list[tuple[str, str]]:
    entries = []
    for line in path.read_text(encoding="utf-8").splitlines():
        match = ENTRY.match(line.strip())
        if match:
            entries.append((match.group(1), match.group(2)))
    return entries


def to_android(value: str) -> str:
    value = value.replace("%@", "%1$s").replace("%d", "%1$d")
    value = value.replace('\\"', '"')
    value = value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    value = value.replace("'", "\\'").replace('"', '\\"')
    return value


def render(language: str, entries: list[tuple[str, str]]) -> str:
    lines = [
        '<?xml version="1.0" encoding="utf-8"?>',
        f"<!-- Generated by scripts/ios-strings-to-android.py from source/kana/kana/{language}.lproj/Localizable.strings. Do not edit by hand. -->",
        "<resources>",
    ]
    if language == "en":
        lines.append('    <string name="app_name" translatable="false">Kana</string>')
    for key, value in entries:
        name = snake(key)
        text = OVERRIDES.get(name, {}).get(language)
        text = to_android(text) if text is not None else to_android(value)
        lines.append(f'    <string name="{name}">{text}</string>')
    lines.append("</resources>")
    return "\n".join(lines) + "\n"


def main() -> None:
    for language, folder in LANGUAGES.items():
        entries = parse(IOS_DIR / f"{language}.lproj" / "Localizable.strings")
        if len(entries) != 39:
            raise SystemExit(f"{language}: expected 39 strings, found {len(entries)}")
        target = RES_DIR / folder / "strings.xml"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(render(language, entries), encoding="utf-8")
        print(f"wrote {target.relative_to(ROOT)} ({len(entries)} strings)")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: 运行脚本并检查输出**

Run:
```bash
python3 scripts/ios-strings-to-android.py && grep -c '<string ' source/android/app/src/main/res/values/strings.xml && grep -E 'stat_recent|stat_seconds|coffee_price|restore_none_message|intro_text' source/android/app/src/main/res/values/strings.xml
```
Expected: 8 行 `wrote ...`；英文文件 40 个 `<string`；`stat_recent` 含 `%1$d`，`stat_seconds` 为 `%1$ss`，`coffee_price` 含 `%1$s`，`restore_none_message` 含 `Google account`，`intro_text` 含 `\n`。

- [ ] **Step 3: locales_config、字体、音效**

`app/src/main/res/xml/locales_config.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<locale-config xmlns:android="http://schemas.android.com/apk/res/android">
    <locale android:name="en" />
    <locale android:name="ja" />
    <locale android:name="zh-Hans" />
    <locale android:name="zh-Hant" />
    <locale android:name="ko" />
    <locale android:name="de" />
    <locale android:name="fr" />
    <locale android:name="es" />
</locale-config>
```

Manifest 的 `<application>` 加一行 `android:localeConfig="@xml/locales_config"`。

```bash
mkdir -p source/android/app/src/main/res/font source/android/app/src/main/res/raw
cp source/kana/kana/resources/fonts/Hosohuwafont.ttf source/android/app/src/main/res/font/hosohuwa.ttf
cp source/kana/kana/resources/sound/correct.wav source/kana/kana/resources/sound/incorrect.wav source/android/app/src/main/res/raw/
```

- [ ] **Step 4: 构建与 lint**

Run: `./gradlew :app:assembleDebug :app:lintDebug`
Expected: `BUILD SUCCESSFUL`；lint 报告无 `MissingTranslation` / `ExtraTranslation` 错误（报告在 `app/build/reports/lint-results-debug.html`）。

- [ ] **Step 5: Commit**

```bash
git add scripts/ios-strings-to-android.py source/android/app/src/main
git commit -m "Add localized strings, kana font, and sound effects to the Android app"
```

---

### Task 3: 五十音数据

**Files:**
- Create: `app/src/main/kotlin/jp/jacky/kana/practice/Kana.kt`
- Test: `app/src/test/kotlin/jp/jacky/kana/practice/KanaTableTest.kt`

**Interfaces:**
- Produces: `enum class KanaForm { ROMAJI, HIRAGANA, KATAKANA }`；`data class Kana(romaji, hiragana, katakana)` + `fun text(form: KanaForm): String`；`object KanaTable { val rows: List<List<Kana?>>; val practicePool: List<Kana> }`。

- [ ] **Step 1: 写失败测试**

```kotlin
package jp.jacky.kana.practice

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class KanaTableTest {
    @Test
    fun `practice pool has the 46 basic kana with unique romaji`() {
        assertEquals(46, KanaTable.practicePool.size)
        assertEquals(46, KanaTable.practicePool.map { it.romaji }.toSet().size)
    }

    @Test
    fun `rows keep the chart layout`() {
        assertEquals(11, KanaTable.rows.size)
        assertEquals(5, KanaTable.rows[0].size)
        assertNull(KanaTable.rows[7][1]) // や行 second slot is empty
        assertNull(KanaTable.rows[9][2]) // わ行 middle slot is empty
        assertEquals(1, KanaTable.rows[10].size) // ん
        assertEquals(Kana("n", "ん", "ン"), KanaTable.rows[10][0])
    }

    @Test
    fun `text picks the requested form`() {
        val ne = Kana("ne", "ね", "ネ")
        assertEquals("ne", ne.text(KanaForm.ROMAJI))
        assertEquals("ね", ne.text(KanaForm.HIRAGANA))
        assertEquals("ネ", ne.text(KanaForm.KATAKANA))
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `./gradlew :app:testDebugUnitTest --tests 'jp.jacky.kana.practice.KanaTableTest'`
Expected: 编译失败，`Unresolved reference: KanaTable`。

- [ ] **Step 3: 实现**

```kotlin
package jp.jacky.kana.practice

enum class KanaForm { ROMAJI, HIRAGANA, KATAKANA }

data class Kana(val romaji: String, val hiragana: String, val katakana: String) {
    fun text(form: KanaForm): String = when (form) {
        KanaForm.ROMAJI -> romaji
        KanaForm.HIRAGANA -> hiragana
        KanaForm.KATAKANA -> katakana
    }
}

/** The 46 basic kana, laid out as the gojūon chart. Ported from the iOS AppConfig.monographs. */
object KanaTable {
    private fun k(romaji: String, hiragana: String, katakana: String) = Kana(romaji, hiragana, katakana)

    /** Chart rows; null keeps the column alignment for empty slots. */
    val rows: List<List<Kana?>> = listOf(
        listOf(k("a", "あ", "ア"), k("i", "い", "イ"), k("u", "う", "ウ"), k("e", "え", "エ"), k("o", "お", "オ")),
        listOf(k("ka", "か", "カ"), k("ki", "き", "キ"), k("ku", "く", "ク"), k("ke", "け", "ケ"), k("ko", "こ", "コ")),
        listOf(k("sa", "さ", "サ"), k("shi", "し", "シ"), k("su", "す", "ス"), k("se", "せ", "セ"), k("so", "そ", "ソ")),
        listOf(k("ta", "た", "タ"), k("chi", "ち", "チ"), k("tsu", "つ", "ツ"), k("te", "て", "テ"), k("to", "と", "ト")),
        listOf(k("na", "な", "ナ"), k("ni", "に", "ニ"), k("nu", "ぬ", "ヌ"), k("ne", "ね", "ネ"), k("no", "の", "ノ")),
        listOf(k("ha", "は", "ハ"), k("hi", "ひ", "ヒ"), k("fu", "ふ", "フ"), k("he", "へ", "ヘ"), k("ho", "ほ", "ホ")),
        listOf(k("ma", "ま", "マ"), k("mi", "み", "ミ"), k("mu", "む", "ム"), k("me", "め", "メ"), k("mo", "も", "モ")),
        listOf(k("ya", "や", "ヤ"), null, k("yu", "ゆ", "ユ"), null, k("yo", "よ", "ヨ")),
        listOf(k("ra", "ら", "ラ"), k("ri", "り", "リ"), k("ru", "る", "ル"), k("re", "れ", "レ"), k("ro", "ろ", "ロ")),
        listOf(k("wa", "わ", "ワ"), null, null, null, k("wo", "を", "ヲ")),
        listOf(k("n", "ん", "ン")),
    )

    val practicePool: List<Kana> = rows.flatten().filterNotNull()
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `./gradlew :app:testDebugUnitTest --tests 'jp.jacky.kana.practice.KanaTableTest'`
Expected: `BUILD SUCCESSFUL`，3 tests passed。

- [ ] **Step 5: Commit**

```bash
git add source/android/app/src
git commit -m "Add the kana table"
```

---

### Task 4: 出题引擎

**Files:**
- Create: `app/src/main/kotlin/jp/jacky/kana/practice/QuestionEngine.kt`
- Test: `app/src/test/kotlin/jp/jacky/kana/practice/QuestionEngineTest.kt`

**Interfaces:**
- Consumes: `Kana`、`KanaForm`、`KanaTable.practicePool`。
- Produces: `data class Answer(val kana: Kana, val label: String)`；`data class Question(val kana: Kana, val prompt: String, val answers: List<Answer>, val correctIndex: Int)`；`class QuestionEngine(random: Random, pool: List<Kana> = KanaTable.practicePool, answerCount: Int = 4) { fun next(): Question }`。

- [ ] **Step 1: 写失败测试**

```kotlin
package jp.jacky.kana.practice

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

class QuestionEngineTest {
    private fun forms(kana: Kana) = KanaForm.entries.map { kana.text(it) }

    @Test
    fun `every question has one correct answer and three distinct distractors`() {
        val engine = QuestionEngine(Random(1))
        repeat(500) {
            val q = engine.next()
            assertEquals(4, q.answers.size)
            assertTrue(q.correctIndex in 0..3)
            assertEquals(q.kana, q.answers[q.correctIndex].kana)
            assertEquals(1, q.answers.count { it.kana == q.kana })
            assertEquals(4, q.answers.map { it.kana }.toSet().size)
        }
    }

    @Test
    fun `prompt and labels are written in one of the three forms`() {
        val engine = QuestionEngine(Random(2))
        repeat(500) {
            val q = engine.next()
            assertTrue(q.prompt in forms(q.kana))
            assertNotEquals(q.prompt, q.answers[q.correctIndex].label)
            q.answers.forEach { assertTrue(it.label in forms(it.kana)) }
        }
    }

    @Test
    fun `every kana in the pool appears as a question`() {
        val engine = QuestionEngine(Random(3))
        val seen = (1..5000).map { engine.next().kana }.toSet()
        assertEquals(KanaTable.practicePool.toSet(), seen)
    }

    @Test
    fun `the same seed produces the same questions`() {
        val a = QuestionEngine(Random(7))
        val b = QuestionEngine(Random(7))
        repeat(20) { assertEquals(a.next(), b.next()) }
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `./gradlew :app:testDebugUnitTest --tests 'jp.jacky.kana.practice.QuestionEngineTest'`
Expected: 编译失败，`Unresolved reference: QuestionEngine`。

- [ ] **Step 3: 实现**

```kotlin
package jp.jacky.kana.practice

import kotlin.random.Random

data class Answer(val kana: Kana, val label: String)

data class Question(
    val kana: Kana,
    val prompt: String,
    val answers: List<Answer>,
    val correctIndex: Int,
)

/**
 * Builds one question at a time: a random kana shown in one form, the correct answer in a
 * different form, and distinct distractors in random forms.
 */
class QuestionEngine(
    private val random: Random,
    private val pool: List<Kana> = KanaTable.practicePool,
    private val answerCount: Int = 4,
) {
    fun next(): Question {
        val kana = pool.random(random)
        val forms = KanaForm.entries
        val promptForm = forms.random(random)
        val correctForm = forms.filter { it != promptForm }.random(random)
        val distractors = pool.filter { it != kana }.shuffled(random).take(answerCount - 1).iterator()
        val correctIndex = random.nextInt(answerCount)
        val answers = List(answerCount) { index ->
            if (index == correctIndex) {
                Answer(kana, kana.text(correctForm))
            } else {
                val other = distractors.next()
                Answer(other, other.text(forms.random(random)))
            }
        }
        return Question(kana, kana.text(promptForm), answers, correctIndex)
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `./gradlew :app:testDebugUnitTest --tests 'jp.jacky.kana.practice.QuestionEngineTest'`
Expected: 4 tests passed。

- [ ] **Step 5: Commit**

```bash
git add source/android/app/src
git commit -m "Add the question engine"
```

---

### Task 5: 统计存储

**Files:**
- Create: `app/src/main/kotlin/jp/jacky/kana/stats/StatStore.kt`
- Test: `app/src/test/kotlin/jp/jacky/kana/stats/StatStoreTest.kt`

**Interfaces:**
- Produces: `data class StatSummary(totalCount: Int = 0, totalCost: Double = 0.0, recentCosts: List<Double> = emptyList(), currentStreak: Int = 0, bestStreak: Int = 0)` + `averageSeconds: Double?`、`recentSeconds: Double?`、`toJson()`、`companion { RECENT_LIMIT = 10; TIME_LIMIT_SECONDS = 5.0; fromJson(String) }`；`class StatStore(file: File, timeLimitSeconds: Double = 5.0) { val summary: StateFlow<StatSummary>; fun recordAnswer(costSeconds: Double); fun recordStreak(correct: Boolean) }`。

- [ ] **Step 1: 写失败测试**

```kotlin
package jp.jacky.kana.stats

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class StatStoreTest {
    @get:Rule
    val tmp = TemporaryFolder()

    private fun file() = File(tmp.root, "stats.json")

    @Test
    fun `empty store has no averages`() {
        val store = StatStore(file())
        assertEquals(0, store.summary.value.totalCount)
        assertNull(store.summary.value.averageSeconds)
        assertNull(store.summary.value.recentSeconds)
    }

    @Test
    fun `record answer updates count and averages`() {
        val store = StatStore(file())
        store.recordAnswer(1.5)
        store.recordAnswer(2.5)
        assertEquals(2, store.summary.value.totalCount)
        assertEquals(2.0, store.summary.value.averageSeconds!!, 1e-9)
        assertEquals(2.0, store.summary.value.recentSeconds!!, 1e-9)
    }

    @Test
    fun `answers outside the time limit are ignored`() {
        val store = StatStore(file())
        store.recordAnswer(0.0)
        store.recordAnswer(-1.0)
        store.recordAnswer(5.01)
        assertEquals(0, store.summary.value.totalCount)
        store.recordAnswer(5.0)
        assertEquals(1, store.summary.value.totalCount)
    }

    @Test
    fun `recent costs keep the last ten`() {
        val store = StatStore(file())
        (1..12).forEach { store.recordAnswer(it / 10.0) }
        assertEquals((3..12).map { it / 10.0 }, store.summary.value.recentCosts)
    }

    @Test
    fun `streak counts and best streak persist`() {
        val store = StatStore(file())
        store.recordStreak(true)
        store.recordStreak(true)
        assertEquals(2, store.summary.value.currentStreak)
        assertEquals(2, store.summary.value.bestStreak)
        store.recordStreak(false)
        assertEquals(0, store.summary.value.currentStreak)
        assertEquals(2, store.summary.value.bestStreak)
    }

    @Test
    fun `values survive a reload`() {
        StatStore(file()).apply {
            recordAnswer(1.0)
            recordStreak(true)
        }
        val reloaded = StatStore(file()).summary.value
        assertEquals(StatSummary(totalCount = 1, totalCost = 1.0, recentCosts = listOf(1.0), currentStreak = 1, bestStreak = 1), reloaded)
    }

    @Test
    fun `a corrupt file starts from zero`() {
        file().writeText("{not json")
        assertEquals(StatSummary(), StatStore(file()).summary.value)
    }

    @Test
    fun `record keeps working when the file cannot be written`() {
        val blocked = File(tmp.newFile("blocker"), "stats.json") // parent is a file, so writes fail
        val store = StatStore(blocked)
        store.recordAnswer(1.0)
        assertEquals(1, store.summary.value.totalCount)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `./gradlew :app:testDebugUnitTest --tests 'jp.jacky.kana.stats.StatStoreTest'`
Expected: 编译失败，`Unresolved reference: StatStore`。

- [ ] **Step 3: 实现**

```kotlin
package jp.jacky.kana.stats

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.nio.file.Files
import java.nio.file.StandardCopyOption

data class StatSummary(
    val totalCount: Int = 0,
    val totalCost: Double = 0.0,
    val recentCosts: List<Double> = emptyList(),
    val currentStreak: Int = 0,
    val bestStreak: Int = 0,
) {
    val averageSeconds: Double? get() = if (totalCount > 0) totalCost / totalCount else null
    val recentSeconds: Double? get() = if (recentCosts.isEmpty()) null else recentCosts.average()

    fun toJson(): String = JSONObject()
        .put("totalCount", totalCount)
        .put("totalCost", totalCost)
        .put("recentCosts", JSONArray(recentCosts))
        .put("currentStreak", currentStreak)
        .put("bestStreak", bestStreak)
        .toString()

    companion object {
        const val RECENT_LIMIT = 10
        const val TIME_LIMIT_SECONDS = 5.0

        fun fromJson(text: String): StatSummary {
            val json = JSONObject(text)
            val recent = json.optJSONArray("recentCosts")
            return StatSummary(
                totalCount = json.optInt("totalCount"),
                totalCost = json.optDouble("totalCost", 0.0),
                recentCosts = if (recent == null) emptyList() else List(recent.length()) { recent.getDouble(it) },
                currentStreak = json.optInt("currentStreak"),
                bestStreak = json.optInt("bestStreak"),
            )
        }
    }
}

/** Practice statistics kept in a small JSON file. Writes are best effort. */
class StatStore(
    private val file: File,
    private val timeLimitSeconds: Double = StatSummary.TIME_LIMIT_SECONDS,
) {
    private val _summary = MutableStateFlow(load())
    val summary: StateFlow<StatSummary> = _summary.asStateFlow()

    /** Records an answer given within the time limit; costs outside (0, 5] are ignored. */
    fun recordAnswer(costSeconds: Double) {
        if (costSeconds <= 0.0 || costSeconds > timeLimitSeconds) return
        update { current ->
            current.copy(
                totalCount = current.totalCount + 1,
                totalCost = current.totalCost + costSeconds,
                recentCosts = (current.recentCosts + costSeconds).takeLast(StatSummary.RECENT_LIMIT),
            )
        }
    }

    fun recordStreak(correct: Boolean) {
        update { current ->
            val streak = if (correct) current.currentStreak + 1 else 0
            current.copy(currentStreak = streak, bestStreak = maxOf(current.bestStreak, streak))
        }
    }

    private fun update(transform: (StatSummary) -> StatSummary) {
        val next = transform(_summary.value)
        _summary.value = next
        save(next)
    }

    private fun load(): StatSummary = try {
        if (file.isFile) StatSummary.fromJson(file.readText()) else StatSummary()
    } catch (e: Exception) {
        StatSummary()
    }

    private fun save(summary: StatSummary) {
        try {
            file.parentFile?.mkdirs()
            val temp = File(file.parentFile, file.name + ".tmp")
            temp.writeText(summary.toJson())
            Files.move(temp.toPath(), file.toPath(), StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
        } catch (e: Exception) {
            // Losing one record is acceptable.
        }
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `./gradlew :app:testDebugUnitTest --tests 'jp.jacky.kana.stats.StatStoreTest'`
Expected: 8 tests passed。

- [ ] **Step 5: Commit**

```bash
git add source/android/app/src
git commit -m "Add the JSON statistics store"
```

---

### Task 6: 服务接口、假实现、AppContainer

**Files:**
- Create: `app/src/main/kotlin/jp/jacky/kana/practice/Clock.kt`
- Create: `app/src/main/kotlin/jp/jacky/kana/sound/SoundPlayer.kt`
- Create: `app/src/main/kotlin/jp/jacky/kana/store/CoffeeStore.kt`
- Create: `app/src/main/kotlin/jp/jacky/kana/store/BillingGateway.kt`
- Create: `app/src/main/kotlin/jp/jacky/kana/ads/AdsManager.kt`
- Create: `app/src/main/kotlin/jp/jacky/kana/share/ShareActions.kt`
- Create: `app/src/main/kotlin/jp/jacky/kana/di/AppContainer.kt`
- Create: `app/src/sharedTest/kotlin/jp/jacky/kana/testing/Fakes.kt`
- Test: `app/src/test/kotlin/jp/jacky/kana/testing/FakesTest.kt`

**Interfaces:**
- Produces（后续任务都依赖这些签名）:

```kotlin
// practice/Clock.kt
fun interface Clock { fun nowMillis(): Long }

// sound/SoundPlayer.kt
interface SoundPlayer { fun playCorrect(); fun playIncorrect() }

// store/CoffeeStore.kt
enum class PurchaseOutcome { PURCHASED, CANCELLED, PENDING }
sealed class StoreException(message: String) : Exception(message) {
    class ProductUnavailable : StoreException("The coffee product is unavailable")
    class Billing(val responseCode: Int, val debugMessage: String) : StoreException("Billing error $responseCode: $debugMessage")
}
interface CoffeeStore {
    val adsRemoved: StateFlow<Boolean>
    val price: StateFlow<String?>
    suspend fun loadProduct()
    suspend fun purchase(activity: Activity): PurchaseOutcome
    suspend fun restore(): Boolean
}
interface AdsRemovedStorage { fun read(): Boolean; fun write(value: Boolean) }

// store/BillingGateway.kt
class CoffeeProduct(val price: String, internal val details: ProductDetails?)
data class PurchaseRecord(val purchased: Boolean, val pending: Boolean, val acknowledged: Boolean, val token: String)
data class PurchaseUpdate(val responseCode: Int, val records: List<PurchaseRecord>)
interface BillingGateway {
    val purchaseUpdates: SharedFlow<PurchaseUpdate>
    suspend fun connect(): Int
    suspend fun queryCoffeePurchases(): List<PurchaseRecord>
    suspend fun queryCoffeeProduct(): CoffeeProduct?
    suspend fun acknowledge(token: String): Int
    fun launchBillingFlow(activity: Activity, product: CoffeeProduct): Int
}

// ads/AdsManager.kt
interface AdsManager {
    val isReady: StateFlow<Boolean>
    val privacyOptionsRequired: StateFlow<Boolean>
    fun gatherConsent(activity: Activity)
    fun showPrivacyOptions(activity: Activity)
}

// share/ShareActions.kt
interface ShareActions { fun share(activity: Activity); fun canSendFeedback(): Boolean; fun sendFeedback(activity: Activity) }

// di/AppContainer.kt
interface AppContainer {
    val random: Random; val clock: Clock; val timeLimitMillis: Long; val statStore: StatStore; val coffeeStore: CoffeeStore
    val adsManager: AdsManager; val soundPlayer: SoundPlayer; val shareActions: ShareActions
}
```

- [ ] **Step 1: 写接口文件**

`practice/Clock.kt`：

```kotlin
package jp.jacky.kana.practice

/** Monotonic time in milliseconds; injected so tests can drive it. */
fun interface Clock {
    fun nowMillis(): Long
}
```

`sound/SoundPlayer.kt`：

```kotlin
package jp.jacky.kana.sound

interface SoundPlayer {
    fun playCorrect()
    fun playIncorrect()
}
```

`store/CoffeeStore.kt`：

```kotlin
package jp.jacky.kana.store

import android.app.Activity
import android.content.Context
import kotlinx.coroutines.flow.StateFlow

enum class PurchaseOutcome { PURCHASED, CANCELLED, PENDING }

sealed class StoreException(message: String) : Exception(message) {
    class ProductUnavailable : StoreException("The coffee product is unavailable")
    class Billing(val responseCode: Int, val debugMessage: String) :
        StoreException("Billing error $responseCode: $debugMessage")
}

/** "Buy me a coffee" one-time purchase that removes ads. */
interface CoffeeStore {
    val adsRemoved: StateFlow<Boolean>
    /** Localized price text, or null while unknown. */
    val price: StateFlow<String?>
    suspend fun loadProduct()
    suspend fun purchase(activity: Activity): PurchaseOutcome
    /** Returns true when a previous purchase was found. */
    suspend fun restore(): Boolean
}

interface AdsRemovedStorage {
    fun read(): Boolean
    fun write(value: Boolean)
}

class PrefsAdsRemovedStorage(context: Context) : AdsRemovedStorage {
    private val prefs = context.getSharedPreferences("kana", Context.MODE_PRIVATE)
    override fun read(): Boolean = prefs.getBoolean(KEY, false)
    override fun write(value: Boolean) {
        prefs.edit().putBoolean(KEY, value).apply()
    }

    private companion object {
        const val KEY = "user.purchase.adsRemoved"
    }
}
```

`store/BillingGateway.kt`：

```kotlin
package jp.jacky.kana.store

import android.app.Activity
import com.android.billingclient.api.ProductDetails
import kotlinx.coroutines.flow.SharedFlow

/** The coffee product with its Play details; the details stay internal so fakes need none. */
class CoffeeProduct(val price: String, internal val details: ProductDetails?)

data class PurchaseRecord(
    val purchased: Boolean,
    val pending: Boolean,
    val acknowledged: Boolean,
    val token: String,
)

/** One PurchasesUpdatedListener callback, reduced to the coffee product. */
data class PurchaseUpdate(val responseCode: Int, val records: List<PurchaseRecord>)

/** Thin wrapper over BillingClient so the store logic can be unit tested. Response codes are BillingClient.BillingResponseCode values. */
interface BillingGateway {
    val purchaseUpdates: SharedFlow<PurchaseUpdate>
    suspend fun connect(): Int
    suspend fun queryCoffeePurchases(): List<PurchaseRecord>
    suspend fun queryCoffeeProduct(): CoffeeProduct?
    suspend fun acknowledge(token: String): Int
    fun launchBillingFlow(activity: Activity, product: CoffeeProduct): Int
}
```

`ads/AdsManager.kt`：

```kotlin
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
```

`share/ShareActions.kt`：

```kotlin
package jp.jacky.kana.share

import android.app.Activity

interface ShareActions {
    fun share(activity: Activity)
    fun canSendFeedback(): Boolean
    fun sendFeedback(activity: Activity)
}
```

`di/AppContainer.kt`：

```kotlin
package jp.jacky.kana.di

import jp.jacky.kana.ads.AdsManager
import jp.jacky.kana.practice.Clock
import jp.jacky.kana.share.ShareActions
import jp.jacky.kana.sound.SoundPlayer
import jp.jacky.kana.stats.StatStore
import jp.jacky.kana.store.CoffeeStore
import kotlin.random.Random

interface AppContainer {
    val random: Random
    val clock: Clock
    /** Per-question time limit; UI tests raise it so a slow emulator does not time out. */
    val timeLimitMillis: Long
    val statStore: StatStore
    val coffeeStore: CoffeeStore
    val adsManager: AdsManager
    val soundPlayer: SoundPlayer
    val shareActions: ShareActions
}
```

- [ ] **Step 2: 写共享假实现**

`app/src/sharedTest/kotlin/jp/jacky/kana/testing/Fakes.kt`：

```kotlin
package jp.jacky.kana.testing

import android.app.Activity
import jp.jacky.kana.ads.AdsManager
import jp.jacky.kana.practice.Clock
import jp.jacky.kana.share.ShareActions
import jp.jacky.kana.sound.SoundPlayer
import jp.jacky.kana.store.AdsRemovedStorage
import jp.jacky.kana.store.BillingGateway
import jp.jacky.kana.store.CoffeeProduct
import jp.jacky.kana.store.CoffeeStore
import jp.jacky.kana.store.PurchaseOutcome
import jp.jacky.kana.store.PurchaseRecord
import jp.jacky.kana.store.PurchaseUpdate
import jp.jacky.kana.store.StoreException
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestCoroutineScheduler

class FakeSoundPlayer : SoundPlayer {
    var correctCount = 0
    var incorrectCount = 0
    override fun playCorrect() { correctCount++ }
    override fun playIncorrect() { incorrectCount++ }
}

class FakeClock(private val scheduler: TestCoroutineScheduler) : Clock {
    override fun nowMillis(): Long = scheduler.currentTime
}

class FakeCoffeeStore(initialAdsRemoved: Boolean = false, var productPrice: String? = "¥300") : CoffeeStore {
    override val adsRemoved = MutableStateFlow(initialAdsRemoved)
    override val price = MutableStateFlow<String?>(null)
    var purchaseOutcome = PurchaseOutcome.PURCHASED
    var purchaseError: StoreException? = null
    var restoreResult = false
    var loadCount = 0

    override suspend fun loadProduct() {
        loadCount++
        price.value = productPrice
    }

    override suspend fun purchase(activity: Activity): PurchaseOutcome {
        purchaseError?.let { throw it }
        if (purchaseOutcome == PurchaseOutcome.PURCHASED) adsRemoved.value = true
        return purchaseOutcome
    }

    override suspend fun restore(): Boolean {
        if (restoreResult) adsRemoved.value = true
        return restoreResult
    }
}

class FakeAdsManager : AdsManager {
    override val isReady = MutableStateFlow(false)
    override val privacyOptionsRequired = MutableStateFlow(false)
    var gatherConsentCalls = 0
    var showPrivacyOptionsCalls = 0
    override fun gatherConsent(activity: Activity) { gatherConsentCalls++ }
    override fun showPrivacyOptions(activity: Activity) { showPrivacyOptionsCalls++ }
}

class FakeShareActions(private val feedbackAvailable: Boolean = true) : ShareActions {
    var shareCalls = 0
    var feedbackCalls = 0
    override fun share(activity: Activity) { shareCalls++ }
    override fun canSendFeedback(): Boolean = feedbackAvailable
    override fun sendFeedback(activity: Activity) { feedbackCalls++ }
}

class InMemoryAdsRemovedStorage(private var value: Boolean = false) : AdsRemovedStorage {
    override fun read(): Boolean = value
    override fun write(value: Boolean) { this.value = value }
}

class FakeBillingGateway : BillingGateway {
    override val purchaseUpdates = MutableSharedFlow<PurchaseUpdate>(extraBufferCapacity = 8)
    var connectResult = 0 // BillingResponseCode.OK
    var purchases: List<PurchaseRecord> = emptyList()
    var product: CoffeeProduct? = CoffeeProduct("¥300", null)
    var launchResult = 0
    /** Runs inside launchBillingFlow, so tests can emit the Play callback. */
    var onLaunch: (() -> Unit)? = null
    val acknowledged = mutableListOf<String>()
    var connectCalls = 0

    override suspend fun connect(): Int { connectCalls++; return connectResult }
    override suspend fun queryCoffeePurchases(): List<PurchaseRecord> = purchases
    override suspend fun queryCoffeeProduct(): CoffeeProduct? = product
    override suspend fun acknowledge(token: String): Int { acknowledged += token; return 0 }
    override fun launchBillingFlow(activity: Activity, product: CoffeeProduct): Int {
        onLaunch?.invoke()
        return launchResult
    }
}
```

- [ ] **Step 3: 写一个编译级测试确认共享源集生效**

`app/src/test/kotlin/jp/jacky/kana/testing/FakesTest.kt`：

```kotlin
package jp.jacky.kana.testing

import kotlinx.coroutines.test.TestCoroutineScheduler
import org.junit.Assert.assertEquals
import org.junit.Test

class FakesTest {
    @Test
    fun `fake clock follows the scheduler`() {
        val scheduler = TestCoroutineScheduler()
        val clock = FakeClock(scheduler)
        scheduler.advanceTimeBy(1234)
        assertEquals(1234L, clock.nowMillis())
    }
}
```

- [ ] **Step 4: 运行**

Run: `./gradlew :app:testDebugUnitTest --tests 'jp.jacky.kana.testing.FakesTest' :app:compileDebugAndroidTestKotlin`
Expected: `BUILD SUCCESSFUL`，1 test passed；androidTest 编译通过（证明 `sharedTest` 同时进了两个源集）。

- [ ] **Step 5: Commit**

```bash
git add source/android/app/src
git commit -m "Define service interfaces, the app container, and shared test fakes"
```

---

### Task 7: Play Billing 咖啡商店

**Files:**
- Create: `app/src/main/kotlin/jp/jacky/kana/store/PlayCoffeeStore.kt`
- Create: `app/src/main/kotlin/jp/jacky/kana/store/PlayBillingGateway.kt`
- Test: `app/src/test/kotlin/jp/jacky/kana/store/PlayCoffeeStoreTest.kt`

**Interfaces:**
- Consumes: Task 6 的 `BillingGateway`、`CoffeeStore`、`AdsRemovedStorage`、`FakeBillingGateway`、`InMemoryAdsRemovedStorage`。
- Produces: `class PlayCoffeeStore(gateway: BillingGateway, storage: AdsRemovedStorage, scope: CoroutineScope) : CoffeeStore { fun start() }`；`class PlayBillingGateway(context: Context, productId: String) : BillingGateway`。

- [ ] **Step 1: 写失败测试**

```kotlin
package jp.jacky.kana.store

import android.app.Activity
import com.android.billingclient.api.BillingClient.BillingResponseCode
import jp.jacky.kana.testing.FakeBillingGateway
import jp.jacky.kana.testing.InMemoryAdsRemovedStorage
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class PlayCoffeeStoreTest {
    private val gateway = FakeBillingGateway()
    private val storage = InMemoryAdsRemovedStorage()
    private val activity = Activity()

    private fun record(purchased: Boolean = true, pending: Boolean = false, acknowledged: Boolean = false) =
        PurchaseRecord(purchased = purchased, pending = pending, acknowledged = acknowledged, token = "token-1")

    @Test
    fun `start refreshes the entitlement and loads the price`() = runTest {
        storage.write(true) // stale cache from a refunded purchase
        gateway.purchases = emptyList()
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        assertTrue(store.adsRemoved.value)
        store.start()
        runCurrent()
        assertFalse(store.adsRemoved.value)
        assertFalse(storage.read())
        assertEquals("¥300", store.price.value)
    }

    @Test
    fun `purchase acknowledges and removes ads`() = runTest {
        gateway.onLaunch = { gateway.purchaseUpdates.tryEmit(PurchaseUpdate(BillingResponseCode.OK, listOf(record()))) }
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        assertEquals(PurchaseOutcome.PURCHASED, store.purchase(activity))
        assertTrue(store.adsRemoved.value)
        assertTrue(storage.read())
        assertEquals(listOf("token-1"), gateway.acknowledged)
    }

    @Test
    fun `pending purchase keeps ads`() = runTest {
        gateway.onLaunch = { gateway.purchaseUpdates.tryEmit(PurchaseUpdate(BillingResponseCode.OK, listOf(record(purchased = false, pending = true)))) }
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        assertEquals(PurchaseOutcome.PENDING, store.purchase(activity))
        assertFalse(store.adsRemoved.value)
    }

    @Test
    fun `user cancel returns CANCELLED`() = runTest {
        gateway.onLaunch = { gateway.purchaseUpdates.tryEmit(PurchaseUpdate(BillingResponseCode.USER_CANCELED, emptyList())) }
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        assertEquals(PurchaseOutcome.CANCELLED, store.purchase(activity))
    }

    @Test
    fun `purchase returns CANCELLED when the update has no coffee record`() = runTest {
        gateway.onLaunch = { gateway.purchaseUpdates.tryEmit(PurchaseUpdate(BillingResponseCode.OK, emptyList())) }
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        assertEquals(PurchaseOutcome.CANCELLED, store.purchase(activity))
        assertFalse(store.adsRemoved.value)
    }

    @Test
    fun `already owned refreshes the entitlement`() = runTest {
        gateway.purchases = listOf(record(acknowledged = true))
        gateway.onLaunch = { gateway.purchaseUpdates.tryEmit(PurchaseUpdate(BillingResponseCode.ITEM_ALREADY_OWNED, emptyList())) }
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        assertEquals(PurchaseOutcome.PURCHASED, store.purchase(activity))
        assertTrue(store.adsRemoved.value)
    }

    @Test
    fun `billing errors are reported`() = runTest {
        gateway.onLaunch = { gateway.purchaseUpdates.tryEmit(PurchaseUpdate(BillingResponseCode.SERVICE_DISCONNECTED, emptyList())) }
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        try {
            store.purchase(activity)
            fail("expected StoreException.Billing")
        } catch (e: StoreException.Billing) {
            assertEquals(BillingResponseCode.SERVICE_DISCONNECTED, e.responseCode)
        }
    }

    @Test
    fun `launch failure is reported without waiting`() = runTest {
        gateway.launchResult = BillingResponseCode.BILLING_UNAVAILABLE
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        try {
            store.purchase(activity)
            fail("expected StoreException.Billing")
        } catch (e: StoreException.Billing) {
            assertEquals(BillingResponseCode.BILLING_UNAVAILABLE, e.responseCode)
        }
    }

    @Test
    fun `missing product throws ProductUnavailable`() = runTest {
        gateway.product = null
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        store.loadProduct()
        assertEquals(null, store.price.value)
        try {
            store.purchase(activity)
            fail("expected ProductUnavailable")
        } catch (e: StoreException.ProductUnavailable) {
            // expected
        }
    }

    @Test
    fun `restore reports and applies an existing purchase`() = runTest {
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        assertFalse(store.restore())
        gateway.purchases = listOf(record())
        assertTrue(store.restore())
        assertTrue(store.adsRemoved.value)
        assertEquals(listOf("token-1"), gateway.acknowledged)
    }

    @Test
    fun `connection failure leaves the price unknown`() = runTest {
        gateway.connectResult = BillingResponseCode.BILLING_UNAVAILABLE
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        store.loadProduct()
        assertEquals(null, store.price.value)
        assertFalse(store.restore())
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `./gradlew :app:testDebugUnitTest --tests 'jp.jacky.kana.store.PlayCoffeeStoreTest'`
Expected: 编译失败，`Unresolved reference: PlayCoffeeStore`。

- [ ] **Step 3: 实现 PlayCoffeeStore**

```kotlin
package jp.jacky.kana.store

import android.app.Activity
import com.android.billingclient.api.BillingClient.BillingResponseCode
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

/** Coffee purchase backed by Play Billing through a [BillingGateway]. */
class PlayCoffeeStore(
    private val gateway: BillingGateway,
    private val storage: AdsRemovedStorage,
    private val scope: CoroutineScope,
) : CoffeeStore {

    private val _adsRemoved = MutableStateFlow(storage.read())
    override val adsRemoved: StateFlow<Boolean> = _adsRemoved.asStateFlow()

    private val _price = MutableStateFlow<String?>(null)
    override val price: StateFlow<String?> = _price.asStateFlow()

    private var product: CoffeeProduct? = null
    private val acknowledgedTokens = mutableSetOf<String>()

    /** Call once at launch: listens for purchase updates, refreshes the entitlement, loads the price. */
    fun start() {
        scope.launch {
            gateway.purchaseUpdates.collect { update ->
                if (update.responseCode == BillingResponseCode.OK) applyRecords(update.records, fromQuery = false)
            }
        }
        scope.launch {
            refreshEntitlement()
            loadProduct()
        }
    }

    override suspend fun loadProduct() {
        if (gateway.connect() != BillingResponseCode.OK) return
        product = gateway.queryCoffeeProduct()
        _price.value = product?.price
    }

    override suspend fun purchase(activity: Activity): PurchaseOutcome {
        if (product == null) loadProduct()
        val current = product ?: throw StoreException.ProductUnavailable()
        return coroutineScope {
            // Subscribe before launching so a fast callback is not missed.
            val update = async(start = CoroutineStart.UNDISPATCHED) { gateway.purchaseUpdates.first() }
            val launch = gateway.launchBillingFlow(activity, current)
            if (launch != BillingResponseCode.OK) {
                update.cancel()
                throw StoreException.Billing(launch, "launchBillingFlow")
            }
            val result = update.await()
            when {
                result.responseCode == BillingResponseCode.OK && result.records.any { it.purchased } -> {
                    applyRecords(result.records, fromQuery = false)
                    PurchaseOutcome.PURCHASED
                }
                result.responseCode == BillingResponseCode.OK && result.records.any { it.pending } -> PurchaseOutcome.PENDING
                result.responseCode == BillingResponseCode.OK -> PurchaseOutcome.CANCELLED
                result.responseCode == BillingResponseCode.USER_CANCELED -> PurchaseOutcome.CANCELLED
                result.responseCode == BillingResponseCode.ITEM_ALREADY_OWNED -> {
                    refreshEntitlement()
                    if (_adsRemoved.value) PurchaseOutcome.PURCHASED
                    else throw StoreException.Billing(result.responseCode, "already owned but not found")
                }
                else -> throw StoreException.Billing(result.responseCode, "purchase")
            }
        }
    }

    override suspend fun restore(): Boolean {
        refreshEntitlement()
        return _adsRemoved.value
    }

    private suspend fun refreshEntitlement() {
        if (gateway.connect() != BillingResponseCode.OK) return
        applyRecords(gateway.queryCoffeePurchases(), fromQuery = true)
    }

    /** Acknowledges new purchases and updates the entitlement. A full query may also revoke it. */
    private suspend fun applyRecords(records: List<PurchaseRecord>, fromQuery: Boolean) {
        val purchased = records.filter { it.purchased }
        for (record in purchased) {
            if (!record.acknowledged && acknowledgedTokens.add(record.token)) gateway.acknowledge(record.token)
        }
        if (purchased.isNotEmpty()) setAdsRemoved(true) else if (fromQuery) setAdsRemoved(false)
    }

    private fun setAdsRemoved(value: Boolean) {
        if (_adsRemoved.value == value) return
        _adsRemoved.value = value
        storage.write(value)
    }
}
```

- [ ] **Step 4: 实现 PlayBillingGateway**

```kotlin
package jp.jacky.kana.store

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClient.BillingResponseCode
import com.android.billingclient.api.BillingClient.ProductType
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

class PlayBillingGateway(context: Context, private val productId: String) : BillingGateway {

    private val _updates = MutableSharedFlow<PurchaseUpdate>(extraBufferCapacity = 8)
    override val purchaseUpdates: SharedFlow<PurchaseUpdate> = _updates.asSharedFlow()

    private val client: BillingClient = BillingClient.newBuilder(context)
        .setListener { result, purchases ->
            _updates.tryEmit(PurchaseUpdate(result.responseCode, purchases.orEmpty().toRecords()))
        }
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
        .enableAutoServiceReconnection()
        .build()

    override suspend fun connect(): Int {
        if (client.isReady) return BillingResponseCode.OK
        return suspendCancellableCoroutine { continuation ->
            client.startConnection(object : BillingClientStateListener {
                override fun onBillingSetupFinished(result: BillingResult) {
                    if (continuation.isActive) continuation.resume(result.responseCode)
                }

                override fun onBillingServiceDisconnected() {
                    // Auto reconnection is enabled on the client.
                }
            })
        }
    }

    override suspend fun queryCoffeePurchases(): List<PurchaseRecord> = suspendCancellableCoroutine { continuation ->
        val params = QueryPurchasesParams.newBuilder().setProductType(ProductType.INAPP).build()
        client.queryPurchasesAsync(params) { result, purchases ->
            val records = if (result.responseCode == BillingResponseCode.OK) purchases.toRecords() else emptyList()
            if (continuation.isActive) continuation.resume(records)
        }
    }

    override suspend fun queryCoffeeProduct(): CoffeeProduct? = suspendCancellableCoroutine { continuation ->
        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(
                listOf(
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(productId)
                        .setProductType(ProductType.INAPP)
                        .build()
                )
            )
            .build()
        client.queryProductDetailsAsync(params) { result, details ->
            val product = details.productDetailsList.firstOrNull { it.productId == productId }
            val price = product?.oneTimePurchaseOfferDetails?.formattedPrice
            val coffee = if (result.responseCode == BillingResponseCode.OK && product != null && price != null) {
                CoffeeProduct(price, product)
            } else {
                null
            }
            if (continuation.isActive) continuation.resume(coffee)
        }
    }

    override suspend fun acknowledge(token: String): Int = suspendCancellableCoroutine { continuation ->
        val params = AcknowledgePurchaseParams.newBuilder().setPurchaseToken(token).build()
        client.acknowledgePurchase(params) { result ->
            if (continuation.isActive) continuation.resume(result.responseCode)
        }
    }

    override fun launchBillingFlow(activity: Activity, product: CoffeeProduct): Int {
        val details = product.details ?: return BillingResponseCode.ITEM_UNAVAILABLE
        val params = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(
                listOf(BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(details).build())
            )
            .build()
        return client.launchBillingFlow(activity, params).responseCode
    }

    private fun List<Purchase>.toRecords(): List<PurchaseRecord> = filter { productId in it.products }.map {
        PurchaseRecord(
            purchased = it.purchaseState == Purchase.PurchaseState.PURCHASED,
            pending = it.purchaseState == Purchase.PurchaseState.PENDING,
            acknowledged = it.isAcknowledged,
            token = it.purchaseToken,
        )
    }
}
```

- [ ] **Step 5: 运行测试确认通过**

Run: `./gradlew :app:testDebugUnitTest --tests 'jp.jacky.kana.store.PlayCoffeeStoreTest'`
Expected: 11 tests passed。若 `queryProductDetailsAsync` 的回调参数类型与 Billing 9.1 不符（编译错误），以 `com.android.billingclient.api.QueryProductDetailsResult` 的实际 API 为准修正 `productDetailsList` 的读取方式。

- [ ] **Step 6: Commit**

```bash
git add source/android/app/src
git commit -m "Add the Play Billing coffee store"
```

---

### Task 8: 练习 ViewModel

**Files:**
- Create: `app/src/main/kotlin/jp/jacky/kana/practice/PracticeViewModel.kt`
- Test: `app/src/test/kotlin/jp/jacky/kana/practice/PracticeViewModelTest.kt`

**Interfaces:**
- Consumes: `QuestionEngine`、`StatStore`、`SoundPlayer`、`Clock`、`CoffeeStore`、`AdsManager`、`AppContainer`，假实现。
- Produces:

```kotlin
enum class Sheet { CHART, COFFEE }
data class PracticeUiState(
    val question: Question, val revealCorrect: Boolean = false, val stats: StatSummary = StatSummary(),
    val menuExpanded: Boolean = false, val sheet: Sheet? = null, val bannerRequested: Boolean = false,
    val bannerAllowed: Boolean = false, val adsRemoved: Boolean = false, val privacyOptionsAvailable: Boolean = false,
) { val showBanner: Boolean }
class PracticeViewModel(engine, statStore, sound, clock, coffeeStore, adsManager, timeLimitMillis = 5_000L) : ViewModel() {
    val state: StateFlow<PracticeUiState>
    fun answer(index: Int); fun toggleMenu(); fun openChart(); fun openCoffee(); fun closeSheet()
    fun setInBackground(background: Boolean); fun bannerFailed()
    companion object { fun factory(container: AppContainer): ViewModelProvider.Factory }
}
```

- [ ] **Step 1: 写失败测试**

```kotlin
package jp.jacky.kana.practice

import jp.jacky.kana.stats.StatStore
import jp.jacky.kana.testing.FakeAdsManager
import jp.jacky.kana.testing.FakeClock
import jp.jacky.kana.testing.FakeCoffeeStore
import jp.jacky.kana.testing.FakeSoundPlayer
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File
import kotlin.random.Random

@OptIn(ExperimentalCoroutinesApi::class)
class PracticeViewModelTest {
    @get:Rule
    val tmp = TemporaryFolder()

    private val dispatcher = StandardTestDispatcher()
    private val sound = FakeSoundPlayer()
    private val coffee = FakeCoffeeStore()
    private val ads = FakeAdsManager().apply { isReady.value = true }
    private lateinit var statStore: StatStore

    @Before
    fun setUp() {
        Dispatchers.setMain(dispatcher)
        statStore = StatStore(File(tmp.root, "stats.json"))
    }

    @After
    fun tearDown() = Dispatchers.resetMain()

    private fun TestScope.viewModel() = PracticeViewModel(
        engine = QuestionEngine(Random(1)),
        statStore = statStore,
        sound = sound,
        clock = FakeClock(testScheduler),
        coffeeStore = coffee,
        adsManager = ads,
    ).also { runCurrent() }

    private fun PracticeUiState.wrongIndex() = (0..3).first { it != question.correctIndex }

    @Test
    fun `correct answer records the cost, extends the streak, and moves on`() = runTest(dispatcher) {
        val vm = viewModel()
        val first = vm.state.value.question
        advanceTimeBy(1500)
        vm.answer(first.correctIndex)
        runCurrent()
        val state = vm.state.value
        assertNotEquals(first, state.question)
        assertFalse(state.revealCorrect)
        assertEquals(1, state.stats.totalCount)
        assertEquals(1.5, state.stats.recentSeconds!!, 1e-9)
        assertEquals(1, state.stats.currentStreak)
        assertEquals(1, state.stats.bestStreak)
        assertEquals(1, sound.correctCount)
    }

    @Test
    fun `wrong answer reveals the correct one, requests the banner, and resets the streak`() = runTest(dispatcher) {
        val vm = viewModel()
        advanceTimeBy(1000)
        vm.answer(vm.state.value.question.correctIndex)
        runCurrent()
        advanceTimeBy(1000)
        val question = vm.state.value.question
        vm.answer(vm.state.value.wrongIndex())
        runCurrent()
        val state = vm.state.value
        assertEquals(question, state.question)
        assertTrue(state.revealCorrect)
        assertTrue(state.bannerRequested)
        assertTrue(state.showBanner)
        assertEquals(2, state.stats.totalCount)
        assertEquals(0, state.stats.currentStreak)
        assertEquals(1, state.stats.bestStreak)
        assertEquals(1, sound.incorrectCount)
    }

    @Test
    fun `timeout counts as wrong without a statistic`() = runTest(dispatcher) {
        val vm = viewModel()
        advanceTimeBy(5001)
        runCurrent()
        val state = vm.state.value
        assertTrue(state.revealCorrect)
        assertTrue(state.bannerRequested)
        assertEquals(0, state.stats.totalCount)
        assertEquals(1, sound.incorrectCount)
    }

    @Test
    fun `timeout fires at exactly the limit`() = runTest(dispatcher) {
        val vm = viewModel()
        advanceTimeBy(4999)
        runCurrent()
        assertFalse(vm.state.value.revealCorrect)
        advanceTimeBy(1)
        runCurrent()
        assertTrue(vm.state.value.revealCorrect)
        // A tap now is handled as a reveal-state tap: no statistic, no streak.
        vm.answer(vm.state.value.question.correctIndex)
        runCurrent()
        assertEquals(0, vm.state.value.stats.totalCount)
        assertEquals(0, vm.state.value.stats.currentStreak)
        assertFalse(vm.state.value.revealCorrect)
    }

    @Test
    fun `after a reveal the correct answer moves on without counting`() = runTest(dispatcher) {
        val vm = viewModel()
        advanceTimeBy(1000)
        vm.answer(vm.state.value.wrongIndex())
        runCurrent()
        val revealed = vm.state.value.question
        vm.answer(revealed.correctIndex)
        runCurrent()
        val state = vm.state.value
        assertNotEquals(revealed, state.question)
        assertFalse(state.revealCorrect)
        assertFalse(state.bannerRequested)
        assertEquals(1, state.stats.totalCount)
        assertEquals(0, state.stats.currentStreak)
        assertEquals(1, sound.correctCount)
    }

    @Test
    fun `double tap on a wrong answer records one answer`() = runTest(dispatcher) {
        val vm = viewModel()
        advanceTimeBy(1000)
        val wrong = vm.state.value.wrongIndex()
        vm.answer(wrong)
        vm.answer(wrong)
        runCurrent()
        val state = vm.state.value
        assertTrue(state.revealCorrect)
        assertEquals(1, state.stats.totalCount)
        assertEquals(0, state.stats.currentStreak)
        assertEquals(2, sound.incorrectCount)
    }

    @Test
    fun `menu pauses the timer and paused time is not answer time`() = runTest(dispatcher) {
        val vm = viewModel()
        vm.toggleMenu()
        runCurrent()
        assertTrue(vm.state.value.menuExpanded)
        advanceTimeBy(10_000)
        runCurrent()
        assertFalse(vm.state.value.revealCorrect)
        vm.toggleMenu()
        runCurrent()
        advanceTimeBy(1000)
        vm.answer(vm.state.value.question.correctIndex)
        runCurrent()
        assertEquals(1.0, vm.state.value.stats.recentSeconds!!, 1e-9)
    }

    @Test
    fun `sheets and background pause the timer`() = runTest(dispatcher) {
        val vm = viewModel()
        vm.openChart()
        runCurrent()
        assertEquals(Sheet.CHART, vm.state.value.sheet)
        advanceTimeBy(10_000)
        vm.closeSheet()
        runCurrent()
        assertNull(vm.state.value.sheet)
        vm.setInBackground(true)
        advanceTimeBy(10_000)
        runCurrent()
        assertFalse(vm.state.value.revealCorrect)
        vm.setInBackground(false)
        advanceTimeBy(5001)
        runCurrent()
        assertTrue(vm.state.value.revealCorrect)
    }

    @Test
    fun `answering collapses the menu`() = runTest(dispatcher) {
        val vm = viewModel()
        vm.toggleMenu()
        runCurrent()
        vm.answer(vm.state.value.question.correctIndex)
        runCurrent()
        assertFalse(vm.state.value.menuExpanded)
    }

    @Test
    fun `banner stays hidden until ads are ready`() = runTest(dispatcher) {
        ads.isReady.value = false
        val vm = viewModel()
        advanceTimeBy(1000)
        vm.answer(vm.state.value.wrongIndex())
        runCurrent()
        assertTrue(vm.state.value.bannerRequested)
        assertFalse(vm.state.value.showBanner)
        ads.isReady.value = true
        runCurrent()
        assertTrue(vm.state.value.showBanner)
    }

    @Test
    fun `removing ads hides the banner and the privacy entry`() = runTest(dispatcher) {
        ads.privacyOptionsRequired.value = true
        val vm = viewModel()
        runCurrent()
        assertTrue(vm.state.value.privacyOptionsAvailable)
        advanceTimeBy(1000)
        vm.answer(vm.state.value.wrongIndex())
        runCurrent()
        assertTrue(vm.state.value.showBanner)
        coffee.adsRemoved.value = true
        runCurrent()
        val state = vm.state.value
        assertTrue(state.adsRemoved)
        assertFalse(state.showBanner)
        assertFalse(state.bannerRequested)
        assertFalse(state.privacyOptionsAvailable)
    }

    @Test
    fun `banner failure collapses the slot`() = runTest(dispatcher) {
        val vm = viewModel()
        advanceTimeBy(1000)
        vm.answer(vm.state.value.wrongIndex())
        runCurrent()
        vm.bannerFailed()
        runCurrent()
        assertFalse(vm.state.value.showBanner)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `./gradlew :app:testDebugUnitTest --tests 'jp.jacky.kana.practice.PracticeViewModelTest'`
Expected: 编译失败，`Unresolved reference: PracticeViewModel`。

- [ ] **Step 3: 实现**

```kotlin
package jp.jacky.kana.practice

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import jp.jacky.kana.ads.AdsManager
import jp.jacky.kana.di.AppContainer
import jp.jacky.kana.sound.SoundPlayer
import jp.jacky.kana.stats.StatStore
import jp.jacky.kana.stats.StatSummary
import jp.jacky.kana.store.CoffeeStore
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

enum class Sheet { CHART, COFFEE }

data class PracticeUiState(
    val question: Question,
    val revealCorrect: Boolean = false,
    val stats: StatSummary = StatSummary(),
    val menuExpanded: Boolean = false,
    val sheet: Sheet? = null,
    val bannerRequested: Boolean = false,
    val bannerAllowed: Boolean = false,
    val adsRemoved: Boolean = false,
    val privacyOptionsAvailable: Boolean = false,
) {
    val showBanner: Boolean get() = bannerRequested && bannerAllowed
}

/**
 * The practice loop: one question at a time with a five second limit. Time spent with the menu,
 * a sheet, or the app in the background is not answer time.
 */
class PracticeViewModel(
    private val engine: QuestionEngine,
    private val statStore: StatStore,
    private val sound: SoundPlayer,
    private val clock: Clock,
    coffeeStore: CoffeeStore,
    adsManager: AdsManager,
    private val timeLimitMillis: Long = 5_000L,
) : ViewModel() {

    private val _state = MutableStateFlow(PracticeUiState(question = engine.next(), stats = statStore.summary.value))
    val state: StateFlow<PracticeUiState> = _state.asStateFlow()

    private var questionStartedAt = clock.nowMillis()
    private var pausedAt: Long? = null
    private var inBackground = false
    private var timerJob: Job? = null

    init {
        viewModelScope.launch {
            statStore.summary.collect { summary -> _state.update { it.copy(stats = summary) } }
        }
        viewModelScope.launch {
            combine(coffeeStore.adsRemoved, adsManager.isReady, adsManager.privacyOptionsRequired) { removed, ready, privacy ->
                Triple(removed, ready, privacy)
            }.collect { (removed, ready, privacy) ->
                _state.update {
                    it.copy(
                        adsRemoved = removed,
                        bannerAllowed = ready && !removed,
                        bannerRequested = it.bannerRequested && !removed,
                        privacyOptionsAvailable = privacy && !removed,
                    )
                }
            }
        }
        startTimer()
    }

    fun answer(index: Int) {
        val current = _state.value
        val chosen = current.question.answers.getOrNull(index) ?: return
        if (current.menuExpanded) setMenuExpanded(false)
        val isCorrect = chosen.kana == current.question.kana
        if (current.revealCorrect) {
            if (isCorrect) {
                sound.playCorrect()
                nextQuestion()
            } else {
                sound.playIncorrect()
            }
            return
        }
        cancelTimer()
        val costSeconds = (clock.nowMillis() - questionStartedAt) / 1000.0
        statStore.recordStreak(isCorrect)
        statStore.recordAnswer(costSeconds)
        if (isCorrect) {
            sound.playCorrect()
            nextQuestion()
        } else {
            sound.playIncorrect()
            reveal()
        }
    }

    fun toggleMenu() = setMenuExpanded(!_state.value.menuExpanded)

    fun openChart() = setSheet(Sheet.CHART)

    fun openCoffee() = setSheet(Sheet.COFFEE)

    fun closeSheet() = setSheet(null)

    fun setInBackground(background: Boolean) {
        inBackground = background
        refreshPause()
    }

    fun bannerFailed() {
        _state.update { it.copy(bannerRequested = false) }
    }

    private fun onTimeout() {
        statStore.recordStreak(false)
        sound.playIncorrect()
        reveal()
    }

    private fun reveal() {
        _state.update { it.copy(revealCorrect = true, bannerRequested = true) }
    }

    private fun nextQuestion() {
        _state.update { it.copy(question = engine.next(), revealCorrect = false, bannerRequested = false) }
        questionStartedAt = clock.nowMillis()
        pausedAt = if (isPaused()) questionStartedAt else null
        startTimer()
    }

    private fun setMenuExpanded(expanded: Boolean) {
        _state.update { it.copy(menuExpanded = expanded) }
        refreshPause()
    }

    private fun setSheet(sheet: Sheet?) {
        _state.update { it.copy(sheet = sheet) }
        refreshPause()
    }

    private fun isPaused(): Boolean = _state.value.menuExpanded || _state.value.sheet != null || inBackground

    private fun refreshPause() {
        val paused = isPaused()
        val now = clock.nowMillis()
        val pauseStart = pausedAt
        if (paused && pauseStart == null) {
            pausedAt = now
            cancelTimer()
        } else if (!paused && pauseStart != null) {
            questionStartedAt += now - pauseStart
            pausedAt = null
            startTimer()
        }
    }

    private fun startTimer() {
        cancelTimer()
        if (pausedAt != null || _state.value.revealCorrect) return
        val remaining = timeLimitMillis - (clock.nowMillis() - questionStartedAt)
        timerJob = viewModelScope.launch {
            delay(remaining.coerceAtLeast(1))
            onTimeout()
        }
    }

    private fun cancelTimer() {
        timerJob?.cancel()
        timerJob = null
    }

    companion object {
        fun factory(container: AppContainer): ViewModelProvider.Factory = viewModelFactory {
            initializer {
                PracticeViewModel(
                    engine = QuestionEngine(container.random),
                    statStore = container.statStore,
                    sound = container.soundPlayer,
                    clock = container.clock,
                    coffeeStore = container.coffeeStore,
                    adsManager = container.adsManager,
                    timeLimitMillis = container.timeLimitMillis,
                )
            }
        }
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `./gradlew :app:testDebugUnitTest --tests 'jp.jacky.kana.practice.PracticeViewModelTest'`
Expected: 12 tests passed。

- [ ] **Step 5: Commit**

```bash
git add source/android/app/src
git commit -m "Add the practice view model"
```

---

### Task 9: 咖啡 ViewModel

**Files:**
- Create: `app/src/main/kotlin/jp/jacky/kana/coffee/CoffeeViewModel.kt`
- Test: `app/src/test/kotlin/jp/jacky/kana/coffee/CoffeeViewModelTest.kt`

**Interfaces:**
- Consumes: `CoffeeStore`、`PurchaseOutcome`、`StoreException`、`FakeCoffeeStore`。
- Produces:

```kotlin
sealed interface CoffeeAlert { data object RestoreNone : CoffeeAlert; data class Failed(val detail: String?) : CoffeeAlert }
enum class CoffeeOperation { PURCHASE, RESTORE }
data class CoffeeUiState(val purchased: Boolean = false, val price: String? = null, val loading: Boolean = false,
    val operation: CoffeeOperation? = null, val pending: Boolean = false, val alert: CoffeeAlert? = null) { val busy: Boolean }
class CoffeeViewModel(store: CoffeeStore) : ViewModel() {
    val state: StateFlow<CoffeeUiState>
    fun loadProduct(); fun purchase(activity: Activity); fun restore(); fun dismissAlert()
    companion object { fun factory(store: CoffeeStore): ViewModelProvider.Factory }
}
```

- [ ] **Step 1: 写失败测试**

```kotlin
package jp.jacky.kana.coffee

import android.app.Activity
import jp.jacky.kana.store.PurchaseOutcome
import jp.jacky.kana.store.StoreException
import jp.jacky.kana.testing.FakeCoffeeStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class CoffeeViewModelTest {
    private val dispatcher = StandardTestDispatcher()
    private val activity = Activity()

    @Before
    fun setUp() = Dispatchers.setMain(dispatcher)

    @After
    fun tearDown() = Dispatchers.resetMain()

    @Test
    fun `loads the price on creation`() = runTest(dispatcher) {
        val store = FakeCoffeeStore()
        val vm = CoffeeViewModel(store)
        runCurrent()
        assertFalse(vm.state.value.loading)
        assertEquals("¥300", vm.state.value.price)
        assertEquals(1, store.loadCount)
    }

    @Test
    fun `does not load when already purchased`() = runTest(dispatcher) {
        val store = FakeCoffeeStore(initialAdsRemoved = true)
        val vm = CoffeeViewModel(store)
        runCurrent()
        assertTrue(vm.state.value.purchased)
        assertEquals(0, store.loadCount)
    }

    @Test
    fun `purchase completes and shows the thank you state`() = runTest(dispatcher) {
        val store = FakeCoffeeStore()
        val vm = CoffeeViewModel(store)
        runCurrent()
        vm.purchase(activity)
        runCurrent()
        assertNull(vm.state.value.operation)
        assertTrue(vm.state.value.purchased)
    }

    @Test
    fun `pending purchase keeps the offer with a pending note`() = runTest(dispatcher) {
        val store = FakeCoffeeStore().apply { purchaseOutcome = PurchaseOutcome.PENDING }
        val vm = CoffeeViewModel(store)
        runCurrent()
        vm.purchase(activity)
        runCurrent()
        assertTrue(vm.state.value.pending)
        assertFalse(vm.state.value.purchased)
        // A second tap while pending does nothing.
        vm.purchase(activity)
        assertNull(vm.state.value.operation)
    }

    @Test
    fun `purchase without a price reloads instead of purchasing`() = runTest(dispatcher) {
        val store = FakeCoffeeStore(productPrice = null)
        val vm = CoffeeViewModel(store)
        runCurrent()
        assertNull(vm.state.value.price)
        vm.purchase(activity)
        runCurrent()
        assertEquals(2, store.loadCount)
        assertFalse(vm.state.value.purchased)
    }

    @Test
    fun `restore without a purchase shows the nothing to restore alert`() = runTest(dispatcher) {
        val store = FakeCoffeeStore()
        val vm = CoffeeViewModel(store)
        runCurrent()
        vm.restore()
        runCurrent()
        assertEquals(CoffeeAlert.RestoreNone, vm.state.value.alert)
        vm.dismissAlert()
        runCurrent()
        assertNull(vm.state.value.alert)
    }

    @Test
    fun `restore with a purchase removes ads`() = runTest(dispatcher) {
        val store = FakeCoffeeStore().apply { restoreResult = true }
        val vm = CoffeeViewModel(store)
        runCurrent()
        vm.restore()
        runCurrent()
        assertTrue(vm.state.value.purchased)
        assertNull(vm.state.value.alert)
    }

    @Test
    fun `billing errors show the failure alert`() = runTest(dispatcher) {
        val store = FakeCoffeeStore().apply { purchaseError = StoreException.Billing(3, "unavailable") }
        val vm = CoffeeViewModel(store)
        runCurrent()
        vm.purchase(activity)
        runCurrent()
        assertEquals(CoffeeAlert.Failed("Billing error 3: unavailable"), vm.state.value.alert)
        assertNull(vm.state.value.operation)
    }

    @Test
    fun `unavailable product shows the failure alert without detail`() = runTest(dispatcher) {
        val store = FakeCoffeeStore().apply { purchaseError = StoreException.ProductUnavailable() }
        val vm = CoffeeViewModel(store)
        runCurrent()
        vm.purchase(activity)
        runCurrent()
        assertEquals(CoffeeAlert.Failed(null), vm.state.value.alert)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `./gradlew :app:testDebugUnitTest --tests 'jp.jacky.kana.coffee.CoffeeViewModelTest'`
Expected: 编译失败，`Unresolved reference: CoffeeViewModel`。

- [ ] **Step 3: 实现**

```kotlin
package jp.jacky.kana.coffee

import android.app.Activity
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import jp.jacky.kana.store.CoffeeStore
import jp.jacky.kana.store.PurchaseOutcome
import jp.jacky.kana.store.StoreException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

sealed interface CoffeeAlert {
    data object RestoreNone : CoffeeAlert
    /** detail null means the product is unavailable. */
    data class Failed(val detail: String?) : CoffeeAlert
}

enum class CoffeeOperation { PURCHASE, RESTORE }

data class CoffeeUiState(
    val purchased: Boolean = false,
    val price: String? = null,
    val loading: Boolean = false,
    val operation: CoffeeOperation? = null,
    val pending: Boolean = false,
    val alert: CoffeeAlert? = null,
) {
    val busy: Boolean get() = operation != null
}

class CoffeeViewModel(private val store: CoffeeStore) : ViewModel() {

    private data class Local(
        val loading: Boolean = false,
        val operation: CoffeeOperation? = null,
        val pending: Boolean = false,
        val alert: CoffeeAlert? = null,
    )

    private val local = MutableStateFlow(Local())

    val state: StateFlow<CoffeeUiState> = combine(store.adsRemoved, store.price, local) { purchased, price, local ->
        CoffeeUiState(
            purchased = purchased,
            price = price,
            loading = local.loading,
            operation = local.operation,
            pending = local.pending && !purchased,
            alert = local.alert,
        )
    }.stateIn(viewModelScope, SharingStarted.Eagerly, CoffeeUiState(purchased = store.adsRemoved.value, price = store.price.value))

    init {
        if (!store.adsRemoved.value && store.price.value == null) loadProduct()
    }

    fun loadProduct() {
        if (local.value.loading) return
        local.update { it.copy(loading = true) }
        viewModelScope.launch {
            store.loadProduct()
            local.update { it.copy(loading = false) }
        }
    }

    fun purchase(activity: Activity) {
        val current = state.value
        if (current.busy || current.purchased || current.loading || current.pending) return
        if (current.price == null) {
            loadProduct()
            return
        }
        perform(CoffeeOperation.PURCHASE) {
            val outcome = store.purchase(activity)
            local.update { it.copy(pending = outcome == PurchaseOutcome.PENDING) }
        }
    }

    fun restore() {
        if (state.value.busy) return
        perform(CoffeeOperation.RESTORE) {
            if (!store.restore()) local.update { it.copy(alert = CoffeeAlert.RestoreNone) }
        }
    }

    fun dismissAlert() = local.update { it.copy(alert = null) }

    private fun perform(operation: CoffeeOperation, block: suspend () -> Unit) {
        local.update { it.copy(operation = operation) }
        viewModelScope.launch {
            try {
                block()
            } catch (e: StoreException.ProductUnavailable) {
                local.update { it.copy(alert = CoffeeAlert.Failed(null)) }
            } catch (e: StoreException) {
                local.update { it.copy(alert = CoffeeAlert.Failed(e.message)) }
            }
            local.update { it.copy(operation = null) }
        }
    }

    companion object {
        fun factory(store: CoffeeStore): ViewModelProvider.Factory = viewModelFactory {
            initializer { CoffeeViewModel(store) }
        }
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `./gradlew :app:testDebugUnitTest --tests 'jp.jacky.kana.coffee.CoffeeViewModelTest'`
Expected: 9 tests passed。

- [ ] **Step 5: Commit**

```bash
git add source/android/app/src
git commit -m "Add the coffee view model"
```

---

### Task 10: Android 服务实现与默认容器

**Files:**
- Create: `app/src/main/kotlin/jp/jacky/kana/ads/GoogleAdsManager.kt`
- Create: `app/src/main/kotlin/jp/jacky/kana/ads/BannerAd.kt`
- Create: `app/src/main/kotlin/jp/jacky/kana/sound/SoundPoolPlayer.kt`
- Create: `app/src/main/kotlin/jp/jacky/kana/share/AndroidShareActions.kt`
- Create: `app/src/main/kotlin/jp/jacky/kana/di/DefaultAppContainer.kt`
- Modify: `app/src/main/kotlin/jp/jacky/kana/KanaApplication.kt`

**Interfaces:**
- Consumes: Task 6 接口，Task 7 `PlayCoffeeStore` / `PlayBillingGateway` / `PrefsAdsRemovedStorage`，`BuildConfig`。
- Produces: `GoogleAdsManager(app: Application, scope: CoroutineScope, debugGeographyEea: Boolean)`；`@Composable fun BannerAd(adUnitId: String, onFailed: () -> Unit, modifier: Modifier = Modifier)`；`SoundPoolPlayer(context)`；`AndroidShareActions(context)`；`DefaultAppContainer(app)`；`KanaApplication.container: AppContainer`（`protected set`）与 `protected open fun createContainer(): AppContainer`。

- [ ] **Step 1: GoogleAdsManager**

```kotlin
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
```

- [ ] **Step 2: BannerAd composable**

```kotlin
package jp.jacky.kana.ads

import androidx.activity.compose.LocalActivity
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalWindowInfo
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.google.android.gms.ads.AdListener
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdSize
import com.google.android.gms.ads.AdView
import com.google.android.gms.ads.LoadAdError

/**
 * An anchored adaptive banner that loads when it enters composition and is destroyed when it
 * leaves. The practice screen shows it only after a wrong answer.
 */
@Composable
fun BannerAd(adUnitId: String, onFailed: () -> Unit, modifier: Modifier = Modifier) {
    val activity = LocalActivity.current ?: return
    val density = LocalDensity.current
    val widthDp = with(density) { LocalWindowInfo.current.containerSize.width.toDp() }.value.toInt()
    val currentOnFailed by rememberUpdatedState(onFailed)

    // The standard anchored size matches the iOS banner height (50 to 90 dp); the "large" variant
    // introduced in SDK 25 may take up to 20 % of the screen.
    @Suppress("DEPRECATION")
    val adSize = remember(widthDp) { AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(activity, widthDp) }

    val adView = remember(adSize) {
        AdView(activity).apply {
            this.adUnitId = adUnitId
            setAdSize(adSize)
            adListener = object : AdListener() {
                override fun onAdFailedToLoad(error: LoadAdError) {
                    currentOnFailed()
                }
            }
        }
    }

    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(adView, lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_PAUSE -> adView.pause()
                Lifecycle.Event.ON_RESUME -> adView.resume()
                else -> Unit
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        adView.loadAd(AdRequest.Builder().build())
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
            adView.destroy()
        }
    }

    AndroidView(
        factory = { adView },
        modifier = modifier.fillMaxWidth().height(adSize.height.dp),
    )
}
```

- [ ] **Step 3: SoundPoolPlayer 与 AndroidShareActions**

`sound/SoundPoolPlayer.kt`：

```kotlin
package jp.jacky.kana.sound

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import jp.jacky.kana.R

/** Plays the two short effects without taking audio focus, so other audio keeps playing. */
class SoundPoolPlayer(context: Context) : SoundPlayer {
    private val pool = SoundPool.Builder()
        .setMaxStreams(2)
        .setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
        )
        .build()
    private val correct = pool.load(context, R.raw.correct, 1)
    private val incorrect = pool.load(context, R.raw.incorrect, 1)

    override fun playCorrect() {
        pool.play(correct, 1f, 1f, 1, 0, 1f)
    }

    override fun playIncorrect() {
        pool.play(incorrect, 1f, 1f, 1, 0, 1f)
    }
}
```

`share/AndroidShareActions.kt`：

```kotlin
package jp.jacky.kana.share

import android.app.Activity
import android.content.Context
import android.content.Intent
import androidx.core.net.toUri
import jp.jacky.kana.R

class AndroidShareActions(private val context: Context) : ShareActions {

    override fun share(activity: Activity) {
        val text = context.getString(R.string.intro_text) + "\n" + PLAY_URL
        val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
        activity.startActivity(Intent.createChooser(send, context.getString(R.string.share)))
    }

    override fun canSendFeedback(): Boolean = feedbackIntent().resolveActivity(context.packageManager) != null

    override fun sendFeedback(activity: Activity) {
        runCatching { activity.startActivity(feedbackIntent()) }
    }

    private fun feedbackIntent(): Intent = Intent(Intent.ACTION_SENDTO, "mailto:$FEEDBACK_EMAIL".toUri())
        .putExtra(Intent.EXTRA_SUBJECT, context.getString(R.string.feedback))

    companion object {
        const val PLAY_URL = "https://play.google.com/store/apps/details?id=jp.jacky.kana"
        const val FEEDBACK_EMAIL = "newbdez33+kana.feedback@gmail.com"
    }
}
```

- [ ] **Step 4: DefaultAppContainer 与 KanaApplication**

`di/DefaultAppContainer.kt`：

```kotlin
package jp.jacky.kana.di

import android.app.Application
import android.os.SystemClock
import jp.jacky.kana.BuildConfig
import jp.jacky.kana.ads.AdsManager
import jp.jacky.kana.ads.GoogleAdsManager
import jp.jacky.kana.practice.Clock
import jp.jacky.kana.share.AndroidShareActions
import jp.jacky.kana.share.ShareActions
import jp.jacky.kana.sound.SoundPlayer
import jp.jacky.kana.sound.SoundPoolPlayer
import jp.jacky.kana.stats.StatStore
import jp.jacky.kana.store.CoffeeStore
import jp.jacky.kana.store.PlayBillingGateway
import jp.jacky.kana.store.PlayCoffeeStore
import jp.jacky.kana.store.PrefsAdsRemovedStorage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import java.io.File
import kotlin.random.Random

class DefaultAppContainer(app: Application) : AppContainer {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override val random: Random = Random.Default
    override val clock: Clock = Clock { SystemClock.elapsedRealtime() }
    override val timeLimitMillis: Long = 5_000L
    override val statStore: StatStore = StatStore(File(app.filesDir, "stats.json"))
    override val coffeeStore: CoffeeStore = PlayCoffeeStore(
        gateway = PlayBillingGateway(app, BuildConfig.COFFEE_PRODUCT_ID),
        storage = PrefsAdsRemovedStorage(app),
        scope = scope,
    ).also { it.start() }
    override val adsManager: AdsManager = GoogleAdsManager(app, scope, BuildConfig.ADS_DEBUG_GEOGRAPHY_EEA)
    override val soundPlayer: SoundPlayer = SoundPoolPlayer(app)
    override val shareActions: ShareActions = AndroidShareActions(app)
}
```

`KanaApplication.kt`（覆盖 Task 1 的版本）：

```kotlin
package jp.jacky.kana

import android.app.Application
import jp.jacky.kana.di.AppContainer
import jp.jacky.kana.di.DefaultAppContainer

open class KanaApplication : Application() {
    lateinit var container: AppContainer
        protected set

    override fun onCreate() {
        super.onCreate()
        container = createContainer()
    }

    protected open fun createContainer(): AppContainer = DefaultAppContainer(this)
}
```

- [ ] **Step 5: 编译**

Run: `./gradlew :app:assembleDebug :app:testDebugUnitTest`
Expected: `BUILD SUCCESSFUL`，之前的单元测试仍全部通过。若 `LocalWindowInfo.current.containerSize` 不可用，改用 `LocalConfiguration.current.screenWidthDp`。

- [ ] **Step 6: Commit**

```bash
git add source/android/app/src
git commit -m "Add Google ads, sound, share, and the default app container"
```

---

### Task 11: 主题、练习页、MainActivity、模拟器与 UI 测试基础

**Files:**
- Create: `app/src/main/kotlin/jp/jacky/kana/ui/theme/Theme.kt`
- Create: `app/src/main/kotlin/jp/jacky/kana/practice/PracticeScreen.kt`
- Create: `app/src/main/kotlin/jp/jacky/kana/KanaApp.kt`
- Modify: `app/src/main/kotlin/jp/jacky/kana/MainActivity.kt`
- Create: `app/src/androidTest/kotlin/jp/jacky/kana/KanaTestRunner.kt`、`TestKanaApplication.kt`、`FakeAppContainer.kt`
- Test: `app/src/androidTest/kotlin/jp/jacky/kana/practice/PracticeScreenTest.kt`

**Interfaces:**
- Consumes: `PracticeViewModel`、`PracticeUiState`、`BannerAd`、字符串资源、`BuildConfig.ADMOB_BANNER_ID`。
- Produces: `object KanaColors { accent, secondary, paper, keyRed, keyGray, ink, incorrect, divider }`；`object KanaFonts { hosohuwa: FontFamily }`；`@Composable fun KanaTheme(content)`；`@Composable fun PracticeScreen(...)`；`@Composable fun KanaApp(container, viewModel)`；测试 tag：`menuToggle, statTotal, statAverage, statRecent, statBest, questionLabel, answer0..answer3, chartMenu, coffeeMenu, moreMenu`；高亮的答案带 `stateDescription = "correct"`。Task 12/13 的 sheet 由 `KanaApp` 按 `state.sheet` 显示（本任务先留 `KanaChartSheet` / `CoffeeSheet` 的调用，用两个空实现占位，Task 12/13 替换）。

- [ ] **Step 1: 主题**

`ui/theme/Theme.kt`：

```kotlin
package jp.jacky.kana.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import jp.jacky.kana.R

/** Colors ported from UIColor+Kana.swift. The app is light only. */
object KanaColors {
    val accent = Color(0xFFC93332)
    val secondary = Color(0xFF6E6963)
    val paper = Color(0xFFFCFAF5)
    val keyRed = Color(0xFFD0141B)
    val keyGray = Color(0xFFF7F7F7)
    val ink = Color(0xFF171412)
    val incorrect = Color(0xFFF08F8F)
    val divider = ink.copy(alpha = 0.09f)
}

object KanaFonts {
    val hosohuwa = FontFamily(Font(R.font.hosohuwa))
}

private val LightColors = lightColorScheme(
    primary = KanaColors.accent,
    onPrimary = Color.White,
    background = KanaColors.keyGray,
    onBackground = KanaColors.ink,
    surface = KanaColors.paper,
    onSurface = KanaColors.ink,
    onSurfaceVariant = KanaColors.secondary,
    secondary = KanaColors.secondary,
)

@Composable
fun KanaTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = LightColors, content = content)
}
```

- [ ] **Step 2: 写失败的 UI 测试和测试基础设施**

`androidTest/.../KanaTestRunner.kt`：

```kotlin
package jp.jacky.kana

import android.app.Application
import android.content.Context
import androidx.test.runner.AndroidJUnitRunner

class KanaTestRunner : AndroidJUnitRunner() {
    override fun newApplication(cl: ClassLoader, className: String, context: Context): Application =
        super.newApplication(cl, TestKanaApplication::class.java.name, context)
}
```

`androidTest/.../TestKanaApplication.kt`：

```kotlin
package jp.jacky.kana

import androidx.test.core.app.ApplicationProvider
import jp.jacky.kana.di.AppContainer

class TestKanaApplication : KanaApplication() {
    override fun createContainer(): AppContainer = FakeAppContainer(this)

    /** Gives every test a fresh set of fakes. Call before launching the activity. */
    fun resetContainer(): FakeAppContainer = FakeAppContainer(this).also { container = it }

    companion object {
        fun get(): TestKanaApplication = ApplicationProvider.getApplicationContext()
    }
}
```

`androidTest/.../FakeAppContainer.kt`：

```kotlin
package jp.jacky.kana

import android.app.Application
import android.os.SystemClock
import jp.jacky.kana.di.AppContainer
import jp.jacky.kana.practice.Clock
import jp.jacky.kana.stats.StatStore
import jp.jacky.kana.testing.FakeAdsManager
import jp.jacky.kana.testing.FakeCoffeeStore
import jp.jacky.kana.testing.FakeShareActions
import jp.jacky.kana.testing.FakeSoundPlayer
import java.io.File
import kotlin.random.Random

class FakeAppContainer(app: Application, seed: Int = 42) : AppContainer {
    override val random: Random = Random(seed)
    override val clock: Clock = Clock { SystemClock.elapsedRealtime() }
    override val timeLimitMillis: Long = 60_000L
    override val statStore = StatStore(File(app.cacheDir, "test-stats-${System.nanoTime()}.json"), timeLimitSeconds = 60.0)
    override val coffeeStore = FakeCoffeeStore()
    override val adsManager = FakeAdsManager()
    override val soundPlayer = FakeSoundPlayer()
    override val shareActions = FakeShareActions()
}
```

`androidTest/.../practice/PracticeScreenTest.kt`：

```kotlin
package jp.jacky.kana.practice

import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.hasStateDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import jp.jacky.kana.MainActivity
import jp.jacky.kana.TestKanaApplication
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import kotlin.random.Random

@RunWith(AndroidJUnit4::class)
class PracticeScreenTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    private lateinit var scenario: ActivityScenario<MainActivity>
    private lateinit var expected: QuestionEngine

    @Before
    fun launch() {
        TestKanaApplication.get().resetContainer()
        expected = QuestionEngine(Random(42))
        scenario = ActivityScenario.launch(MainActivity::class.java)
    }

    @After
    fun close() = scenario.close()

    @Test
    fun showsTheFirstQuestionAndCountsACorrectAnswer() {
        val first = expected.next()
        compose.onNodeWithTag("questionLabel").assertTextEquals(first.prompt)
        (0..3).forEach { compose.onNodeWithTag("answer$it").assert(hasText(first.answers[it].label)) }
        compose.onNodeWithTag("answer${first.correctIndex}").performClick()
        val second = expected.next()
        compose.onNodeWithTag("questionLabel").assertTextEquals(second.prompt)
        compose.onNodeWithTag("statTotal").assert(hasText("1"))
        compose.onNodeWithTag("statBest").assert(hasText("1"))
    }

    @Test
    fun wrongAnswerHighlightsTheCorrectOne() {
        val first = expected.next()
        val wrong = (0..3).first { it != first.correctIndex }
        compose.onNodeWithTag("answer$wrong").performClick()
        compose.onNodeWithTag("questionLabel").assertTextEquals(first.prompt)
        compose.onNodeWithTag("answer${first.correctIndex}").assert(hasStateDescription("correct"))
        compose.onNodeWithTag("statBest").assert(hasText("0"))
    }

    @Test
    fun menuTogglesAndShowsTheActions() {
        compose.onNodeWithTag("chartMenu").assertDoesNotExist()
        compose.onNodeWithTag("menuToggle").performClick()
        compose.onNodeWithTag("chartMenu").assertIsDisplayed()
        compose.onNodeWithTag("coffeeMenu").assertIsDisplayed()
        compose.onNodeWithTag("moreMenu").assertIsDisplayed()
        compose.onNodeWithTag("menuToggle").performClick()
        compose.onNodeWithTag("chartMenu").assertDoesNotExist()
    }
}
```

- [ ] **Step 3: 创建并启动模拟器，运行测试确认失败**

```bash
avdmanager create avd -n kana_api_36 -k "system-images;android-36;google_apis;arm64-v8a" -d pixel_7 --force
$ANDROID_HOME/emulator/emulator -avd kana_api_36 -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect &
adb wait-for-device shell 'while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 2; done; echo booted'
```

Run: `./gradlew :app:connectedDebugAndroidTest`
Expected: 编译失败（`PracticeScreen` / tag 不存在），或测试因找不到 `questionLabel` 失败。

- [ ] **Step 4: 练习页**

`practice/PracticeScreen.kt`：

```kotlin
package jp.jacky.kana.practice

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.GridView
import androidx.compose.material.icons.outlined.KeyboardArrowUp
import androidx.compose.material.icons.outlined.LocalCafe
import androidx.compose.material.icons.outlined.MailOutline
import androidx.compose.material.icons.outlined.Menu
import androidx.compose.material.icons.outlined.MoreHoriz
import androidx.compose.material.icons.outlined.PrivacyTip
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import jp.jacky.kana.R
import jp.jacky.kana.ads.BannerAd
import jp.jacky.kana.stats.StatSummary
import jp.jacky.kana.ui.theme.KanaColors
import jp.jacky.kana.ui.theme.KanaFonts
import java.text.NumberFormat

private val ContentMaxWidth = 560.dp

@Composable
fun PracticeScreen(
    state: PracticeUiState,
    bannerAdUnitId: String,
    canSendFeedback: Boolean,
    onAnswer: (Int) -> Unit,
    onToggleMenu: () -> Unit,
    onOpenChart: () -> Unit,
    onOpenCoffee: () -> Unit,
    onShare: () -> Unit,
    onFeedback: () -> Unit,
    onPrivacyOptions: () -> Unit,
    onBannerFailed: () -> Unit,
) {
    Column(
        Modifier
            .fillMaxSize()
            .background(KanaColors.keyGray)
            .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.Horizontal))
    ) {
        AnimatedVisibility(visible = state.menuExpanded) {
            MenuRow(
                adsRemoved = state.adsRemoved,
                privacyOptionsAvailable = state.privacyOptionsAvailable,
                canSendFeedback = canSendFeedback,
                onOpenChart = onOpenChart,
                onOpenCoffee = onOpenCoffee,
                onShare = onShare,
                onFeedback = onFeedback,
                onPrivacyOptions = onPrivacyOptions,
            )
        }
        StatisticsBar(stats = state.stats, menuExpanded = state.menuExpanded, onToggleMenu = onToggleMenu)
        Column(Modifier.weight(1f).fillMaxWidth()) {
            QuestionArea(prompt = state.question.prompt, modifier = Modifier.weight(1f))
            if (state.showBanner) {
                BannerAd(adUnitId = bannerAdUnitId, onFailed = onBannerFailed, modifier = Modifier.padding(bottom = 5.dp))
            }
        }
        AnswerGrid(
            question = state.question,
            revealCorrect = state.revealCorrect,
            onAnswer = onAnswer,
            modifier = Modifier.weight(1f).windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Bottom)),
        )
    }
}

@Composable
private fun MenuRow(
    adsRemoved: Boolean,
    privacyOptionsAvailable: Boolean,
    canSendFeedback: Boolean,
    onOpenChart: () -> Unit,
    onOpenCoffee: () -> Unit,
    onShare: () -> Unit,
    onFeedback: () -> Unit,
    onPrivacyOptions: () -> Unit,
) {
    Box(Modifier.fillMaxWidth().height(80.dp), contentAlignment = Alignment.BottomCenter) {
        Row(
            Modifier.widthIn(max = ContentMaxWidth).fillMaxWidth().padding(horizontal = 20.dp).padding(bottom = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            TextButton(onClick = onOpenChart, modifier = Modifier.heightIn(min = 44.dp).testTag("chartMenu")) {
                Icon(Icons.Outlined.GridView, contentDescription = null, tint = KanaColors.ink)
                Spacer(Modifier.width(8.dp))
                Text(stringResource(R.string.chart), color = KanaColors.ink, fontSize = 14.sp, fontWeight = FontWeight.Medium)
            }
            Spacer(Modifier.weight(1f))
            TextButton(onClick = onOpenCoffee, modifier = Modifier.heightIn(min = 44.dp).testTag("coffeeMenu")) {
                Icon(
                    if (adsRemoved) Icons.Outlined.FavoriteBorder else Icons.Outlined.LocalCafe,
                    contentDescription = null,
                    tint = KanaColors.accent,
                )
                Spacer(Modifier.width(8.dp))
                Text(stringResource(R.string.support), color = KanaColors.accent, fontSize = 14.sp, fontWeight = FontWeight.Medium)
            }
            Box {
                var expanded by remember { mutableStateOf(false) }
                IconButton(onClick = { expanded = true }, modifier = Modifier.size(44.dp).testTag("moreMenu")) {
                    Icon(Icons.Outlined.MoreHoriz, contentDescription = stringResource(R.string.more), tint = KanaColors.secondary)
                }
                DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.share)) },
                        leadingIcon = { Icon(Icons.Outlined.Share, contentDescription = null) },
                        onClick = { expanded = false; onShare() },
                    )
                    if (canSendFeedback) {
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.feedback)) },
                            leadingIcon = { Icon(Icons.Outlined.MailOutline, contentDescription = null) },
                            onClick = { expanded = false; onFeedback() },
                        )
                    }
                    if (privacyOptionsAvailable) {
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.ad_privacy)) },
                            leadingIcon = { Icon(Icons.Outlined.PrivacyTip, contentDescription = null) },
                            onClick = { expanded = false; onPrivacyOptions() },
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun StatisticsBar(stats: StatSummary, menuExpanded: Boolean, onToggleMenu: () -> Unit) {
    Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
        Column(Modifier.widthIn(max = ContentMaxWidth).fillMaxWidth().padding(horizontal = 20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    stringResource(R.string.practice).uppercase(),
                    color = KanaColors.secondary,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(Modifier.weight(1f))
                IconButton(onClick = onToggleMenu, modifier = Modifier.size(44.dp).testTag("menuToggle")) {
                    Icon(
                        if (menuExpanded) Icons.Outlined.KeyboardArrowUp else Icons.Outlined.Menu,
                        contentDescription = stringResource(if (menuExpanded) R.string.close_menu else R.string.menu),
                        tint = KanaColors.ink,
                    )
                }
            }
            Spacer(Modifier.height(8.dp))
            val hasAnswers = stats.totalCount > 0
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.Top) {
                Metric(
                    value = AnnotatedString(NumberFormat.getIntegerInstance().format(stats.totalCount)),
                    caption = stringResource(R.string.stat_answers),
                    tag = "statTotal",
                    modifier = Modifier.weight(1f),
                )
                Metric(
                    value = secondsText(stats.averageSeconds, hasAnswers),
                    caption = stringResource(R.string.stat_average),
                    tag = "statAverage",
                    modifier = Modifier.weight(1f),
                )
                Metric(
                    value = secondsText(stats.recentSeconds, hasAnswers),
                    caption = stringResource(R.string.stat_recent, StatSummary.RECENT_LIMIT),
                    tag = "statRecent",
                    modifier = Modifier.weight(1f),
                )
                Metric(
                    value = AnnotatedString(NumberFormat.getIntegerInstance().format(stats.bestStreak)),
                    caption = stringResource(R.string.stat_best),
                    tag = "statBest",
                    accent = true,
                    modifier = Modifier.weight(1f),
                )
            }
            Spacer(Modifier.height(20.dp))
            HorizontalDivider(color = KanaColors.divider, thickness = 1.dp)
        }
    }
}

@Composable
private fun secondsText(value: Double?, hasAnswers: Boolean): AnnotatedString {
    if (!hasAnswers || value == null) return AnnotatedString("—")
    val number = NumberFormat.getNumberInstance().apply {
        minimumFractionDigits = 2
        maximumFractionDigits = 2
    }.format(value)
    val text = stringResource(R.string.stat_seconds, number)
    val start = text.indexOf(number)
    return buildAnnotatedString {
        append(text)
        addStyle(SpanStyle(fontSize = 12.sp, color = KanaColors.secondary), 0, text.length)
        if (start >= 0) addStyle(SpanStyle(fontSize = 25.sp, color = KanaColors.ink), start, start + number.length)
    }
}

@Composable
private fun Metric(value: AnnotatedString, caption: String, tag: String, modifier: Modifier = Modifier, accent: Boolean = false) {
    Column(modifier.semantics(mergeDescendants = true) {}.testTag(tag)) {
        BasicText(
            text = value,
            style = TextStyle(
                fontSize = 25.sp,
                fontWeight = FontWeight.Medium,
                color = if (accent) KanaColors.accent else KanaColors.ink,
                fontFamily = FontFamily.Default,
            ),
            maxLines = 1,
            autoSize = TextAutoSize.StepBased(minFontSize = 15.sp, maxFontSize = 25.sp, stepSize = 1.sp),
        )
        Spacer(Modifier.height(5.dp))
        Text(caption, color = KanaColors.secondary, fontSize = 11.sp, fontWeight = FontWeight.Medium, maxLines = 2)
    }
}

@Composable
private fun QuestionArea(prompt: String, modifier: Modifier = Modifier) {
    BoxWithConstraints(modifier.fillMaxWidth().background(KanaColors.keyGray), contentAlignment = Alignment.Center) {
        val maxFont = with(LocalDensity.current) { 155.dp.toSp() }
        BasicText(
            text = prompt,
            modifier = Modifier.widthIn(max = 240.dp).heightIn(max = maxHeight * 0.85f).testTag("questionLabel"),
            style = TextStyle(fontFamily = KanaFonts.hosohuwa, color = KanaColors.ink, textAlign = TextAlign.Center),
            maxLines = 1,
            autoSize = TextAutoSize.StepBased(minFontSize = 40.sp, maxFontSize = maxFont, stepSize = 4.sp),
        )
    }
}

@Composable
private fun AnswerGrid(question: Question, revealCorrect: Boolean, onAnswer: (Int) -> Unit, modifier: Modifier = Modifier) {
    val maxFont = with(LocalDensity.current) { 80.dp.toSp() }
    Column(modifier.fillMaxWidth().background(Color.White)) {
        for (row in 0 until 2) {
            Row(Modifier.weight(1f).fillMaxWidth()) {
                for (column in 0 until 2) {
                    val index = row * 2 + column
                    val highlight = revealCorrect && index == question.correctIndex
                    Box(
                        Modifier
                            .weight(1f)
                            .fillMaxHeight()
                            .background(if (highlight) KanaColors.incorrect else Color.Transparent)
                            .clickable { onAnswer(index) }
                            .semantics { if (highlight) stateDescription = "correct" }
                            .testTag("answer$index"),
                        contentAlignment = Alignment.Center,
                    ) {
                        BasicText(
                            text = question.answers[index].label,
                            style = TextStyle(
                                fontFamily = KanaFonts.hosohuwa,
                                color = if (highlight) Color.White else KanaColors.ink,
                                textAlign = TextAlign.Center,
                            ),
                            maxLines = 1,
                            autoSize = TextAutoSize.StepBased(minFontSize = 24.sp, maxFontSize = maxFont, stepSize = 2.sp),
                        )
                    }
                    if (column == 0) VerticalDivider(color = KanaColors.keyGray, thickness = 1.dp)
                }
            }
            if (row == 0) HorizontalDivider(color = KanaColors.keyGray, thickness = 1.dp)
        }
    }
}
```

- [ ] **Step 5: KanaApp 与 MainActivity（sheet 先占位）**

`KanaApp.kt`：

```kotlin
package jp.jacky.kana

import androidx.activity.compose.LocalActivity
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import jp.jacky.kana.chart.KanaChartSheet
import jp.jacky.kana.coffee.CoffeeSheet
import jp.jacky.kana.coffee.CoffeeViewModel
import jp.jacky.kana.di.AppContainer
import jp.jacky.kana.practice.PracticeScreen
import jp.jacky.kana.practice.PracticeViewModel
import jp.jacky.kana.practice.Sheet

@Composable
fun KanaApp(container: AppContainer, viewModel: PracticeViewModel) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val activity = LocalActivity.current

    PracticeScreen(
        state = state,
        bannerAdUnitId = BuildConfig.ADMOB_BANNER_ID,
        canSendFeedback = container.shareActions.canSendFeedback(),
        onAnswer = viewModel::answer,
        onToggleMenu = viewModel::toggleMenu,
        onOpenChart = viewModel::openChart,
        onOpenCoffee = viewModel::openCoffee,
        onShare = { activity?.let(container.shareActions::share) },
        onFeedback = { activity?.let(container.shareActions::sendFeedback) },
        onPrivacyOptions = { activity?.let(container.adsManager::showPrivacyOptions) },
        onBannerFailed = viewModel::bannerFailed,
    )

    when (state.sheet) {
        Sheet.CHART -> KanaChartSheet(onDismiss = viewModel::closeSheet)
        Sheet.COFFEE -> {
            val coffeeViewModel: CoffeeViewModel = viewModel(factory = CoffeeViewModel.factory(container.coffeeStore))
            CoffeeSheet(viewModel = coffeeViewModel, onDismiss = viewModel::closeSheet)
        }
        null -> Unit
    }
}
```

占位（Task 12 / 13 会替换成真实实现）：

`chart/KanaChartSheet.kt`：

```kotlin
package jp.jacky.kana.chart

import androidx.compose.runtime.Composable

@Composable
fun KanaChartSheet(onDismiss: () -> Unit) {
    // Implemented in Task 12.
}
```

`coffee/CoffeeSheet.kt`：

```kotlin
package jp.jacky.kana.coffee

import androidx.compose.runtime.Composable

@Composable
fun CoffeeSheet(viewModel: CoffeeViewModel, onDismiss: () -> Unit) {
    // Implemented in Task 13.
}
```

`MainActivity.kt`（覆盖）：

```kotlin
package jp.jacky.kana

import android.graphics.Color
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import jp.jacky.kana.practice.PracticeViewModel
import jp.jacky.kana.ui.theme.KanaTheme

class MainActivity : ComponentActivity() {

    private val container get() = (application as KanaApplication).container
    private val practiceViewModel: PracticeViewModel by viewModels { PracticeViewModel.factory(container) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT),
        )
        setContent {
            KanaTheme { KanaApp(container = container, viewModel = practiceViewModel) }
        }
    }

    override fun onStart() {
        super.onStart()
        practiceViewModel.setInBackground(false)
        if (!container.coffeeStore.adsRemoved.value) container.adsManager.gatherConsent(this)
    }

    override fun onStop() {
        super.onStop()
        practiceViewModel.setInBackground(true)
    }
}
```

- [ ] **Step 6: 运行 UI 测试确认通过**

Run: `./gradlew :app:connectedDebugAndroidTest`
Expected: `BUILD SUCCESSFUL`，3 tests passed（报告 `app/build/reports/androidTests/connected/debug/index.html`）。若 `assertTextEquals` 对 `questionLabel` 失败，改用 `assert(hasText(first.prompt))`。

- [ ] **Step 7: 手动看一眼**

```bash
adb shell am start -n jp.jacky.kana/.MainActivity && sleep 3 && adb exec-out screencap -p > /tmp/kana-practice.png
```
用 Read 工具查看截图：浅灰底、统计栏四列、手写题目、白底 2×2 答案。答错一次后再截图，应看到粉红高亮和 Google 测试横幅（模拟器有网络时）。

- [ ] **Step 8: Commit**

```bash
git add source/android/app/src
git commit -m "Add the practice screen, main activity, and instrumented test setup"
```

---

### Task 12: 五十音图

**Files:**
- Modify: `app/src/main/kotlin/jp/jacky/kana/chart/KanaChartSheet.kt`（替换占位）
- Test: `app/src/androidTest/kotlin/jp/jacky/kana/chart/KanaChartSheetTest.kt`

**Interfaces:**
- Consumes: `KanaTable.rows`、`KanaForm`、`KanaColors`、`KanaFonts`。
- Produces: `@Composable fun KanaChartSheet(onDismiss: () -> Unit)`；tag `kanaChart`、`chartHiragana`、`chartKatakana`。

- [ ] **Step 1: 写失败测试**

```kotlin
package jp.jacky.kana.chart

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import jp.jacky.kana.MainActivity
import jp.jacky.kana.TestKanaApplication
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class KanaChartSheetTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    private lateinit var scenario: ActivityScenario<MainActivity>

    @Before
    fun launch() {
        TestKanaApplication.get().resetContainer()
        scenario = ActivityScenario.launch(MainActivity::class.java)
    }

    @After
    fun close() = scenario.close()

    @Test
    fun opensTheChartAndSwitchesToKatakana() {
        compose.onNodeWithTag("menuToggle").performClick()
        compose.onNodeWithTag("chartMenu").performClick()
        compose.onNodeWithTag("kanaChart").assertIsDisplayed()
        compose.onNodeWithText("か").assertIsDisplayed()
        compose.onNodeWithText("ka").assertIsDisplayed()
        compose.onNodeWithText("カ").assertDoesNotExist()
        compose.onNodeWithTag("chartKatakana").performClick()
        compose.onNodeWithText("カ").assertIsDisplayed()
        compose.onNodeWithText("か").assertDoesNotExist()
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `./gradlew :app:connectedDebugAndroidTest --tests 'jp.jacky.kana.chart.KanaChartSheetTest'`
Expected: 失败于 `kanaChart` 不存在。

- [ ] **Step 3: 实现**

```kotlin
package jp.jacky.kana.chart

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsBottomHeight
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import jp.jacky.kana.practice.Kana
import jp.jacky.kana.practice.KanaForm
import jp.jacky.kana.practice.KanaTable
import jp.jacky.kana.ui.theme.KanaColors
import jp.jacky.kana.ui.theme.KanaFonts

/** The gojūon chart as a full-height sheet; swipe down or press back to close. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun KanaChartSheet(onDismiss: () -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var form by rememberSaveable { mutableStateOf(KanaForm.HIRAGANA) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = Color.White,
        modifier = Modifier.testTag("kanaChart"),
    ) {
        LazyColumn(Modifier.fillMaxWidth().fillMaxHeight()) {
            item { ChartHeader(selected = form, onSelect = { form = it }) }
            itemsIndexed(KanaTable.rows) { index, row ->
                ChartRow(row = row, form = form, background = if (index % 2 == 0) Color.White else KanaColors.keyGray)
            }
            item { Spacer(Modifier.windowInsetsBottomHeight(WindowInsets.navigationBars)) }
        }
    }
}

@Composable
private fun ChartHeader(selected: KanaForm, onSelect: (KanaForm) -> Unit) {
    Row(
        Modifier.fillMaxWidth().height(140.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        FormButton(label = "あ", selected = selected == KanaForm.HIRAGANA, tag = "chartHiragana") { onSelect(KanaForm.HIRAGANA) }
        FormButton(label = "ア", selected = selected == KanaForm.KATAKANA, tag = "chartKatakana") { onSelect(KanaForm.KATAKANA) }
    }
}

@Composable
private fun FormButton(label: String, selected: Boolean, tag: String, onClick: () -> Unit) {
    val fontSize = with(LocalDensity.current) { 30.dp.toSp() }
    Box(
        Modifier
            .size(64.dp)
            .clip(CircleShape)
            .background(if (selected) KanaColors.keyRed else KanaColors.ink)
            .clickable(onClick = onClick)
            .testTag(tag),
        contentAlignment = Alignment.Center,
    ) {
        BasicText(label, style = TextStyle(fontFamily = KanaFonts.hosohuwa, fontSize = fontSize, color = Color.White))
    }
}

@Composable
private fun ChartRow(row: List<Kana?>, form: KanaForm, background: Color) {
    Row(Modifier.fillMaxWidth().background(background).padding(horizontal = 10.dp, vertical = 10.dp)) {
        for (column in 0 until 5) {
            val kana = row.getOrNull(column)
            Box(Modifier.weight(1f).height(60.dp), contentAlignment = Alignment.Center) {
                if (kana != null) ChartCell(kana, form)
            }
        }
    }
}

@Composable
private fun ChartCell(kana: Kana, form: KanaForm) {
    val density = LocalDensity.current
    val kanaSize = with(density) { 32.dp.toSp() }
    val romajiSize = with(density) { 18.dp.toSp() }
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        BasicText(
            kana.text(form),
            style = TextStyle(fontFamily = KanaFonts.hosohuwa, fontSize = kanaSize, color = KanaColors.ink, textAlign = TextAlign.Center),
        )
        BasicText(
            kana.romaji,
            style = TextStyle(fontFamily = KanaFonts.hosohuwa, fontSize = romajiSize, color = KanaColors.secondary, textAlign = TextAlign.Center),
        )
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `./gradlew :app:connectedDebugAndroidTest --tests 'jp.jacky.kana.chart.KanaChartSheetTest'`
Expected: 1 test passed。若 `onNodeWithText("か")` 因 LazyColumn 未布局到该行而找不到，在断言前加 `compose.onNodeWithTag("kanaChart").performTouchInput { swipeUp() }` 不是正确修法；正确修法是把断言目标换成首行的 `あ` / `a` / `ア`（用 `onAllNodesWithText("あ")` 并断言数量 ≥ 2，因为头部按钮也含「あ」）。

- [ ] **Step 5: Commit**

```bash
git add source/android/app/src
git commit -m "Add the kana chart sheet"
```

---

### Task 13: 咖啡面板

**Files:**
- Modify: `app/src/main/kotlin/jp/jacky/kana/coffee/CoffeeSheet.kt`（替换占位）
- Test: `app/src/androidTest/kotlin/jp/jacky/kana/coffee/CoffeeSheetTest.kt`

**Interfaces:**
- Consumes: `CoffeeViewModel`、`CoffeeUiState`、`CoffeeAlert`、`CoffeeOperation`、字符串资源、`KanaColors`。
- Produces: `@Composable fun CoffeeSheet(viewModel: CoffeeViewModel, onDismiss: () -> Unit)`；tag `coffeeSheet`、`coffeeClose`、`coffeeTitle`、`coffeePurchase`、`coffeeStatus`、`coffeeRestore`。

- [ ] **Step 1: 写失败测试**

```kotlin
package jp.jacky.kana.coffee

import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import jp.jacky.kana.MainActivity
import jp.jacky.kana.TestKanaApplication
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class CoffeeSheetTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    private lateinit var scenario: ActivityScenario<MainActivity>

    @Before
    fun launch() {
        TestKanaApplication.get().resetContainer()
        scenario = ActivityScenario.launch(MainActivity::class.java)
    }

    @After
    fun close() = scenario.close()

    private fun openSheet() {
        compose.onNodeWithTag("menuToggle").performClick()
        compose.onNodeWithTag("coffeeMenu").performClick()
        compose.onNodeWithTag("coffeeSheet").assertIsDisplayed()
    }

    private fun waitForText(text: String) {
        compose.waitUntil(5_000) { compose.onAllNodesWithText(text).fetchSemanticsNodes().isNotEmpty() }
    }

    @Test
    fun purchaseShowsThePriceThenTheThankYou() {
        openSheet()
        waitForText("Buy me a coffee · ¥300")
        compose.onNodeWithTag("coffeeTitle").assert(hasText("Buy me a coffee"))
        compose.onNodeWithTag("coffeePurchase").assertIsEnabled().performClick()
        waitForText("Thanks for the coffee")
        compose.onNodeWithTag("coffeeTitle").assert(hasText("Thanks for the coffee"))
        compose.onNodeWithTag("coffeePurchase").assert(hasText("Back to practice"))
        compose.onNodeWithTag("coffeeRestore").assertDoesNotExist()
        compose.onNodeWithTag("coffeePurchase").performClick()
        compose.onNodeWithTag("coffeeSheet").assertDoesNotExist()
    }

    @Test
    fun restoreWithoutPurchaseShowsTheAlert() {
        openSheet()
        waitForText("Buy me a coffee · ¥300")
        compose.onNodeWithTag("coffeeRestore").performClick()
        waitForText("Nothing to restore")
        compose.onNodeWithText("No previous purchase was found for this Google account.").assertIsDisplayed()
        compose.onNodeWithText("OK").performClick()
        compose.onNodeWithText("Nothing to restore").assertDoesNotExist()
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `./gradlew :app:connectedDebugAndroidTest --tests 'jp.jacky.kana.coffee.CoffeeSheetTest'`
Expected: 失败于 `coffeeSheet` 不存在。

- [ ] **Step 3: 实现**

```kotlin
package jp.jacky.kana.coffee

import androidx.activity.compose.LocalActivity
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsBottomHeight
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.LocalCafe
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.ModalBottomSheetProperties
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import jp.jacky.kana.R
import jp.jacky.kana.ui.theme.KanaColors

/** "Buy me a coffee" sheet with the same states as the iOS CoffeeViewController. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CoffeeSheet(viewModel: CoffeeViewModel, onDismiss: () -> Unit) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val activity = LocalActivity.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true, confirmValueChange = { !state.busy })

    ModalBottomSheet(
        onDismissRequest = { if (!state.busy) onDismiss() },
        sheetState = sheetState,
        containerColor = KanaColors.paper,
        properties = ModalBottomSheetProperties(shouldDismissOnBackPress = !state.busy),
        modifier = Modifier.testTag("coffeeSheet"),
    ) {
        Box(Modifier.fillMaxWidth().fillMaxHeight()) {
            IconButton(
                onClick = onDismiss,
                enabled = !state.busy,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(end = 16.dp)
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(KanaColors.ink.copy(alpha = 0.05f))
                    .testTag("coffeeClose"),
            ) {
                Icon(Icons.Outlined.Close, contentDescription = stringResource(R.string.close), tint = KanaColors.secondary)
            }
            CoffeeContent(
                state = state,
                onPurchase = { activity?.let(viewModel::purchase) },
                onRestore = viewModel::restore,
                onClose = onDismiss,
                modifier = Modifier.align(Alignment.TopCenter).padding(top = 52.dp),
            )
        }
    }

    state.alert?.let { alert ->
        AlertDialog(
            onDismissRequest = viewModel::dismissAlert,
            confirmButton = { TextButton(onClick = viewModel::dismissAlert) { Text(stringResource(R.string.ok)) } },
            title = {
                Text(stringResource(if (alert is CoffeeAlert.RestoreNone) R.string.restore_none_title else R.string.purchase_failed_title))
            },
            text = {
                Text(
                    when (alert) {
                        CoffeeAlert.RestoreNone -> stringResource(R.string.restore_none_message)
                        is CoffeeAlert.Failed -> alert.detail ?: stringResource(R.string.coffee_unavailable)
                    }
                )
            },
        )
    }
}

@Composable
private fun CoffeeContent(
    state: CoffeeUiState,
    onPurchase: () -> Unit,
    onRestore: () -> Unit,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val purchased = state.purchased
    BoxWithConstraints(modifier.fillMaxWidth().fillMaxHeight()) {
        val viewportHeight = maxHeight
        Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState())) {
            // At least one viewport tall: the footer sits at the bottom on tall screens and the
            // whole sheet scrolls on short ones.
            Box(Modifier.fillMaxWidth().heightIn(min = viewportHeight)) {
                Column(
                    Modifier
                        .align(Alignment.TopCenter)
                        .widthIn(max = 380.dp)
                        .fillMaxWidth()
                        .padding(horizontal = 28.dp)
                        .padding(bottom = 64.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                Box(
                    Modifier.size(96.dp).clip(CircleShape).background(KanaColors.accent.copy(alpha = 0.07f)),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        if (purchased) Icons.Outlined.FavoriteBorder else Icons.Outlined.LocalCafe,
                        contentDescription = null,
                        tint = KanaColors.accent,
                        modifier = Modifier.size(44.dp),
                    )
                    Box(
                        Modifier
                            .align(Alignment.BottomEnd)
                            .size(28.dp)
                            .clip(CircleShape)
                            .background(KanaColors.paper)
                            .padding(4.dp)
                            .clip(CircleShape)
                            .background(KanaColors.accent),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Filled.Favorite, contentDescription = null, tint = Color.White, modifier = Modifier.size(11.dp))
                    }
                }
                Spacer(Modifier.height(24.dp))
                Text(
                    stringResource(if (purchased) R.string.coffee_thanks else R.string.coffee),
                    color = KanaColors.ink,
                    fontSize = 28.sp,
                    fontWeight = FontWeight.SemiBold,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.testTag("coffeeTitle"),
                )
                Spacer(Modifier.height(12.dp))
                Text(
                    stringResource(if (purchased) R.string.thanks_message else R.string.coffee_message),
                    color = KanaColors.secondary,
                    fontSize = 15.sp,
                    textAlign = TextAlign.Center,
                )
                Spacer(Modifier.height(28.dp))
                HorizontalDivider(color = KanaColors.ink.copy(alpha = 0.1f), thickness = 1.dp)
                Row(Modifier.padding(vertical = 16.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center) {
                    Icon(Icons.Outlined.CheckCircle, contentDescription = null, tint = KanaColors.accent, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(8.dp))
                    Text(
                        stringResource(if (purchased) R.string.coffee_supported else R.string.coffee_benefit),
                        color = KanaColors.secondary,
                        fontSize = 15.sp,
                    )
                }
                HorizontalDivider(color = KanaColors.ink.copy(alpha = 0.1f), thickness = 1.dp)
                Spacer(Modifier.height(26.dp))

                val busyLabel = when (state.operation) {
                    CoffeeOperation.PURCHASE -> stringResource(R.string.coffee_purchasing)
                    CoffeeOperation.RESTORE -> stringResource(R.string.coffee_restoring)
                    null -> null
                }
                val label = busyLabel
                    ?: if (purchased) stringResource(R.string.continue_practice)
                    else if (state.pending) stringResource(R.string.coffee_pending)
                    else if (state.loading) stringResource(R.string.coffee_loading)
                    else state.price?.let { stringResource(R.string.coffee_price, it) } ?: stringResource(R.string.retry)
                val showSpinner = state.busy || (state.loading && !purchased)
                Button(
                    onClick = { if (purchased) onClose() else onPurchase() },
                    enabled = !state.busy && (purchased || (!state.loading && !state.pending)),
                    colors = ButtonDefaults.buttonColors(containerColor = KanaColors.accent, contentColor = Color.White),
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp).testTag("coffeePurchase"),
                ) {
                    if (showSpinner) {
                        CircularProgressIndicator(color = Color.White, strokeWidth = 2.dp, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(10.dp))
                    }
                    Text(label, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
                }
                if (!purchased) {
                    Spacer(Modifier.height(4.dp))
                    Text(stringResource(R.string.coffee_terms), color = KanaColors.secondary, fontSize = 12.sp, textAlign = TextAlign.Center)
                }
                val status = when {
                    purchased -> null
                    state.pending -> stringResource(R.string.coffee_pending_message)
                    !state.loading && state.price == null -> stringResource(R.string.coffee_unavailable)
                    else -> null
                }
                if (status != null) {
                    Spacer(Modifier.height(12.dp))
                    Text(status, color = KanaColors.secondary, fontSize = 13.sp, textAlign = TextAlign.Center, modifier = Modifier.testTag("coffeeStatus"))
                }
                if (!purchased) {
                    Spacer(Modifier.height(12.dp))
                    TextButton(onClick = onRestore, enabled = !state.busy, modifier = Modifier.heightIn(min = 44.dp).testTag("coffeeRestore")) {
                        Text(stringResource(R.string.restore), color = KanaColors.secondary, fontSize = 15.sp)
                    }
                }                }
                Text(
                    "五 十 音",
                    color = KanaColors.secondary.copy(alpha = 0.45f),
                    fontSize = 17.sp,
                    fontFamily = FontFamily.Serif,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.align(Alignment.BottomCenter).padding(bottom = 24.dp),
                )
            }
            Spacer(Modifier.windowInsetsBottomHeight(WindowInsets.navigationBars))
        }
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `./gradlew :app:connectedDebugAndroidTest --tests 'jp.jacky.kana.coffee.CoffeeSheetTest'`
Expected: 2 tests passed。

- [ ] **Step 5: 全量回归**

Run: `./gradlew :app:testDebugUnitTest :app:connectedDebugAndroidTest`
Expected: 全部通过（单元测试 45 个左右，UI 测试 6 个）。

- [ ] **Step 6: Commit**

```bash
git add source/android/app/src
git commit -m "Add the coffee sheet"
```

---

### Task 14: 图标、本地化验证、文档、收尾

**Files:**
- Create: `scripts/make-android-icons.py`
- Create（脚本生成）: `app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher_foreground.png`
- Modify: `app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`、`ic_launcher_round.xml`（前景改为 PNG）
- Test: `app/src/androidTest/kotlin/jp/jacky/kana/LocalizationTest.kt`
- Modify: `source/android/README.md`、`README.md`（仓库根）、`TODO.md`

- [ ] **Step 1: 图标脚本**

`scripts/make-android-icons.py`：

```python
#!/usr/bin/env python3
"""Generate the Android adaptive launcher icon from the iOS 1024 px icon.

The iOS icon is a white square with handwritten 五十音 on the right. Android masks adaptive
icons, so the glyphs are re-centered inside the 66 dp safe zone of the 108 dp canvas.

Usage: python3 scripts/make-android-icons.py
"""
import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "source/kana/kana/Assets.xcassets/AppIcon.appiconset/Icon-1024.png"
RES = ROOT / "source/android/app/src/main/res"
DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}
CANVAS_DP = 108
GLYPH_BOX_DP = 60  # inside the 66 dp safe zone
INK = (0x17, 0x14, 0x12)


def extract_glyphs(image: Image.Image) -> Image.Image:
    gray = image.convert("L")
    alpha = gray.point(lambda p: 255 - p)
    ink = Image.new("RGBA", image.size, INK + (255,))
    ink.putalpha(alpha)
    bbox = alpha.point(lambda a: 255 if a > 10 else 0).getbbox()
    return ink.crop(bbox)


def foreground(glyphs: Image.Image, scale: float) -> Image.Image:
    canvas_px = round(CANVAS_DP * scale)
    box_px = round(GLYPH_BOX_DP * scale)
    canvas = Image.new("RGBA", (canvas_px, canvas_px), (0, 0, 0, 0))
    fitted = glyphs.copy()
    fitted.thumbnail((box_px, box_px), Image.LANCZOS)
    canvas.alpha_composite(fitted, ((canvas_px - fitted.width) // 2, (canvas_px - fitted.height) // 2))
    return canvas


def main() -> None:
    glyphs = extract_glyphs(Image.open(SOURCE))
    for density, scale in DENSITIES.items():
        target = RES / f"mipmap-{density}" / "ic_launcher_foreground.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        foreground(glyphs, scale).save(target, optimize=True)
        print(f"wrote {target.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
```

Run: `python3 scripts/make-android-icons.py`
Expected: 5 个 PNG；用 Read 工具打开 `mipmap-xxxhdpi/ic_launcher_foreground.png`，三个字居中、透明底。

把两个 `mipmap-anydpi-v26/*.xml` 的前景改为：

```xml
<foreground android:drawable="@mipmap/ic_launcher_foreground" />
```

- [ ] **Step 2: 本地化资源测试**

`androidTest/.../LocalizationTest.kt`：

```kotlin
package jp.jacky.kana

import android.content.res.Configuration
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test
import org.junit.runner.RunWith
import java.util.Locale

@RunWith(AndroidJUnit4::class)
class LocalizationTest {
    private fun string(locale: Locale, id: Int): String {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val configuration = Configuration(context.resources.configuration).apply { setLocale(locale) }
        return context.createConfigurationContext(configuration).getString(id)
    }

    @Test
    fun everyLanguageTranslatesTheChartTitle() {
        val english = string(Locale.ENGLISH, R.string.chart)
        assertEquals("Kana chart", english)
        listOf("ja", "zh-Hans", "zh-Hant", "ko", "de", "fr", "es").forEach { tag ->
            assertNotEquals(tag, english, string(Locale.forLanguageTag(tag), R.string.chart))
        }
    }

    @Test
    fun restoreMessageMentionsGoogle() {
        listOf("en", "ja", "zh-Hans", "zh-Hant", "ko", "de", "fr", "es").forEach { tag ->
            val text = string(Locale.forLanguageTag(tag), R.string.restore_none_message)
            assert(text.contains("Google")) { "$tag: $text" }
            assert(!text.contains("Apple")) { "$tag: $text" }
        }
    }

    @Test
    fun formatArgumentsWork() {
        assertEquals("Last 10 avg.", string(Locale.ENGLISH, R.string.stat_recent).format(10))
        assertEquals("1.23s", string(Locale.ENGLISH, R.string.stat_seconds).format("1.23"))
    }
}
```

Run: `./gradlew :app:connectedDebugAndroidTest --tests 'jp.jacky.kana.LocalizationTest'`
Expected: 3 tests passed。若某语言的 `chart` 翻译与英文相同（iOS 原文就相同），把那个语言从第一个测试的列表里去掉并在注释里说明。

- [ ] **Step 3: lint 与全量验证**

Run: `./gradlew :app:lintDebug :app:testDebugUnitTest :app:assembleDebug :app:connectedDebugAndroidTest`
Expected: 全部 `BUILD SUCCESSFUL`；lint 无 error。逐条处理 lint error（warning 可留）。

- [ ] **Step 4: 文档**

`source/android/README.md` 追加：

```markdown
## Emulator

```sh
avdmanager create avd -n kana_api_36 -k "system-images;android-36;google_apis;arm64-v8a" -d pixel_7
$ANDROID_HOME/emulator/emulator -avd kana_api_36 -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect &
adb wait-for-device
./gradlew :app:connectedDebugAndroidTest
```

Instrumented tests run against `TestKanaApplication`, which replaces the Play, AdMob, sound,
and share services with fakes and seeds the question order.

## Icons and strings

`scripts/make-android-icons.py` renders the adaptive launcher icon from the iOS 1024 px icon.
`scripts/ios-strings-to-android.py` regenerates every `strings.xml` from the iOS
`Localizable.strings` files; edit the iOS files (or the script's overrides) and rerun it.

## Consent form testing

Set `kana.ads.debugGeography=eea` in `gradle.properties` and rebuild the debug app to force the
EEA consent form on the emulator.
```

仓库根 `README.md`：在「Build and test」后加一节：

```markdown
### Android

The Android app lives in [source/android](source/android/README.md) (Kotlin, Jetpack Compose,
minSdk 26). Build and test with the Gradle wrapper:

```sh
cd source/android
./gradlew :app:testDebugUnitTest :app:assembleDebug
```
```

并把「Roadmap」段改为：

```markdown
## Roadmap

The Android app is implemented and awaits its Google Play release. See [TODO.md](TODO.md)
for the store submission tasks.
```

`TODO.md` 第 6 节前两项改为：

```markdown
- [x] **实现 Android 版**：对齐 iOS 的五秒四选一练习、连对挑战、设备内统计、五十音图、离线使用和多语言界面。2026-09-27 完成：`source/android/`（Kotlin + Compose），设计见 `docs/specs/2026-09-27-android-app-design.md`。
- [x] **接入广告与咖啡支持**：接入 Android AdMob、同意流程和 Google Play Billing；广告仅在答错或超时后触发，支持一次性咖啡购买与恢复。2026-09-27 完成；正式广告 ID 与 Play 商品要等主人在 AdMob / Play Console 建好后填入 `source/android/gradle.properties`。
```

- [ ] **Step 5: Commit 并更新 PR**

```bash
git add scripts/make-android-icons.py source/android README.md TODO.md
git commit -m "Add the launcher icon, localization tests, and Android docs"
git push
gh pr ready 6
gh pr edit 6 --body "$(cat <<'EOF'
## Summary
Android version of Kana (TODO section 6, items 1 and 2), implemented per `docs/specs/2026-09-27-android-app-design.md` and `docs/plans/2026-09-27-android-app.md`:
- Practice loop, statistics, kana chart, coffee purchase (Play Billing 9), AdMob banner with UMP consent, share and feedback, eight languages.
- Single-module Kotlin + Jetpack Compose app in `source/android/`, minSdk 26, targetSdk 36.
- Debug builds use Google test ad IDs; release builds require the production IDs and a signing key.

## Test plan
- [x] `./gradlew :app:testDebugUnitTest`
- [x] `./gradlew :app:lintDebug`
- [x] `./gradlew :app:assembleDebug`
- [x] `./gradlew :app:connectedDebugAndroidTest` on the `kana_api_36` emulator
- [x] Manual check on the emulator: practice, wrong answer highlight, timeout, statistics, menu, chart, coffee sheet states, test banner
EOF
)"
```

---

## Self-review notes

- Spec 第 3 节的工具链在实施前已按最新稳定版核实并改为 AGP 9.4.1 / Gradle 9.6.0 / Kotlin 2.4.20 / compileSdk 37.0；统计 JSON 用 `org.json` 而非 kotlinx.serialization；横幅尺寸沿用 `getCurrentOrientationAnchoredAdaptiveBannerAdSize`（SDK 25 标记弃用但仍可用，新的 large 版本最高占屏 20%，不符合 iOS 的高度）。这些差异已同步回 spec。
- Spec 第 6.2 节「答案格式 1px 分隔」、第 6.4 节各状态、第 7 节同意流程、第 8 节内购、第 9 节分享、第 10 节资源、第 11 节错误处理、第 12 节测试都能对应到 Task 2、7、8、9、10、11、12、13、14。
- 没有测试的部分：`GoogleAdsManager`、`PlayBillingGateway`、`BannerAd`、`SoundPoolPlayer`、`AndroidShareActions`（纯 Android 胶水，用 debug 构建手动检查）。
