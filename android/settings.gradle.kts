// Pinned explicitly (rather than left for `flutter create` to generate,
// as originally tried) to thread a narrow window this Flutter SDK requires:
//   - AGP must be >= 8.11.1 — this exact version came from the Flutter
//     Gradle plugin's own error message ("Your project's Android Gradle
//     Plugin version is lower than Flutter's minimum supported version of
//     Android Gradle Plugin version 8.11.1") when 8.5.2 was tried first.
//     (AGP 8.11.1 does print a soft "support will soon be dropped, upgrade
//     to 9.0.1+" warning — non-fatal, left as-is rather than chasing AGP 9's
//     newDsl migration.)
//   - AGP must be < 9.0 — AGP 9.0 defaults `android.newDsl=true`, which
//     hard-errors on the classic `android { }` / `kotlinOptions { }` /
//     `.srcDirs()` Kotlin DSL surface used in app/build.gradle.kts, per
//     AGP's own deprecation message ("default in AGP 9.0").
//   - Kotlin must be >= 2.2.20 — again the Flutter Gradle plugin's own
//     error message ("Your project's Kotlin version (2.0.0) is lower than
//     Flutter's minimum supported version of 2.2.20"), hit even after
//     pinning 1.9.24 here (something in Flutter's plugin resolution
//     coerced that to 2.0.0 rather than honoring it outright — pinning
//     Flutter's exact stated floor sidesteps needing to know why).
// Both pins are Flutter's own stated floor, chosen the same way for the
// same reason: verified from an actual build error rather than guessed.
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
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
