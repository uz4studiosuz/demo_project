# AutoValue
-dontwarn com.google.auto.value.**
-keep class com.google.auto.value.** { *; }

# Mapbox
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**

# Flutter Mapbox Navigation
-keep class com.eopeter.fluttermapboxnavigation.** { *; }
-dontwarn com.eopeter.fluttermapboxnavigation.**

# General Android
-keepattributes Signature,Annotation*
-dontwarn sun.misc.Unsafe
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
