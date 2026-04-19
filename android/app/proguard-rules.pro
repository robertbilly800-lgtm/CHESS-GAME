# Stockfish AI Protection
-keep class com.multistockfish.** { *; }
-keep interface com.multistockfish.** { *; }
-dontwarn com.multistockfish.**

# Native library protection
-keep class io.flutter.embedding.engine.FlutterJNI { *; }

# General Flutter stability
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
