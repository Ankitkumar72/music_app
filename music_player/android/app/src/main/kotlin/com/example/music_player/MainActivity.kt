package com.example.music_player

import android.content.*
import android.os.Build
import android.os.IBinder
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: AudioServiceFragmentActivity() {
    private val CHANNEL = "com.example.music_player/notification"
    private lateinit var notificationManager: CustomNotificationManager
    private var methodChannel: MethodChannel? = null
    
    private var mediaService: CustomMediaService? = null
    private var serviceBound = false
    
    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as CustomMediaService.LocalBinder
            mediaService = binder.getService()
            serviceBound = true
            
            // Pass the MediaSession token to notification manager
            mediaService?.getSessionToken()?.let {
                notificationManager.setMediaSessionToken(it)
            }
            android.util.Log.d("MainActivity", "MediaService connected and token set")
        }
        
        override fun onServiceDisconnected(name: ComponentName?) {
            serviceBound = false
            mediaService = null
            android.util.Log.d("MainActivity", "MediaService disconnected")
        }
    }
    
    private val mediaActionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.getStringExtra("action") ?: return
            
            android.util.Log.d("MainActivity", "Media action received: $action")
            
            // Forward to Flutter
            methodChannel?.invokeMethod("onMediaButton", mapOf("action" to action))
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        notificationManager = CustomNotificationManager(this)
        
        // Bind to MediaService
        Intent(this, CustomMediaService::class.java).also { intent ->
            bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
        }
        
        // Register receiver for media actions
        val filter = IntentFilter("com.example.music_player.MEDIA_ACTION_INTERNAL")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(mediaActionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(mediaActionReceiver, filter)
        }
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "Unknown"
                    val artist = call.argument<String>("artist") ?: "Unknown Artist"
                    val artworkPath = call.argument<String>("artworkPath")
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    
                    // Update MediaSession state
                    mediaService?.updatePlaybackState(isPlaying)
                    
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
    
    override fun onDestroy() {
        if (serviceBound) {
            unbindService(serviceConnection)
            serviceBound = false
        }
        try {
            unregisterReceiver(mediaActionReceiver)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error unregistering receiver: $e")
        }
        super.onDestroy()
    }
}
