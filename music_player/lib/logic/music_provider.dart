import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hive/hive.dart';

import 'models/song_data.dart';

class MusicProvider extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ================= SONG LISTS =================
  List<SongModel> _songs = [];
  List<SongModel> _allSongs = [];
  final List<SongModel> _likedSongs = [];
  final Map<String, List<SongModel>> _playlists = {"Liked": []};

  // ================= SYNC DATA =================
  Map<int, int> _playCounts = {}; // songId : count
  List<int> _recentIds = []; // recently played song IDs
  String _activeCategory = "✨ For You";

  // ================= STATE =================
  int _currentIndex = -1;
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _isShuffleModeEnabled = false;
  LoopMode _loopMode = LoopMode.off;

  // ================= HIVE =================
  late Box<PlaylistData> _playlistBox;
  late Box _statsBox;
  bool _isHiveReady = false;

  // ================= GETTERS =================
  List<SongModel> get songs => _songs;
  List<SongModel> get allSongs => _allSongs;
  List<SongModel> get likedSongs => _likedSongs;
  Map<String, List<SongModel>> get allPlaylists => _playlists;
  List<String> get playlistNames => _playlists.keys.toList();
  String get activeCategory => _activeCategory;

  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  bool get isShuffleModeEnabled => _isShuffleModeEnabled;
  LoopMode get loopMode => _loopMode;
  AudioPlayer get player => _audioPlayer;

  SongModel? get currentSong =>
      (_currentIndex >= 0 && _currentIndex < _allSongs.length)
      ? _allSongs[_currentIndex]
      : null;

  // ================= HOME LOGIC =================
  // 1. Daily Mix: Songs played 3 or more times
  List<SongModel> get dailyMixSongs =>
      _songs.where((s) => (_playCounts[s.id] ?? 0) >= 3).toList();

  // 2. Discovery: Returns 10 random songs from the library
  List<SongModel> get discoverySongs {
    final shuffled = List<SongModel>.from(_songs)..shuffle();
    return shuffled.take(10).toList();
  }

  // 3. Jump Back In: Recently played songs (last 10)
  List<SongModel> get recentlyPlayed {
    final result = <SongModel>[];
    for (final id in _recentIds) {
      try {
        result.add(_songs.firstWhere((s) => s.id == id));
        if (result.length >= 10) break;
      } catch (_) {}
    }
    return result;
  }

  // ================= CONSTRUCTOR =================
  MusicProvider() {
    _initHive();

    // PLAY / PAUSE STATE
    _audioPlayer.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    // TRACK CHANGE
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && _currentIndex != index) {
        _currentIndex = index;
        _handleSongChange(index);
        notifyListeners();
      }
    });

    // HANDLE PLAYBACK COMPLETION
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _currentIndex = -1;
        _isPlaying = false;
        notifyListeners();
      }
    });
  }

  // ================= HIVE INIT =================
  Future<void> _initHive() async {
    try {
      _playlistBox = await Hive.openBox<PlaylistData>('playlists');
      _statsBox = await Hive.openBox('stats');
      _isHiveReady = true;

      _playCounts = Map<int, int>.from(
        _statsBox.get('playCounts', defaultValue: {}),
      );
      _recentIds = List<int>.from(_statsBox.get('recentIds', defaultValue: []));

      if (_songs.isNotEmpty) _syncWithHive();
    } catch (e) {
      debugPrint("Hive init error: $e");
    }
  }

  void _syncWithHive() {
    if (!_isHiveReady) return;

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

  // SAFE INDEX VALIDATION
  void _validateCurrentIndex() {
    if (_currentIndex < 0 || _currentIndex >= _allSongs.length) {
      _currentIndex = -1;
    }
  }

  // ================= STATS =================
  void _handleSongChange(int index) {
    if (index < 0 || index >= _allSongs.length) return;

    final song = _allSongs[index];

    _playCounts[song.id] = (_playCounts[song.id] ?? 0) + 1;

    _recentIds.remove(song.id);
    _recentIds.insert(0, song.id);
    if (_recentIds.length > 20) _recentIds.removeLast();

    _statsBox.put('playCounts', _playCounts);
    _statsBox.put('recentIds', _recentIds);
  }

  void setActiveCategory(String category) {
    _activeCategory = category;
    notifyListeners();
  }

  // ================= FETCH SONGS =================
  Future<void> fetchSongs() async {
    _isLoading = true;
    notifyListeners();

    try {
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

        final wasPlaying = _currentIndex >= 0;

        _allSongs = List.from(_songs);

        // PREVENT MINI PLAYER GLITCH ON REFRESH
        if (wasPlaying) _validateCurrentIndex();

        if (_isHiveReady) _syncWithHive();
      }
    } catch (e) {
      debugPrint("Error fetching songs: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // ================= PLAYBACK =================
  ConcatenatingAudioSource _createSequence(List<SongModel> list) {
    return ConcatenatingAudioSource(
      children: list.map((s) => AudioSource.uri(Uri.parse(s.uri!))).toList(),
    );
  }

  Future<void> playSong(int index, {List<SongModel>? customList}) async {
    if (customList != null) {
      _allSongs = customList;
      _validateCurrentIndex();
    }

    if (index < 0 || index >= _allSongs.length) return;

    try {
      await _audioPlayer.setAudioSource(
        _createSequence(_allSongs),
        initialIndex: index,
        initialPosition: Duration.zero,
      );

      _currentIndex = index;
      _audioPlayer.play();
      notifyListeners();
    } catch (e) {
      debugPrint("Playback error: $e");
    }
  }

  void shuffleAndPlay() {
    if (_songs.isEmpty) return;
    _allSongs = List.from(_songs)..shuffle();
    _validateCurrentIndex();
    playSong(0);
  }

  void togglePlay() {
    _audioPlayer.playing ? _audioPlayer.pause() : _audioPlayer.play();
  }

  void playNext() => _audioPlayer.hasNext ? _audioPlayer.seekToNext() : null;

  void playPrevious() =>
      _audioPlayer.hasPrevious ? _audioPlayer.seekToPrevious() : null;

  // ================= PLAYLISTS =================
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

  void createPlaylist(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && !_playlists.containsKey(trimmed)) {
      _playlists[trimmed] = [];
      _savePlaylist(trimmed);
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
      if (name == "Liked" && !isLiked(song)) _likedSongs.add(song);
      _savePlaylist(name);
      notifyListeners();
    }
  }

  void _savePlaylist(String name) {
    if (!_isHiveReady) return;
    final songIds = _playlists[name]?.map((song) => song.id).toList() ?? [];
    _playlistBox.put(name, PlaylistData(name: name, songIds: songIds));
  }

  // ================= PLAYER MODES =================
  void toggleShuffle() {
    _isShuffleModeEnabled = !_isShuffleModeEnabled;
    _audioPlayer.setShuffleModeEnabled(_isShuffleModeEnabled);
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
