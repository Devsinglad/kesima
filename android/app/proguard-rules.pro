# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Suppress warnings for Play Core classes referenced by Flutter internals
-dontwarn com.google.android.play.core.**

# Audio players
-keep class xyz.luan.audioplayers.** { *; }

# Shared preferences
-keep class androidx.datastore.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}
