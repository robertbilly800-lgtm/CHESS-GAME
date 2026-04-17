pluginManagement {
    // Use FLUTTER_ROOT environment variable directly (Standard on Codemagic)
    val flutterSdkPath = System.getenv("FLUTTER_ROOT") ?: "${System.getProperty("user.home")}/flutter"
    println("Using Flutter SDK path: $flutterSdkPath")

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.1.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
}

include(":app")
