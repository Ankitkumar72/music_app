import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';

class MusicProvider extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<SongModel> _songs = [];
  final List<SongModel> _likedSongs = [];

  final Map<String, List<SongModel>> _playlists = {"Liked": []};

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
      if (index != null && _currentIndex != index) {
        _currentIndex = index;
        notifyListeners();
      }
    });
  }

  // ================= FETCH SONGS (UPDATED FOR ANDROID 13+) =================
  Future<void> fetchSongs() async {
    if (_songs.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Step 3 Fix: Explicitly check and request permissions for Release builds.
      // on_audio_query's permissionsStatus() checks for READ_MEDIA_AUDIO on Android 13+
      // and READ_EXTERNAL_STORAGE on older versions automatically.
      bool hasPermission = await _audioQuery.permissionsStatus();

      if (!hasPermission) {
        hasPermission = await _audioQuery.permissionsRequest();
      }

      if (hasPermission) {
        _songs = await _audioQuery.querySongs(
          ignoreCase: true,
          orderType: OrderType.ASC_OR_SMALLER,
          sortType: SongSortType.TITLE,
          uriType: UriType.EXTERNAL,
        );
      } else {
        debugPrint("Storage/Media permissions were denied by the user.");
      }
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
      _playlists["Liked"]?.removeWhere((s) => s.id == song.id);
    } else {
      _likedSongs.add(song);
      _playlists["Liked"]?.add(song);
    }
    notifyListeners();
  }

  void addToLikedPlaylist(SongModel song) {
    if (!isLiked(song)) {
      _likedSongs.add(song);
      _playlists["Liked"]?.add(song);
      notifyListeners();
    }
  }

  // ================= PLAYLIST MANAGEMENT =================
  void createPlaylist(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty && !_playlists.containsKey(trimmedName)) {
      _playlists[trimmedName] = [];
      notifyListeners();
    }
  }

  void renamePlaylist(String oldName, String newName) {
    final trimmedNew = newName.trim();
    if (_playlists.containsKey(oldName) &&
        !_playlists.containsKey(trimmedNew) &&
        oldName != "Liked" &&
        trimmedNew.isNotEmpty) {
      _playlists[trimmedNew] = _playlists.remove(oldName)!;
      notifyListeners();
    }
  }

  void deletePlaylist(String name) {
    if (name != "Liked") {
      _playlists.remove(name);
      notifyListeners();
    }
  }

  void addToPlaylist(String name, SongModel song) {
    if (_playlists.containsKey(name)) {
      if (!_playlists[name]!.any((s) => s.id == song.id)) {
        _playlists[name]!.add(song);

        if (name == "Liked" && !isLiked(song)) {
          _likedSongs.add(song);
        }

        notifyListeners();
      }
    }
  }

  void removeFromPlaylist(String name, int songId) {
    if (_playlists.containsKey(name)) {
      _playlists[name]!.removeWhere((s) => s.id == songId);

      if (name == "Liked") {
        _likedSongs.removeWhere((s) => s.id == songId);
      }

      notifyListeners();
    }
  }

  // ================= PLAYBACK =================
  Future<void> playSong(int index) async {
    if (index < 0 || index >= _songs.length) return;

    try {
      if (_audioPlayer.audioSource == null) {
        final playlist = ConcatenatingAudioSource(
          children: _songs.map((song) {
            return AudioSource.uri(Uri.parse(song.data));
          }).toList(),
        );

        await _audioPlayer.setAudioSource(
          playlist,
          initialIndex: index,
          initialPosition: Duration.zero,
        );
      } else {
        if (_currentIndex != index) {
          await _audioPlayer.seek(Duration.zero, index: index);
        }
      }

      _audioPlayer.play();
    } catch (e) {
      debugPrint("Playback error: $e");
    }
  }

  void togglePlay() {
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
    notifyListeners();
  }

  // ================= NAVIGATION =================
  void playNext() => _audioPlayer.hasNext ? _audioPlayer.seekToNext() : null;
  void playPrevious() =>
      _audioPlayer.hasPrevious ? _audioPlayer.seekToPrevious() : null;

  // ================= SHUFFLE / REPEAT =================
  void toggleShuffle() async {
    _isShuffleModeEnabled = !_isShuffleModeEnabled;
    if (_isShuffleModeEnabled) await _audioPlayer.shuffle();
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
