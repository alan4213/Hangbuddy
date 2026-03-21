# Keep Google Play Services Auth classes
-keep class com.google.android.gms.auth.api.credentials.** { *; }
-dontwarn com.google.android.gms.auth.api.credentials.**

# Keep smart_auth plugin classes
-keep class fman.ge.smart_auth.** { *; }
-dontwarn fman.ge.smart_auth.**