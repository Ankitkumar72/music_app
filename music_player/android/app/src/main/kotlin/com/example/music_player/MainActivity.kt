package com.example.music_player

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.os.Build

class MainActivity: FlutterActivity(), CustomMediaService.MediaActionCallback {
    private val CHANNEL = "com.example.music_player/notification"
    private var mediaService: CustomMediaService? = null
    private var isBound = false
    private var methodChannel: MethodChannel? = null

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            android.util.Log.d("MainActivity", "✅ Service Connected!")
            val binder = service as CustomMediaService.LocalBinder
            mediaService = binder.getService()
            // Set up the callback for media actions
            mediaService?.setMediaActionCallback(this@MainActivity)
            isBound = true
        }
        override fun onServiceDisconnected(name: ComponentName?) {
            android.util.Log.d("MainActivity", "❌ Service Disconnected!")
            mediaService?.setMediaActionCallback(null)
            mediaService = null
            isBound = false
        }
    }
    
    // Fallback broadcast receiver (in case callback not available)
    private val mediaActionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.getStringExtra("action") ?: return
            android.util.Log.d("MainActivity", "📻 Broadcast received: $action")
            forwardMediaActionToFlutter(action)
        }
    }
    
    // Implementation of MediaActionCallback interface - called directly by service
    override fun onMediaAction(action: String) {
        android.util.Log.d("MainActivity", "🎵 Direct callback received: $action")
        forwardMediaActionToFlutter(action)
    }

    override fun onSeekTo(position: Long) {
        android.util.Log.d("MainActivity", "🎵 Direct callback seek: $position")
        runOnUiThread {
            methodChannel?.invokeMethod("onMediaButton", mapOf("action" to "seek", "position" to position))
        }
    }
    
    private fun forwardMediaActionToFlutter(action: String) {
        // Forward to Flutter via MethodChannel
        runOnUiThread {
            methodChannel?.invokeMethod("onMediaButton", mapOf("action" to action))
            android.util.Log.d("MainActivity", "✅ Forwarded to Flutter: $action")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Store method channel reference for callbacks
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        // Bind to service
        Intent(this, CustomMediaService::class.java).also { intent ->
            bindService(intent, connection, Context.BIND_AUTO_CREATE)
        }
        
        // Register receiver for media actions (fallback)
        val filter = IntentFilter("com.example.music_player.MEDIA_CONTROL")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(mediaActionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(mediaActionReceiver, filter)
        }

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> { 
                    val title = call.argument<String>("title") ?: ""
                    val artist = call.argument<String>("artist") ?: ""
                    val artPath = call.argument<String>("artworkPath")
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    val duration = call.argument<Number>("duration")?.toLong() ?: -1L
                    val position = call.argument<Number>("position")?.toLong() ?: 0L
                    
                    if (mediaService == null) {
                         android.util.Log.e("MainActivity", "❌ FATAL: mediaService is NULL! Binding failed or not ready.")
                    } else {
                         android.util.Log.d("MainActivity", "➡️ Forwarding to MediaService: $title")
                         mediaService?.updateNotification(title, artist, artPath, isPlaying, duration, position)
                    }
                    result.success(null)
                }
                "moveToBackground" -> {
                    moveTaskToBack(true)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    override fun onDestroy() {
        if (isBound) {
            mediaService?.setMediaActionCallback(null)
            unbindService(connection)
            isBound = false
        }
        try {
            unregisterReceiver(mediaActionReceiver)
        } catch (e: Exception) {
             // ignore
        }
        methodChannel = null
        super.onDestroy()
    }
}
