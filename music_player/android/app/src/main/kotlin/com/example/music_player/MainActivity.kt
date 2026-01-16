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

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.music_player/notification" // Keeping this channel name consistent with dart side unless dart side changes
    private var mediaService: CustomMediaService? = null
    private var isBound = false

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            android.util.Log.d("MainActivity", "✅ Service Connected!")
            val binder = service as CustomMediaService.LocalBinder
            mediaService = binder.getService()
            isBound = true
        }
        override fun onServiceDisconnected(name: ComponentName?) {
            android.util.Log.d("MainActivity", "❌ Service Disconnected!")
            isBound = false
        }
    }
    
    private val mediaActionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.getStringExtra("action") ?: return
            
            // Forward to Flutter via MethodChannel
             flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                 MethodChannel(messenger, "com.example.music_player/notification")
                    .invokeMethod("onMediaButton", mapOf("action" to action))
             }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Bind to service
        Intent(this, CustomMediaService::class.java).also { intent ->
            bindService(intent, connection, Context.BIND_AUTO_CREATE)
        }
        
        // Register receiver for media actions sent from Service/Notification
        val filter = IntentFilter("com.example.music_player.MEDIA_CONTROL")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(mediaActionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(mediaActionReceiver, filter)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.music_player/notification").setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> { 
                    val title = call.argument<String>("title") ?: ""
                    val artist = call.argument<String>("artist") ?: ""
                    val artPath = call.argument<String>("artworkPath")
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    
                    if (mediaService == null) {
                         android.util.Log.e("MainActivity", "❌ FATAL: mediaService is NULL! Binding failed or not ready.")
                    } else {
                         android.util.Log.d("MainActivity", "➡️ Forwarding to MediaService: $title")
                         mediaService?.updateNotification(title, artist, artPath, isPlaying)
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
            unbindService(connection)
            isBound = false
        }
        try {
            unregisterReceiver(mediaActionReceiver)
        } catch (e: Exception) {
             // ignore
        }
        super.onDestroy()
    }
}
