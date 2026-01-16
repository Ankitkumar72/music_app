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
    
    // Cache for artwork to avoid re-decoding
    private var cachedArtwork: android.graphics.Bitmap? = null
    private var cachedArtPath: String? = null
    private var lastTitle: String = ""
    private var lastArtist: String = ""

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
        android.util.Log.d("CustomMediaService", "updateNotification called: $title, isPlaying: $isPlaying")
        
        // Check if only playback state changed (fast path - no bitmap decoding needed)
        val isSameSong = title == lastTitle && artist == lastArtist && artPath == cachedArtPath
        
        // Only decode bitmap if artwork path changed
        if (!isSameSong || cachedArtwork == null) {
            cachedArtwork = null
            cachedArtPath = artPath
            lastTitle = title
            lastArtist = artist
            
            if (!artPath.isNullOrEmpty()) {
                try {
                    val file = java.io.File(artPath)
                    if (file.exists()) {
                        cachedArtwork = android.graphics.BitmapFactory.decodeFile(artPath)
                        android.util.Log.d("CustomMediaService", "✅ Decoded NEW bitmap: ${cachedArtwork?.width}x${cachedArtwork?.height}")
                    } else {
                        android.util.Log.e("CustomMediaService", "❌ File does not exist: $artPath")
                    }
                } catch (e: Exception) {
                    android.util.Log.e("CustomMediaService", "❌ Error decoding bitmap: $e")
                }
            }
        } else {
            android.util.Log.d("CustomMediaService", "⚡ Fast path: reusing cached bitmap")
        }

        // Update MediaSession Metadata (only if song changed)
        if (!isSameSong) {
            val metadataBuilder = android.support.v4.media.MediaMetadataCompat.Builder()
                .putString(android.support.v4.media.MediaMetadataCompat.METADATA_KEY_TITLE, title)
                .putString(android.support.v4.media.MediaMetadataCompat.METADATA_KEY_ARTIST, artist)
            
            if (cachedArtwork != null) {
                metadataBuilder.putBitmap(android.support.v4.media.MediaMetadataCompat.METADATA_KEY_ALBUM_ART, cachedArtwork)
                metadataBuilder.putBitmap(android.support.v4.media.MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON, cachedArtwork)
            }
            
            mediaSession.setMetadata(metadataBuilder.build())
        }

        // Always update playback state (this is fast)
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

        // Build and Show Notification (uses cached bitmap)
        val notification = notificationManager.buildNotification(
            title, artist, cachedArtwork, isPlaying, mediaSession
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
