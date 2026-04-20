plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.sachcheck.sachcheck"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.marwadiuniversity.sachdrishti"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    dependencies {

        implementation("com.google.mlkit:text-recognition:16.0.0")

        implementation("com.google.mlkit:text-recognition-chinese:16.0.0")
        implementation("com.google.mlkit:text-recognition-devanagari:16.0.0")
        implementation("com.google.mlkit:text-recognition-japanese:16.0.0")
        implementation("com.google.mlkit:text-recognition-korean:16.0.0")

    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
