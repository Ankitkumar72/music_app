import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  
  AudioPlayerHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    
    // Listen for index changes to update the current media item in the notification
    _player.currentIndexStream.listen((index) async {
      if (index != null && queue.value.isNotEmpty && index < queue.value.length) {
        final item = queue.value[index];
        
        // Force Android to refresh artwork by recreating MediaItem with timestamp
        final updatedItem = MediaItem(
          id: item.id,
          title: item.title,
          artist: item.artist,
          album: item.album,
          artUri: item.artUri,
          extras: {'timestamp': DateTime.now().millisecondsSinceEpoch},
        );
        
        mediaItem.add(updatedItem);
        debugPrint('🎵 Notification updated: ${item.title} - Artwork: ${item.artUri != null ? "YES (${item.artUri})" : "NO"}');
      }
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2], // Previous, Play/Pause, Next
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState] ?? AudioProcessingState.idle,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
    );
  }

  Future<void> playPlaylist(List<MediaItem> items, {int initialIndex = 0}) async {
    queue.add(items);
    
    final audioSources = items.map((item) => AudioSource.uri(
      Uri.parse(item.id),
      tag: item,
    )).toList();
    
    // Use setAudioSources (plural) instead of deprecated ConcatenatingAudioSource
    await _player.setAudioSources(audioSources, initialIndex: initialIndex);
    
    if (items.isNotEmpty && initialIndex < items.length) {
      mediaItem.add(items[initialIndex]);
    }
    
    play();
  }

  // FIX: Changed return type to Future<void> to match the base class requirement
  @override
  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    // Check if there's a next track before attempting to skip
    if (_player.hasNext) {
      await _player.seekToNext();
      // Auto-play the next song even if current was paused
      if (!_player.playing) {
        await _player.play();
      }
    }
  }

  @override
  Future<void> skipToPrevious() async {
    // Check if there's a previous track before attempting to skip
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      // Auto-play the previous song even if current was paused
      if (!_player.playing) {
        await _player.play();
      }
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  AudioPlayer get player => _player;
}