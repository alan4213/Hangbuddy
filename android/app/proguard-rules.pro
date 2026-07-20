# Keep Google Play Services Auth classes
-keep class com.google.android.gms.auth.api.credentials.** { *; }
-dontwarn com.google.android.gms.auth.api.credentials.**

# Keep smart_auth plugin classes
-keep class fman.ge.smart_auth.** { *; }
-dontwarn fman.ge.smart_auth.**

# Keep Haule app classes (fixes ClassNotFoundException crash from Play Store)
-keep class com.hauleapp.haule.** { *; }
-dontwarn com.hauleapp.haule.**

# Keep Flutter classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
-keep class io.flutter.plugins.** { *; }

# Keep AndroidX classes
-keep class androidx.** { *; }
-dontwarn androidx.**