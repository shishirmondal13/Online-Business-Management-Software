# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Prevent obfuscating model classes if they are used with reflection (e.g. JSON serialization)
# Adjust the package name to match your app's package name
-keep class com.smartbuyonline.app.** { *; }

# Keep generic Flutter classes
-keep class io.flutter.facade.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep all enum values
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Play Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
