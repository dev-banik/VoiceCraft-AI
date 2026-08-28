// The Android Gradle Plugin and Kotlin plugin versions are intentionally
// NOT pinned here or in settings.gradle.kts — that file is generated fresh
// by `flutter create` in CI (see .github/workflows/build_apk.yml) rather
// than hand-authored, precisely so those versions always match what the
// Flutter SDK actually in use expects, instead of a guess baked in here
// going stale. The Google Services plugin is the one addition this project
// needs beyond stock Flutter, so it's wired the classic buildscript/apply
// way below — self-contained, and unaffected by whatever AGP/Kotlin/Gradle
// versions settings.gradle.kts ends up pinning.
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
