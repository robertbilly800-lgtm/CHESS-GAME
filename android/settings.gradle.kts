import java.util.Properties

val flutterSdkPath = {
    val properties = Properties()
    file("local.properties").inputStream().use { properties.load(it) }
    val flutterSdkPath = properties.getProperty("flutter.sdk")
    require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
    flutterSdkPath
}()

pluginManagement {
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
