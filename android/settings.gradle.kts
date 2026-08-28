// Pinned explicitly (rather than left for `flutter create` to generate,
// as originally tried) to thread a narrow window this Flutter SDK requires:
//   - AGP must be >= 8.11.1 — this exact version came from the Flutter
//     Gradle plugin's own error message ("Your project's Android Gradle
//     Plugin version is lower than Flutter's minimum supported version of
//     Android Gradle Plugin version 8.11.1") when 8.5.2 was tried first.
//   - AGP must be < 9.0 — AGP 9.0 defaults `android.newDsl=true`, which
//     hard-errors on the classic `android { }` / `kotlinOptions { }` /
//     `.srcDirs()` Kotlin DSL surface used in app/build.gradle.kts, per
//     AGP's own deprecation message ("default in AGP 9.0"). Migrating to
//     AGP 9's new ApplicationExtension-based DSL isn't something to
//     confidently do without documentation for a release this new.
// 8.11.1 is therefore pinned exactly: it's Flutter's stated floor, and
// still within the pre-9.0 classic-DSL window.
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
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}

include(":app")
