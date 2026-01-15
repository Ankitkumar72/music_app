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
import android.support.v4.media.session.MediaSessionCompat

class CustomNotificationManager(private val context: Context) {
    private val channelId = "music_player_channel"
    private val notificationId = 888

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Music Playback",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Controls for music playback"
                setShowBadge(false)
            }
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    fun buildNotification(
        title: String,
        artist: String,
        artworkBitmap: Bitmap?,
        isPlaying: Boolean,
        mediaSession: MediaSessionCompat
    ): Notification {
        // Bitmap is now passed in directly
        if (artworkBitmap != null) {
            android.util.Log.d("CustomNotification", "✅ Using provided bitmap: ${artworkBitmap.width}x${artworkBitmap.height}")
        } else {
             android.util.Log.d("CustomNotification", "⚠️ No artwork bitmap provided")
        }

        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent, PendingIntent.FLAG_IMMUTABLE
        )

        // Using system icons for simplicity as requested
        val playPauseIcon = if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play

        return NotificationCompat.Builder(context, channelId)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setSmallIcon(android.R.drawable.ic_media_play) // TODO: Replace with app icon if available
            .setLargeIcon(artworkBitmap)
            .setContentTitle(title)
            .setContentText(artist)
            .setContentIntent(pendingIntent)
            .setOngoing(isPlaying)
            .setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setMediaSession(mediaSession.sessionToken)
                    .setShowActionsInCompactView(0, 1, 2)
            )
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .addAction(android.R.drawable.ic_media_previous, "Previous", createPendingIntent("previous"))
            .addAction(playPauseIcon, if (isPlaying) "Pause" else "Play", createPendingIntent(if (isPlaying) "pause" else "play"))
            .addAction(android.R.drawable.ic_media_next, "Next", createPendingIntent("next"))
            .build()
    }

    private fun createPendingIntent(action: String): PendingIntent {
        val intent = Intent("com.example.music_player.MEDIA_CONTROL").apply {
            setPackage(context.packageName)
            putExtra("action", action)
        }
        return PendingIntent.getBroadcast(
            context, action.hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}