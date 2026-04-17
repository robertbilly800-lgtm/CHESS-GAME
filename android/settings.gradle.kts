pluginManagement {
    // Using FLUTTER_ROOT which is standard on Codemagic
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
    // Using the versions from your build.gradle to ensure compatibility
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
