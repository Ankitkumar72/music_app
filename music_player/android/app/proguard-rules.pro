-keep class com.ryanheise.just_audio.** { *; }
-keep class com.google.android.exoplayer2.** { *; }

# Keep custom notification and media service classes (including inner classes)
-keep class com.example.music_player.** { *; }
-keep interface com.example.music_player.** { *; }
-keep class com.example.music_player.**$* { *; }

# Keep Android MediaSession classes
-keep class android.support.v4.media.** { *; }
-keep class androidx.media.** { *; }

# Keep BroadcastReceiver methods
-keepclassmembers class * extends android.content.BroadcastReceiver {
    public void onReceive(android.content.Context, android.content.Intent);
}

# Keep Service methods and binders
-keepclassmembers class * extends android.app.Service {
    public android.os.IBinder onBind(android.content.Intent);
}

# Keep Kotlin metadata for reflection
-keep class kotlin.Metadata { *; }

# Keep Flutter plugin classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Suppress warnings for Play Core classes (referenced by Flutter deferred components)
-dontwarn com.google.android.play.core.**