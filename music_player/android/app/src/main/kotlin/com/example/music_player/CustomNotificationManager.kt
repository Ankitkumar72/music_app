package com.example.music_player

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.support.v4.media.session.MediaSessionCompat
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle
import java.io.File

class CustomNotificationManager(private val context: Context) {
    
    private val CHANNEL_ID = "com.example.music_player.channel.audio"
    private val CUSTOM_NOTIFICATION_ID = 1124
    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    
    private var sessionToken: MediaSessionCompat.Token? = null
    
    init {
        createNotificationChannel()
    }
    
    fun setMediaSessionToken(token: MediaSessionCompat.Token) {
        this.sessionToken = token
        android.util.Log.d("CustomNotification", "MediaSession token set")
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
        android.util.Log.d("CustomNotification", "Showing notification: $title, Art: $artworkPath, Token: ${sessionToken != null}")
        val artwork = loadArtwork(artworkPath)
        
        // Create media actions
        val previousAction = createMediaAction("previous", android.R.drawable.ic_media_previous)
        val playPauseAction = if (isPlaying) {
            createMediaAction("pause", android.R.drawable.ic_media_pause)
        } else {
            createMediaAction("play", android.R.drawable.ic_media_play)
        }
        val nextAction = createMediaAction("next", android.R.drawable.ic_media_next)
        
        val mediaStyle = MediaStyle()
            .setShowActionsInCompactView(0, 1, 2)
        
        // CRITICAL: Set the MediaSession token
        if (sessionToken != null) {
            mediaStyle.setMediaSession(sessionToken)
        }
        
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle(title)
            .setContentText(artist)
            .setLargeIcon(artwork)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setStyle(mediaStyle)
            .addAction(previousAction)
            .addAction(playPauseAction)
            .addAction(nextAction)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setAutoCancel(false)
            .build()
        
        // Cancel the existing notification first to force Android to refresh the artwork
        // This prevents Android from caching the old album art
        notificationManager.cancel(CUSTOM_NOTIFICATION_ID)
        
        // Post the new notification immediately after canceling
        notificationManager.notify(CUSTOM_NOTIFICATION_ID, notification)
        android.util.Log.d("CustomNotification", "Notification posted (refreshed)")
    }
    
    private fun createMediaAction(action: String, icon: Int): NotificationCompat.Action {
        val intent = Intent("com.example.music_player.MEDIA_CONTROL").apply {
            setPackage(context.packageName)
            putExtra("action", action)
        }
        
        val requestCode = when(action) {
            "previous" -> 101
            "play"     -> 102
            "pause"    -> 103
            "next"     -> 104
            else       -> action.hashCode()
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        android.util.Log.d("CustomNotification", "Created action: $action with requestCode: $requestCode")
        return NotificationCompat.Action.Builder(icon, action, pendingIntent).build()
    }
    
    private fun loadArtwork(path: String?): Bitmap? {
        return try {
            if (path != null && File(path).exists()) {
                BitmapFactory.decodeFile(path)
            } else {
                null
            }
        } catch (e: Exception) {
            android.util.Log.e("CustomNotification", "Error loading artwork: $e")
            null
        }
    }
    
    fun cancelNotification() {
        notificationManager.cancel(CUSTOM_NOTIFICATION_ID)
    }
}