package com.example.music_player

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import android.support.v4.media.session.MediaSessionCompat

class CustomMediaService : Service() {
    private val binder = LocalBinder()
    private lateinit var mediaSession: MediaSessionCompat
    private lateinit var notificationManager: CustomNotificationManager

    inner class LocalBinder : Binder() {
        fun getService(): CustomMediaService = this@CustomMediaService
    }

    override fun onCreate() {
        super.onCreate()
        mediaSession = MediaSessionCompat(this, "CustomMediaService")
        notificationManager = CustomNotificationManager(this)
        
        mediaSession.setCallback(object : MediaSessionCompat.Callback() {
            override fun onPlay() { sendMediaAction("play") }
            override fun onPause() { sendMediaAction("pause") }
            override fun onSkipToNext() { sendMediaAction("next") }
            override fun onSkipToPrevious() { sendMediaAction("previous") }
        })
        mediaSession.isActive = true
    }
    
    private fun sendMediaAction(action: String) {
        val intent = Intent("com.example.music_player.MEDIA_CONTROL").apply {
            putExtra("action", action)
        }
        sendBroadcast(intent)
    }

    override fun onBind(intent: Intent?): IBinder = binder

    fun updateNotification(title: String, artist: String, artPath: String?, isPlaying: Boolean) {
        android.util.Log.d("CustomMediaService", "updateNotification called: $title, path: $artPath")
        
        // 1. Decode Bitmap
        var artwork: android.graphics.Bitmap? = null
        if (!artPath.isNullOrEmpty()) {
            try {
                // Check if file exists to avoid decoding errors
                val file = java.io.File(artPath)
                if (file.exists()) {
                    artwork = android.graphics.BitmapFactory.decodeFile(artPath)
                    android.util.Log.d("CustomMediaService", "✅ Decoded bitmap: ${artwork?.width}x${artwork?.height}")
                } else {
                     android.util.Log.e("CustomMediaService", "❌ File does not exist: $artPath")
                }
            } catch (e: Exception) {
                android.util.Log.e("CustomMediaService", "❌ Error decoding bitmap: $e")
            }
        }

        // 2. Update MediaSession Metadata (CRITICAL for lock screen / system UI)
        val metadataBuilder = android.support.v4.media.MediaMetadataCompat.Builder()
            .putString(android.support.v4.media.MediaMetadataCompat.METADATA_KEY_TITLE, title)
            .putString(android.support.v4.media.MediaMetadataCompat.METADATA_KEY_ARTIST, artist)
        
        if (artwork != null) {
            metadataBuilder.putBitmap(android.support.v4.media.MediaMetadataCompat.METADATA_KEY_ALBUM_ART, artwork)
            metadataBuilder.putBitmap(android.support.v4.media.MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON, artwork)
        }
        
        mediaSession.setMetadata(metadataBuilder.build())

        // 3. Update Playback State
        val state = if (isPlaying) {
            android.support.v4.media.session.PlaybackStateCompat.STATE_PLAYING
        } else {
            android.support.v4.media.session.PlaybackStateCompat.STATE_PAUSED
        }
        
        mediaSession.setPlaybackState(
            android.support.v4.media.session.PlaybackStateCompat.Builder()
                .setActions(
                    android.support.v4.media.session.PlaybackStateCompat.ACTION_PLAY or
                    android.support.v4.media.session.PlaybackStateCompat.ACTION_PAUSE or
                    android.support.v4.media.session.PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                    android.support.v4.media.session.PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                    android.support.v4.media.session.PlaybackStateCompat.ACTION_SEEK_TO
                )
                .setState(state, android.support.v4.media.session.PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN, 1.0f)
                .build()
        )

        // 4. Build and Show Notification
        val notification = notificationManager.buildNotification(
            title, artist, artwork, isPlaying, mediaSession
        )
        
        if (isPlaying) {
            startForeground(888, notification)
        } else {
            stopForeground(false)
            val manager = getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager
            manager.notify(888, notification)
        }
    }

    override fun onDestroy() {
        mediaSession.isActive = false
        mediaSession.release()
        super.onDestroy()
    }
}
