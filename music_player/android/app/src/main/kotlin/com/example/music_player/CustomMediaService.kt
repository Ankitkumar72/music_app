package com.example.music_player

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat

class CustomMediaService : Service() {
    
    private lateinit var mediaSession: MediaSessionCompat
    private val binder = LocalBinder()
    
    inner class LocalBinder : Binder() {
        fun getService(): CustomMediaService = this@CustomMediaService
    }
    
    override fun onCreate() {
        super.onCreate()
        
        // Create MediaSession
        mediaSession = MediaSessionCompat(this, "CustomMediaService").apply {
            setFlags(MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS or
                     MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS)
            
            val stateBuilder = PlaybackStateCompat.Builder()
                .setActions(
                    PlaybackStateCompat.ACTION_PLAY or
                    PlaybackStateCompat.ACTION_PAUSE or
                    PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                    PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                    PlaybackStateCompat.ACTION_SEEK_TO
                )
            setPlaybackState(stateBuilder.build())
            
            // Set callback for media button events
            setCallback(object : MediaSessionCompat.Callback() {
                override fun onPlay() {
                    sendMediaAction("play")
                }
                
                override fun onPause() {
                    sendMediaAction("pause")
                }
                
                override fun onSkipToNext() {
                    sendMediaAction("next")
                }
                
                override fun onSkipToPrevious() {
                    sendMediaAction("previous")
                }
            })
            
            isActive = true
        }
    }
    
    private fun sendMediaAction(action: String) {
        val intent = Intent("com.example.music_player.MEDIA_CONTROL").apply {
            putExtra("action", action)
        }
        sendBroadcast(intent)
    }
    
    fun getSessionToken() = mediaSession.sessionToken
    
    fun updatePlaybackState(isPlaying: Boolean) {
        val state = if (isPlaying) {
            PlaybackStateCompat.STATE_PLAYING
        } else {
            PlaybackStateCompat.STATE_PAUSED
        }
        
        val stateBuilder = PlaybackStateCompat.Builder()
            .setState(state, 0, 1f)
            .setActions(
                PlaybackStateCompat.ACTION_PLAY or
                PlaybackStateCompat.ACTION_PAUSE or
                PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                PlaybackStateCompat.ACTION_SEEK_TO
            )
        
        mediaSession.setPlaybackState(stateBuilder.build())
    }
    
    override fun onBind(intent: Intent?): IBinder = binder
    
    override fun onDestroy() {
        mediaSession.isActive = false
        mediaSession.release()
        super.onDestroy()
    }
}
