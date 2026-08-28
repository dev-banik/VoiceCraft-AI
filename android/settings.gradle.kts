// Pinned explicitly (rather than left for `flutter create` to generate,
// as originally tried) because this Flutter SDK's default — AGP 9.0 —
// hard-errors on the classic `android { }` / `kotlinOptions { }` /
// `.srcDirs()` Kotlin DSL surface used in app/build.gradle.kts, requiring
// a migration to AGP 9's new ApplicationExtension-based DSL that isn't
// documented/stable enough yet to confidently target. AGP 8.5.2 predates
// that breaking change (it only applies "by default in AGP 9.0" per AGP's
// own deprecation message) and is a well-established, broadly compatible
// version otherwise. A newer Gradle wrapper (which `flutter create` still
// generates fresh) running an older, explicitly pinned AGP like this is
// the well-supported direction for that combination.
pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.5.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}

include(":app")
