# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep local_auth
-keep class io.flutter.plugins.localauth.** { *; }

# Keep flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep flutter_windowmanager
-keep class io.adaptant.labs.flutter_windowmanager.** { *; }

# Hive
-keep class com.hive.** { *; }
-keep class io.hivedb.** { *; }

# PointyCastle
-keep class org.pointycastle.** { *; }

# Encrypt
-keep class encrypt.** { *; }
