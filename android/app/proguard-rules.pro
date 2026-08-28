# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# FFmpegKit
-keep class com.arthenica.ffmpegkit.** { *; }

# Hive
-keep class hive.** { *; }
-keepclassmembers class * extends com.google.protobuf.GeneratedMessageLite { *; }

# Keep Kotlin metadata for reflection-based plugins
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
