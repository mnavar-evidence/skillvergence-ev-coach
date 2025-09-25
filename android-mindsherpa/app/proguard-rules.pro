# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Fix non-SDK API usage for Android P+ compatibility
# Keep MethodHandles for reflection-based libraries
-dontwarn java.lang.invoke.**
-keep class java.lang.invoke.** { *; }

# Keep Mux Player classes from obfuscation
-keep class com.mux.** { *; }
-dontwarn com.mux.**

# Keep Retrofit and Gson classes with proper generic signatures
-keep class com.squareup.retrofit2.** { *; }

# Gson specific rules - CRITICAL for TypeToken
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Keep Gson classes
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }

# Keep generic signatures for TypeToken
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep all model classes used with Gson (your API models)
-keep class com.skillvergence.mindsherpa.data.model.** { *; }

# Keep generic type information for Gson deserialization
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Keep enum names for Gson
-keepnames class * extends java.lang.Enum {
    <fields>;
    public static **[] values();
    public static ** valueOf(java.lang.String);
}