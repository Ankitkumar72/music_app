package com.example.music_player

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.view.KeyEvent

class MediaButtonReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context?, intent: Intent?) {
        android.util.Log.d("MediaButtonReceiver", "onReceive called")
        android.util.Log.d("MediaButtonReceiver", "Intent action: ${intent?.action}")
        android.util.Log.d("MediaButtonReceiver", "Intent extras: ${intent?.extras}")
        
        if (context == null || intent == null) {
            android.util.Log.e("MediaButtonReceiver", "Context or intent is null")
            return
        }
        
        val action = intent.getStringExtra("action")
        android.util.Log.d("MediaButtonReceiver", "Extracted action: $action")
        
        if (action == null) {
            android.util.Log.e("MediaButtonReceiver", "Action is null")
            return
        }
        
        // Convert to media button key event
        val keyCode = when (action) {
            "play" -> KeyEvent.KEYCODE_MEDIA_PLAY
            "pause" -> KeyEvent.KEYCODE_MEDIA_PAUSE
            "next" -> KeyEvent.KEYCODE_MEDIA_NEXT
            "previous" -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
            else -> {
                android.util.Log.e("MediaButtonReceiver", "Unknown action: $action")
                return
            }
        }
        
        android.util.Log.d("MediaButtonReceiver", "Sending media button: $keyCode")
        
        // Send media button event
        val downEvent = KeyEvent(KeyEvent.ACTION_DOWN, keyCode)
        val upEvent = KeyEvent(KeyEvent.ACTION_UP, keyCode)
        
        val mediaIntent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            setPackage(context.packageName)
            putExtra(Intent.EXTRA_KEY_EVENT, downEvent)
        }
        context.sendOrderedBroadcast(mediaIntent, null)
        
        val mediaIntent2 = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            setPackage(context.packageName)
            putExtra(Intent.EXTRA_KEY_EVENT, upEvent)
        }
        context.sendOrderedBroadcast(mediaIntent2, null)
        
        android.util.Log.d("MediaButtonReceiver", "Media button events sent")
    }
}