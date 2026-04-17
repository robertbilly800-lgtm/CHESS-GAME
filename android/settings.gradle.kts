pluginManagement {
    // Using full package names to ensure the compiler finds the classes
    val flutterSdkPath = {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        if (localPropertiesFile.exists()) {
            properties.load(java.io.FileInputStream(localPropertiesFile))
        }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        checkNotNull(flutterSdkPath) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }()

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
