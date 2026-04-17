import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.grandmaster.chess.pro"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.grandmaster.chess.pro"
        minSdk = 21
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
        }
    }

    signingConfigs {
        create("release") {
            keyAlias     = (keystoreProperties["keyAlias"]     as String?) ?: "chess-mate"
            keyPassword  = (keystoreProperties["keyPassword"]  as String?) ?: "chessmate123"
            storeFile    = keystoreProperties["storeFile"]?.let { file(it as String) }
                           ?: file("release-keystore.jks")
            storePassword = (keystoreProperties["storePassword"] as String?) ?: "chessmate123"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled   = false
            isShrinkResources = false
            signingConfig     = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

tasks.whenTaskAdded {
    if (name.contains("checkReleaseAarMetadata")) enabled = false
}
