package com.example.music_player

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class MediaControlReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.getStringExtra("action") ?: return
        
        android.util.Log.d("MediaControlReceiver", "Received action: $action")
        
        // Forward to MainActivity's method channel
        val mainIntent = Intent("com.example.music_player.MEDIA_ACTION_INTERNAL").apply {
            putExtra("action", action)
            setPackage(context.packageName)
        }
        context.sendBroadcast(mainIntent)
    }
}
