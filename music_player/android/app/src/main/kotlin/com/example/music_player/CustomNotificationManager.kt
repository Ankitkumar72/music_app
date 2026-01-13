package com.example.music_player

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle
import java.io.File

class CustomNotificationManager(private val context: Context) {
    
    // Match AudioService's Channel ID and Notification ID to ovewrite the default notification
    private val CHANNEL_ID = "com.example.music_player.channel.audio"
    private val NOTIFICATION_ID = 1124 // Default AudioService notification ID
    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    
    init {
        createNotificationChannel()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Music Playback",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows currently playing music"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    fun showNotification(
        title: String,
        artist: String,
        artworkPath: String?,
        isPlaying: Boolean
    ) {
        android.util.Log.d("CustomNotification", "Showing notification: $title, Art: $artworkPath")
        val artwork = loadArtwork(artworkPath)
        android.util.Log.d("CustomNotification", "Artwork loaded: ${artwork != null}")
        
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle(title)
            .setContentText(artist)
            .setLargeIcon(artwork)
            .setOnlyAlertOnce(true)
            .setStyle(MediaStyle()
                .setShowActionsInCompactView(0, 1, 2))
            .addAction(createAction("previous", android.R.drawable.ic_media_previous))
            .addAction(
                if (isPlaying) 
                    createAction("pause", android.R.drawable.ic_media_pause)
                else 
                    createAction("play", android.R.drawable.ic_media_play)
            )
            .addAction(createAction("next", android.R.drawable.ic_media_next))
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(isPlaying) // Make non-dismissible only when playing
            .build()
        
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
    
    private fun loadArtwork(path: String?): Bitmap? {
        return try {
            if (path != null && File(path).exists()) {
                val bitmap = BitmapFactory.decodeFile(path)
                android.util.Log.d("CustomNotification", "Decoded bitmap size: ${bitmap?.byteCount}")
                bitmap
            } else {
                android.util.Log.d("CustomNotification", "Artwork file not found or path null")
                null
            }
        } catch (e: Exception) {
            android.util.Log.e("CustomNotification", "Error loading artwork: $e")
            null
        }
    }
    
    private fun createAction(action: String, icon: Int): NotificationCompat.Action {
        val intent = Intent("com.example.music_player.MEDIA_ACTION").apply {
            putExtra("action", action)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            action.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Action.Builder(icon, action, pendingIntent).build()
    }
    
    fun cancelNotification() {
        notificationManager.cancel(NOTIFICATION_ID)
    }
}
