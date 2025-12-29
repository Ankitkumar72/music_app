import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hive/hive.dart';

import 'models/song_data.dart';

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

  late Box<PlaylistData> _playlistBox;
  bool _isHiveReady = false; // Guard flag for Hive

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
    _initHive();

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

  // ================= HIVE =================
  Future<void> _initHive() async {
    try {
      _playlistBox = await Hive.openBox<PlaylistData>('playlists');
      _isHiveReady = true;
      debugPrint("Hive initialized successfully.");
      // If songs were already fetched before Hive opened, sync now
      if (_songs.isNotEmpty) {
        _syncWithHive();
      }
    } catch (e) {
      debugPrint("Hive init error: $e");
    }
  }

  void _syncWithHive() {
    if (!_isHiveReady) return;

    debugPrint("Syncing Hive data with ${_songs.length} songs...");
    for (final data in _playlistBox.values) {
      final matchedSongs = _songs
          .where((s) => data.songIds.contains(s.id))
          .toList();

      _playlists[data.name] = matchedSongs;

      if (data.name == "Liked") {
        _likedSongs
          ..clear()
          ..addAll(matchedSongs);
      }
    }
    notifyListeners();
  }

  void _savePlaylist(String name) {
    if (!_isHiveReady) return;
    final songIds = _playlists[name]?.map((song) => song.id).toList() ?? [];
    _playlistBox.put(name, PlaylistData(name: name, songIds: songIds));
  }

  // ================= FETCH SONGS (UPDATED PERMISSION LOGIC) =================
  Future<void> fetchSongs() async {
    if (_songs.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Step 3 Fix: Explicitly check for Android 13+ (READ_MEDIA_AUDIO)
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

        // Sync Hive ONLY if songs were successfully loaded
        if (_isHiveReady) {
          _syncWithHive();
        }
      } else {
        debugPrint("Permissions denied in Release mode.");
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
    _savePlaylist("Liked");
    notifyListeners();
  }

  void addToLikedPlaylist(SongModel song) {
    if (!isLiked(song)) {
      _likedSongs.add(song);
      _playlists["Liked"]?.add(song);
      _savePlaylist("Liked");
      notifyListeners();
    }
  }

  // ================= PLAYLIST MANAGEMENT =================
  void createPlaylist(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && !_playlists.containsKey(trimmed)) {
      _playlists[trimmed] = [];
      _savePlaylist(trimmed);
      notifyListeners();
    }
  }

  void renamePlaylist(String oldName, String newName) {
    final trimmedNew = newName.trim();
    if (oldName == "Liked") return;

    if (_playlists.containsKey(oldName) &&
        !_playlists.containsKey(trimmedNew) &&
        trimmedNew.isNotEmpty) {
      _playlists[trimmedNew] = _playlists.remove(oldName)!;
      _playlistBox.delete(oldName);
      _savePlaylist(trimmedNew);
      notifyListeners();
    }
  }

  void deletePlaylist(String name) {
    if (name == "Liked") return;
    _playlists.remove(name);
    _playlistBox.delete(name);
    notifyListeners();
  }

  void addToPlaylist(String name, SongModel song) {
    if (_playlists.containsKey(name) &&
        !_playlists[name]!.any((s) => s.id == song.id)) {
      _playlists[name]!.add(song);
      if (name == "Liked" && !isLiked(song)) {
        _likedSongs.add(song);
      }
      _savePlaylist(name);
      notifyListeners();
    }
  }

  void removeFromPlaylist(String name, int songId) {
    if (_playlists.containsKey(name)) {
      _playlists[name]!.removeWhere((s) => s.id == songId);
      if (name == "Liked") {
        _likedSongs.removeWhere((s) => s.id == songId);
      }
      _savePlaylist(name);
      notifyListeners();
    }
  }

  // ================= PLAYBACK (URI FIX) =================
  Future<void> playSong(int index) async {
    if (index < 0 || index >= _songs.length) return;

    try {
      if (_audioPlayer.audioSource == null) {
        final playlist = ConcatenatingAudioSource(
          children: _songs
              .map(
                (song) => AudioSource.uri(Uri.file(song.data)),
              ) // Fixed for local files
              .toList(),
        );

        await _audioPlayer.setAudioSource(
          playlist,
          initialIndex: index,
          initialPosition: Duration.zero,
        );
      } else if (_currentIndex != index) {
        await _audioPlayer.seek(Duration.zero, index: index);
      }

      _audioPlayer.play();
    } catch (e) {
      debugPrint("Playback error: $e");
    }
  }

  void togglePlay() {
    _audioPlayer.playing ? _audioPlayer.pause() : _audioPlayer.play();
    notifyListeners();
  }

  // ================= NAVIGATION =================
  void playNext() => _audioPlayer.hasNext ? _audioPlayer.seekToNext() : null;

  void playPrevious() =>
      _audioPlayer.hasPrevious ? _audioPlayer.seekToPrevious() : null;

  // ================= SHUFFLE / REPEAT =================
  Future<void> toggleShuffle() async {
    _isShuffleModeEnabled = !_isShuffleModeEnabled;
    if (_isShuffleModeEnabled) await _audioPlayer.shuffle();
    await _audioPlayer.setShuffleModeEnabled(_isShuffleModeEnabled);
    notifyListeners();
  }

  void toggleRepeat() {
    _loopMode = _loopMode == LoopMode.off
        ? LoopMode.all
        : _loopMode == LoopMode.all
        ? LoopMode.one
        : LoopMode.off;

    _audioPlayer.setLoopMode(_loopMode);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
