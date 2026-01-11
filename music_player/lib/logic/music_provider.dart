// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

import 'Models/song_data.dart';

class MusicProvider extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ================= SONG LISTS =================
  List<SongData> _songs = [];
  List<SongData> _allSongs = []; // Full library, never modified
  List<SongData> _currentPlaylist = []; // Currently playing playlist
  final List<SongData> _likedSongs = [];
  final Map<String, List<SongData>> _playlists = {"Liked": []};

  // ================= SYNC DATA =================
  Map<int, int> _playCounts = {};
  List<int> _recentIds = [];
  String _activeCategory = "✨ For You";

  // Cache for internet artwork paths
  final Map<int, String?> _artworkCache = {};

  // ================= STATE =================
  int _currentIndex = -1;
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _isShuffleModeEnabled = false;
  LoopMode _loopMode = LoopMode.off;

  // ================= HIVE =================
  late Box<PlaylistData> _playlistBox;
  late Box<CachedMetadata> _metadataBox; // New box for artwork paths
  late Box _statsBox;
  bool _isHiveReady = false;

  // ================= GETTERS =================
  List<SongData> get songs => _songs;
  List<SongData> get allSongs => _allSongs;
  List<SongData> get likedSongs => _likedSongs;
  Map<String, List<SongData>> get allPlaylists => _playlists;
  List<String> get playlistNames => _playlists.keys.toList();
  String get activeCategory => _activeCategory;

  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  bool get isShuffleModeEnabled => _isShuffleModeEnabled;
  LoopMode get loopMode => _loopMode;
  AudioPlayer get player => _audioPlayer;

  SongData? get currentSong {
    // Use current playlist if available
    if (_currentPlaylist.isNotEmpty &&
        _currentIndex >= 0 &&
        _currentIndex < _currentPlaylist.length) {
      return _currentPlaylist[_currentIndex];
    }
    
    // Fallback to allSongs to ensure mini player shows
    if (_currentIndex >= 0 && _currentIndex < _allSongs.length) {
      return _allSongs[_currentIndex];
    }
    
    return null;
  }

  // Helper to check if custom artwork exists
  String? getCustomArtwork(int songId) => _artworkCache[songId];

  // ================= MANUAL ARTWORK SEARCH =================
  /// Searches iTunes API with custom query and returns multiple results
  Future<List<Map<String, dynamic>>> searchArtwork(String query) async {
    try {
      final term = Uri.encodeComponent(query);
      final url =
          "https://itunes.apple.com/search?term=$term&entity=song&limit=12";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['resultCount'] > 0) {
          return (data['results'] as List).map((result) {
            // Get high-res version of artwork
            String artworkUrl = (result['artworkUrl100'] ?? '')
                .replaceAll('100x100bb', '600x600bb');

            return {
              'artworkUrl': artworkUrl,
              'trackName': result['trackName'] ?? 'Unknown',
              'artistName': result['artistName'] ?? 'Unknown Artist',
              'collectionName': result['collectionName'],
            };
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("Artwork search error: $e");
    }
    return [];
  }

  /// Downloads and saves custom artwork selected by user
  Future<void> setCustomArtwork(int songId, String artworkUrl) async {
    try {
      Directory dir = await getApplicationDocumentsDirectory();
      String filePath = "${dir.path}/art_$songId.jpg";

      // Download the artwork
      await Dio().download(artworkUrl, filePath);

      // Save to Hive and Cache
      _artworkCache[songId] = filePath;
      await _metadataBox.put(
        songId,
        CachedMetadata(songId: songId, localImagePath: filePath),
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint("Custom artwork save error: $e");
      rethrow; // Re-throw so UI can show error
    }
  }

  // ================= HOME LOGIC =================
  List<SongData> get dailyMixSongs =>
      _songs.where((s) => (_playCounts[s.id] ?? 0) >= 3).toList();

  List<SongData> get discoverySongs {
    final shuffled = List<SongData>.from(_songs)..shuffle();
    return shuffled.take(10).toList();
  }

  List<SongData> get recentlyPlayed {
    final result = <SongData>[];
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

    _audioPlayer.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && _currentIndex != index) {
        _currentIndex = index;
        _handleSongChange(index);
        notifyListeners();
      }
    });

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
      _metadataBox = await Hive.openBox<CachedMetadata>('metadata'); //
      _statsBox = await Hive.openBox('stats');
      _isHiveReady = true;

      _playCounts = Map<int, int>.from(
        _statsBox.get('playCounts', defaultValue: {}),
      );
      _recentIds = List<int>.from(_statsBox.get('recentIds', defaultValue: []));

      // Load cached metadata into memory
      for (var meta in _metadataBox.values) {
        _artworkCache[meta.songId] = meta.localImagePath;
      }

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

  // ================= ARTWORK FETCHER (iTunes API) =================
  Future<void> fetchInternetArtwork(SongData song) async {
    // Skip if already cached
    if (_artworkCache.containsKey(song.id)) return;

    try {
      final term = Uri.encodeComponent("${song.title} ${song.artist}");
      final url =
          "https://itunes.apple.com/search?term=$term&entity=song&limit=1";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['resultCount'] > 0) {
          // Get high-res version
          String imageUrl = data['results'][0]['artworkUrl100'].replaceAll(
            '100x100bb',
            '600x600bb',
          );

          Directory dir = await getApplicationDocumentsDirectory();
          String filePath = "${dir.path}/art_${song.id}.jpg";

          await Dio().download(imageUrl, filePath);

          // Save to Hive and Cache
          _artworkCache[song.id] = filePath;
          await _metadataBox.put(
            song.id,
            CachedMetadata(songId: song.id, localImagePath: filePath),
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Metadata fetch error: $e");
    }
  }

  void _validateCurrentIndex() {
    if (_currentIndex < 0 || _currentIndex >= _currentPlaylist.length) {
      _currentIndex = -1;
    }
  }

  // ================= STATS & AUTO-FETCH ART =================
  void _handleSongChange(int index) {
    if (index < 0 || index >= _currentPlaylist.length) return;
    final song = _currentPlaylist[index];

    // Trigger internet artwork check when a song starts
    fetchInternetArtwork(song);

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
      // 1. Get raw songs from device
      List<SongModel> queriedSongs = await _audioQuery.querySongs(
        ignoreCase: true,
        orderType: OrderType.ASC_OR_SMALLER,
        sortType: SongSortType.TITLE, // Initial sort from the package
        uriType: UriType.EXTERNAL,
      );

      // 2. Map to SongData (This runs your MetadataParser logic)
      _songs = queriedSongs.map((s) {
        return SongData.fromFile(id: s.id, filePath: s.data);
      }).toList();

      // 3. FINAL SORT: Force alphabetical order by the CLEANED Title
      _songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

      _allSongs = List.from(_songs);
    } catch (e) {
      debugPrint("Error fetching songs: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // ================= PLAYBACK =================
  ConcatenatingAudioSource _createSequence(List<SongData> list) {
    return ConcatenatingAudioSource(
      children: list.map((s) => AudioSource.uri(Uri.file(s.data))).toList(),
    );
  }

  Future<void> playSong(int index, {List<SongData>? customList}) async {
    // Set current playlist (from customList or use full library)
    _currentPlaylist = customList ?? _allSongs;
    if (index < 0 || index >= _currentPlaylist.length) return;

    try {
      await _audioPlayer.setAudioSource(
        _createSequence(_currentPlaylist),
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
    _currentPlaylist = List.from(_songs)..shuffle();
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
  bool isLiked(SongData song) => _likedSongs.any((s) => s.id == song.id);

  void toggleLike(SongData song) {
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

  void addToPlaylist(String name, SongData song) {
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
