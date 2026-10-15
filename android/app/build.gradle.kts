import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing for sideload distribution. The keystore and its passwords
// live outside version control in key.properties — see key.properties.example.
// When that file is absent (a fresh clone, or CI without secrets) release falls
// back to the debug keystore so the build still succeeds; the output is then
// only fit for local testing, not for handing to users.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val hasReleaseKeystore = keystoreProperties.getProperty("keyAlias") != null

android {
    namespace = "mu.org.asu.planner"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "mu.org.asu.planner"
        // Version code/name come from pubspec.yaml, the single source of truth.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // When using split APKs, 1000 * ABI_VERSION is added automatically by
        // Flutter. Force the value with -P force-version-code-ignoring-abi=true.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile")!!)
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("key.properties missing — signing release with the DEBUG keystore. Not for distribution.")
                signingConfigs.getByName("debug")
            }
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
