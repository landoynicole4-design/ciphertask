# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Keep local_auth
-keep class io.flutter.plugins.localauth.** { *; }

# Keep flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# Keep flutter_windowmanager
-keep class io.adaptant.labs.flutter_windowmanager.** { *; }

# AndroidX lifecycle
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.lifecycle.**

# Google Play Core - ignore missing classes
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Hive
-keep class com.hive.** { *; }
-keep class io.hivedb.** { *; }

# PointyCastle
-keep class org.pointycastle.** { *; }

# Encrypt
-keep class encrypt.** { *; }

# Keep text input fields to prevent crash
-keep class io.flutter.plugins.texteffect.** { *; }

# Prevent ProGuard from stripping interface information
-keep,allowobfuscation,allowshrinking interface * { *; }

# Prevent R8 from leaving Data object members always null
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
