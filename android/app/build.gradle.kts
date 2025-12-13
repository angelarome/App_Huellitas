plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin
    id("com.google.gms.google-services")    // Firebase
}

android {
    namespace = "com.example.huellitas"
    compileSdk = 33 // valor explícito, no flutter.compileSdkVersion
    ndkVersion = "25.2.9519653" // ejemplo, ajusta según tu proyecto

    defaultConfig {
        applicationId = "com.example.huellitas"
        minSdk = flutter.minSdkVersion
        targetSdk = 33 // valor explícito
        versionCode = 1
        versionName = "1.0"
    }

    buildFeatures {
        buildConfig = true  // <--- esto es lo que Cloud Firestore necesita
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
    implementation("com.google.firebase:firebase-analytics")
    // otras librerías Firebase que necesites
}

flutter {
    source = "../.."
}
