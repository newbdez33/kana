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
        versionCode = 2
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
