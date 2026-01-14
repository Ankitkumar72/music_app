import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayerHandler() {
    // 1. Sync playback state
    _player.playbackEventStream.listen(
      (event) => playbackState.add(_transformEvent(event)),
      onError: (Object e, StackTrace st) {
        debugPrint('Playback error: $e');
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
        ));
      },
    );

    // 2. Listen to track changes via sequenceStateStream
    // This handles natural track completion, manual skips, and queue jumps
    _player.sequenceStateStream.listen((state) {
      if (state?.currentIndex != null) {
        final index = state!.currentIndex!;
        if (index < queue.value.length) {
          mediaItem.add(queue.value[index]);
        }
      }
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      // Keep controls for proper MediaSession integration with MediaButtonReceiver
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
      androidCompactActionIndices: const [0, 1, 2],
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

    // Set source - the sequenceStateStream listener added in constructor
    // will automatically update mediaItem.add() once the player loads.
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: initialIndex,
    );
    
    play();
  }

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
    if (_player.hasNext) {
      await _player.seekToNext();
      if (!_player.playing) await _player.play();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      if (!_player.playing) await _player.play();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < queue.value.length) {
      await _player.seek(Duration.zero, index: index);
      if (!_player.playing) await _player.play();
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.dispose(); // Proper disposal of resources
    await super.stop();
  }

  AudioPlayer get player => _player;
}