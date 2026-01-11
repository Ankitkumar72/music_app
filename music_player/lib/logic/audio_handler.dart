import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

// Global audio handler instance - nullable until initialized
AudioPlayerHandler? audioHandler;

/// AudioPlayerHandler wraps just_audio with audio_service for background playback
/// and notification controls.
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  
  // Track current playlist for navigation
  List<MediaItem> _playlist = [];
  int _currentIndex = 0;

  AudioPlayerHandler() {
    _init();
  }

  Future<void> _init() async {
    // Broadcast playback state changes
    _player.playbackEventStream.listen((event) {
      _broadcastState();
    });

    // Broadcast playing state
    _player.playingStream.listen((playing) {
      _broadcastState();
    });

    // Handle song completion and advancement
    _player.currentIndexStream.listen((index) {
      if (index != null && index != _currentIndex) {
        _currentIndex = index;
        if (_playlist.isNotEmpty && index < _playlist.length) {
          mediaItem.add(_playlist[index]);
        }
      }
    });

    // Handle processing state for queue advancement
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
      }
    });
  }

  AudioPlayer get player => _player;
  int get currentIndex => _currentIndex;

  /// Load and play a playlist starting at the given index
  Future<void> loadPlaylist(List<MediaItem> items, int startIndex) async {
    _playlist = items;
    _currentIndex = startIndex;

    // Update the queue
    queue.add(_playlist);

    // Create audio sources from media items
    final audioSources = items.map((item) {
      return AudioSource.file(item.id); // item.id contains the file path
    }).toList();

    try {
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: audioSources),
        initialIndex: startIndex,
      );
      
      // Set initial media item
      if (_playlist.isNotEmpty) {
        mediaItem.add(_playlist[startIndex]);
      }
      
      await _player.play();
    } catch (e) {
      debugPrint('Error loading playlist: $e');
    }
  }

  /// Update the current media item (for artwork updates etc.)
  @override
  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
      _currentIndex = _player.currentIndex ?? _currentIndex;
      if (_playlist.isNotEmpty && _currentIndex < _playlist.length) {
        mediaItem.add(_playlist[_currentIndex]);
      }
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      _currentIndex = _player.currentIndex ?? _currentIndex;
      if (_playlist.isNotEmpty && _currentIndex < _playlist.length) {
        mediaItem.add(_playlist[_currentIndex]);
      }
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _playlist.length) {
      await _player.seek(Duration.zero, index: index);
      _currentIndex = index;
      mediaItem.add(_playlist[index]);
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(
      shuffleMode == AudioServiceShuffleMode.all,
    );
  }

  /// Broadcast current playback state to notification and listeners
  void _broadcastState() {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _mapProcessingState(_player.processingState),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    ));
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }
}
