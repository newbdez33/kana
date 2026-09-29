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
