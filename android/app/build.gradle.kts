import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningProperties = Properties()
val releaseSigningPropertiesFile = rootProject.file("key.properties")
if (releaseSigningPropertiesFile.isFile) {
    releaseSigningPropertiesFile.inputStream().use(releaseSigningProperties::load)
}

val releaseTasksRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val releaseSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val missingReleaseSigningKeys = releaseSigningKeys.filter {
    releaseSigningProperties.getProperty(it).isNullOrBlank()
}
if (releaseTasksRequested && missingReleaseSigningKeys.isNotEmpty()) {
    throw GradleException(
        "Release signing is not configured. Add ${missingReleaseSigningKeys.joinToString()} " +
            "to android/key.properties. See docs/ANDROID_RELEASE.md."
    )
}

android {
    namespace = "com.medsuper.med_super"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (uses java.time APIs via
        // desugaring on API levels below 26).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.medsuper.med_super"
        minSdk = flutter.minSdkVersion
        // Google Play requires API 36 for new app submissions from 2026-08-31.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (missingReleaseSigningKeys.isEmpty()) {
                storeFile = rootProject.file(releaseSigningProperties.getProperty("storeFile")!!)
                storePassword = releaseSigningProperties.getProperty("storePassword")!!
                keyAlias = releaseSigningProperties.getProperty("keyAlias")!!
                keyPassword = releaseSigningProperties.getProperty("keyPassword")!!
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
