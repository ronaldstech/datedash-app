# Flutter Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# General Android
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**
-dontwarn javax.annotation.**
-dontwarn org.apache.http.**
-dontwarn sun.misc.Unsafe
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# To prevent obfuscation of certain classes that might be accessed via reflection
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Optimization Settings
-optimizationpasses 5
-allowaccessmodification
-dontpreverify
-repackageclasses ''
