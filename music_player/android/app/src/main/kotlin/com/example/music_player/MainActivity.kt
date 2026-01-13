package com.example.music_player

import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: AudioServiceFragmentActivity() {
    private val CHANNEL = "com.example.music_player/notification"
    private lateinit var notificationManager: CustomNotificationManager
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        notificationManager = CustomNotificationManager(this)
        
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        MediaButtonReceiver.methodChannel = channel
        
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "Unknown"
                    val artist = call.argument<String>("artist") ?: "Unknown Artist"
                    val artworkPath = call.argument<String>("artworkPath")
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    
                    notificationManager.showNotification(title, artist, artworkPath, isPlaying)
                    result.success(null)
                }
                "hideNotification" -> {
                    notificationManager.cancelNotification()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
