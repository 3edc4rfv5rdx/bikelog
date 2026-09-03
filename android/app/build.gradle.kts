import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

val keystorePropertiesFile = file(System.getProperty("user.home") + "/.my-safe/key.properties")
val keystoreProperties = Properties()
keystoreProperties.load(FileInputStream(keystorePropertiesFile))

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}


android {
    namespace = "a.a.bikelog"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
	ndkVersion = "27.0.12077973"
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "a.a.bikelog"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
//        ndk {
//             abiFilters.add("arm64-v8a")
//        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "armeabi-v7a", "x86_64", "x86")
            isUniversalApk = true  // Enable universal APK generation
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

// With --split-per-abi the Flutter plugin rewrites each APK's version code as
// abi * 1000 + build, so one build reads as 2070 on arm64 and 4070 on x86_64.
// A store needs that ordering; these APKs are installed by hand and offered by
// the updater, which compares the manifest against the code inside the installed
// APK, so the two must be the same number.
//
// Registered here rather than in afterEvaluate, where the property is already
// closed for writing: the plugin hooks the variants from its own apply(), so an
// action added below it in this script still runs second and wins.
@Suppress("DEPRECATION")
(extensions.getByName("android") as com.android.build.gradle.AppExtension)
    .applicationVariants
    .all {
        outputs.all {
            (this as com.android.build.gradle.api.ApkVariantOutput).versionCodeOverride =
                flutter.versionCode
        }
    }
