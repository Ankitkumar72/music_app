package com.example.music_player

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodChannel

class MediaButtonReceiver : BroadcastReceiver() {
    
    companion object {
        var methodChannel: MethodChannel? = null
    }
    
    override fun onReceive(context: Context?, intent: Intent?) {
        val action = intent?.getStringExtra("action") ?: return
        
        methodChannel?.invokeMethod("onMediaButton", mapOf("action" to action))
    }
}
