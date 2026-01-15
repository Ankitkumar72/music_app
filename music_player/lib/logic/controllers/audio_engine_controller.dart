import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../Models/song_data.dart';
import '../audio_handler.dart';

/// 🎧 AudioEngineController (Playback Brain)
///
/// Purpose:
/// 🔹 Decides WHAT to play
/// 🔹 Builds queues
/// 🔹 Handles skip logic
/// 🔹 Manages Fallback Player vs AudioHandler
///
/// Rules:
/// ✅ Creates queue MediaItems (initial only)
/// ❌ Never updates notification
/// ❌ Never updates artwork later
class AudioEngineController {
  final AudioPlayerHandler? _handler;
  
  // Fallback player for when audio_service isn't initialized
  // We own this now.
  final AudioPlayer _fallbackPlayer = AudioPlayer();
  
  // Lock to prevent media button race conditions during load
  bool _isQueueBuilding = false;

  AudioEngineController(this._handler);

  // Use AudioService's audio handler player if available
  AudioPlayer get player => _handler?.player ?? _fallbackPlayer;
  
  bool get isQueueBuilding => _isQueueBuilding;

  // ================= PLAYBACK COMMANDS =================
  
  Future<void> play() async {
    if (_handler != null) {
      await _handler!.play();
    } else {
      await _fallbackPlayer.play();
    }
  }

  Future<void> pause() async {
    if (_handler != null) {
      await _handler!.pause();
    } else {
      await _fallbackPlayer.pause();
    }
  }

  Future<void> stop() async {
    if (_handler != null) {
      await _handler!.stop();
    } else {
      await _fallbackPlayer.stop();
    }
  }

  Future<void> seek(Duration position) async {
    if (_handler != null) {
      await _handler!.seek(position);
    } else {
      await _fallbackPlayer.seek(position);
    }
  }

  Future<void> skipToNext() async {
    if (_handler != null) {
      await _handler!.skipToNext();
      // Note: We DO NOT update currentIndex here. 
      // MusicProvider/MetadataController listens to streams.
    } else if (_fallbackPlayer.hasNext) {
      await _fallbackPlayer.seekToNext();
    }
  }

  Future<void> skipToPrevious() async {
    if (_handler != null) {
      await _handler!.skipToPrevious();
    } else if (_fallbackPlayer.hasPrevious) {
      await _fallbackPlayer.seekToPrevious();
    }
  }

  void setShuffleMode(bool enabled) {
    if (_handler != null) {
      _handler!.player.setShuffleModeEnabled(enabled);
    } else {
      _fallbackPlayer.setShuffleModeEnabled(enabled);
    }
  }

  void setLoopMode(LoopMode mode) {
    if (_handler != null) {
      _handler!.player.setLoopMode(mode);
    } else {
      _fallbackPlayer.setLoopMode(mode);
    }
  }

  // ================= QUEUE MANAGEMENT =================

  /// Builds the queue and starts playback.
  /// 
  /// ⚠️ IMPORTANT: This method creates the INITIAL MediaItems.
  /// It intentionally does NOT set artwork to avoid blocking the UI.
  /// MetadataController will pick up the playing item and fill in details.
  Future<void> playPlaylist(List<SongData> sourceList, int index) async {
    if (sourceList.isEmpty || index < 0 || index >= sourceList.length) return;

    debugPrint("🎧 [AudioEngine] playPlaylist called. Handler available: ${_handler != null}");

    if (_handler != null) {
      try {
        _isQueueBuilding = true;
        
        final mediaItems = sourceList.map((song) {
          // Minimal metadata for queue construction
          return MediaItem(
            id: song.data,
            title: song.title,
            artist: song.artist.isEmpty ? 'Unknown Artist' : song.artist,
            album: song.artist.isEmpty ? 'Unknown Album' : song.artist,
            // ❌ NO ARTWORK HERE - delegated to MetadataController
            artUri: null, 
          );
        }).toList();

        await _handler!.playPlaylist(mediaItems, initialIndex: index);
        
        debugPrint('✅ [AudioEngine] Playlist started via audio_service');
      } catch (e) {
        debugPrint('❌ [AudioEngine] Error playing via service: $e');
        await _fallbackPlayback(sourceList, index);
      } finally {
        _isQueueBuilding = false;
      }
    } else {
      await _fallbackPlayback(sourceList, index);
    }
  }

  Future<void> _fallbackPlayback(List<SongData> sourceList, int index) async {
    debugPrint('⚠️ [AudioEngine] Using fallback audio player');
    try {
      List<AudioSource> audioSources = sourceList.map((song) {
        return AudioSource.file(song.data);
      }).toList();

      await _fallbackPlayer.setAudioSource(
        ConcatenatingAudioSource(children: audioSources),
        initialIndex: index,
      );
      await _fallbackPlayer.play();
    } catch (e) {
      debugPrint('❌ [AudioEngine] Fallback error: $e');
    }
  }

  void dispose() {
    _fallbackPlayer.dispose();
  }
}
