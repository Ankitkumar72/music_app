import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';

class MusicProvider extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<SongModel> _songs = [];

  // Core collections
  final List<SongModel> _likedSongs = [];

  // Dynamic playlists (user-created)
  final Map<String, List<SongModel>> _playlists = {
    "Liked Songs": [], // Protected default playlist
  };

  int _currentIndex = -1;
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _isShuffleModeEnabled = false;
  LoopMode _loopMode = LoopMode.off;

  // ================= GETTERS =================
  List<SongModel> get songs => _songs;
  List<SongModel> get likedSongs => _likedSongs;
  Map<String, List<SongModel>> get allPlaylists => _playlists;
  List<String> get playlistNames => _playlists.keys.toList();

  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  bool get isShuffleModeEnabled => _isShuffleModeEnabled;
  LoopMode get loopMode => _loopMode;
  AudioPlayer get player => _audioPlayer;

  SongModel? get currentSong =>
      (_currentIndex >= 0 && _currentIndex < _songs.length)
      ? _songs[_currentIndex]
      : null;

  // ================= CONSTRUCTOR =================
  MusicProvider() {
    _audioPlayer.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null) {
        _currentIndex = index;
        notifyListeners();
      }
    });
  }

  // ================= FETCH SONGS =================
  Future<void> fetchSongs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _songs = await _audioQuery.querySongs(
        ignoreCase: true,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
    } catch (e) {
      debugPrint("Error fetching songs: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // ================= LIKE LOGIC =================
  bool isLiked(SongModel song) => _likedSongs.any((s) => s.id == song.id);

  void toggleLike(SongModel song) {
    if (isLiked(song)) {
      _likedSongs.removeWhere((s) => s.id == song.id);
      _playlists["Liked Songs"]!.removeWhere((s) => s.id == song.id);
    } else {
      _likedSongs.add(song);
      _playlists["Liked Songs"]!.add(song);
    }
    notifyListeners();
  }

  // ================= PLAYLIST MANAGEMENT =================
  void createPlaylist(String name) {
    if (!_playlists.containsKey(name)) {
      _playlists[name] = [];
      notifyListeners();
    }
  }

  void renamePlaylist(String oldName, String newName) {
    if (_playlists.containsKey(oldName) &&
        !_playlists.containsKey(newName) &&
        oldName != "Liked Songs") {
      _playlists[newName] = _playlists.remove(oldName)!;
      notifyListeners();
    }
  }

  void deletePlaylist(String name) {
    if (name != "Liked Songs") {
      _playlists.remove(name);
      notifyListeners();
    }
  }

  void addToPlaylist(String name, SongModel song) {
    if (_playlists.containsKey(name)) {
      if (!_playlists[name]!.any((s) => s.id == song.id)) {
        _playlists[name]!.add(song);
        notifyListeners();
      }
    }
  }

  void removeFromPlaylist(String name, int songId) {
    if (_playlists.containsKey(name)) {
      _playlists[name]!.removeWhere((s) => s.id == songId);
      notifyListeners();
    }
  }

  // ================= PLAYBACK =================
  Future<void> playSong(int index) async {
    if (index < 0 || index >= _songs.length) return;

    try {
      if (_audioPlayer.audioSource == null) {
        await _audioPlayer.setAudioSources(
          _songs.map((song) => AudioSource.file(song.data)).toList(),
          initialIndex: index,
          initialPosition: Duration.zero,
        );
      } else {
        await _audioPlayer.seek(Duration.zero, index: index);
      }

      _audioPlayer.play();
    } catch (e) {
      debugPrint("Playback error: $e");
    }
  }

  void togglePlay() {
    _audioPlayer.playing ? _audioPlayer.pause() : _audioPlayer.play();
  }

  // ================= NAVIGATION =================
  void playNext() {
    if (_audioPlayer.hasNext) {
      _audioPlayer.seekToNext();
    }
  }

  void playPrevious() {
    if (_audioPlayer.hasPrevious) {
      _audioPlayer.seekToPrevious();
    }
  }

  // ================= SHUFFLE / REPEAT =================
  void toggleShuffle() async {
    _isShuffleModeEnabled = !_isShuffleModeEnabled;

    if (_isShuffleModeEnabled) {
      await _audioPlayer.shuffle();
    }

    await _audioPlayer.setShuffleModeEnabled(_isShuffleModeEnabled);
    notifyListeners();
  }

  void toggleRepeat() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.all;
    } else if (_loopMode == LoopMode.all) {
      _loopMode = LoopMode.one;
    } else {
      _loopMode = LoopMode.off;
    }

    _audioPlayer.setLoopMode(_loopMode);
    notifyListeners();
  }

  // ================= CLEANUP =================
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
