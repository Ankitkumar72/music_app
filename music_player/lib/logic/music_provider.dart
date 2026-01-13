// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'Models/song_data.dart';
import 'audio_handler.dart';
import '../main.dart';

class MusicProvider extends ChangeNotifier {
  static const platform = MethodChannel('com.example.music_player/notification');
  final OnAudioQuery _audioQuery = OnAudioQuery();

  // Helper to safely get the audio handler from the global variable
  AudioPlayerHandler? get _handler => audioHandler;

  // Use AudioService's audio handler player if available
  AudioPlayer get _audioPlayer => _handler?.player ?? _fallbackPlayer;
  
  // Fallback player for when audio_service isn't initialized
  final AudioPlayer _fallbackPlayer = AudioPlayer();

  MusicProvider() {
    _init();
  }

  void _init() {
    _setupPlayerListeners();
    _setupMediaButtonHandler();
    _initHive();
  }

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
  List<SongData> _searchResults = [];

  // Cache for internet artwork paths
  final Map<int, String?> _artworkCache = {};

  // ================= EXCLUDED SONGS =================
  List<int> _excludedSongIds = [];

  // ================= STATE =================
  int _currentIndex = -1;
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _isShuffleModeEnabled = false;
  LoopMode _loopMode = LoopMode.off;

  // ================= HIVE =================
  late Box<PlaylistData> _playlistBox;
  late Box<CachedMetadata> _metadataBox;
  late Box _statsBox;
  bool _isHiveReady = false;

  // ================= GETTERS =================
  List<SongData> get songs => _songs;
  List<SongData> get allSongs => _allSongs;
  List<SongData> get likedSongs => _likedSongs;
  Map<String, List<SongData>> get allPlaylists => _playlists;
  List<String> get playlistNames => _playlists.keys.toList();
  String get activeCategory => _activeCategory;
  List<SongData> get searchResults => _searchResults;
  
  // Library search results
  List<SongData> _librarySearchResults = [];
  String _librarySearchQuery = '';
  List<SongData> get librarySearchResults => _librarySearchResults;
  String get librarySearchQuery => _librarySearchQuery;

  // ================= GROUPING GETTERS =================
  
  /// Returns a list of unique artists (excluding "Unknown" artists)
  List<String> get artists {
    final artistSet = <String>{};
    for (final song in _allSongs) {
      final artist = song.artist.trim();
      if (artist.isNotEmpty && 
          artist.toLowerCase() != 'unknown' && 
          artist.toLowerCase() != 'unknown artist') {
        artistSet.add(artist);
      }
    }
    final artistList = artistSet.toList();
    artistList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return artistList;
  }

  /// Returns a list of unique albums (using artist as a grouping key since we don't have album metadata)
  /// Each "album" is represented as the artist name for grouping purposes
  List<String> get albums {
    // Since SongData doesn't have album field, we'll group by artist
    // This creates "albums" as collections by the same artist
    return artists;
  }

  /// Returns a list of unique genres
  /// Since we don't have genre metadata, we'll create some based on patterns
  List<String> get genres {
    // Generate some pseudo-genres based on artist or title patterns
    // For now, return a predefined list that can be expanded later
    final genreSet = <String>{'All Songs', 'Favorites'};
    
    // Add "By Artist" genres for artists with multiple songs
    final artistCounts = <String, int>{};
    for (final song in _allSongs) {
      final artist = song.artist.trim();
      if (artist.isNotEmpty && 
          artist.toLowerCase() != 'unknown' && 
          artist.toLowerCase() != 'unknown artist') {
        artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
      }
    }
    
    // Artists with 3+ songs get their own "genre"
    for (final entry in artistCounts.entries) {
      if (entry.value >= 3) {
        genreSet.add(entry.key);
      }
    }
    
    final genreList = genreSet.toList();
    genreList.sort((a, b) {
      // Keep "All Songs" and "Favorites" at the top
      if (a == 'All Songs') return -1;
      if (b == 'All Songs') return 1;
      if (a == 'Favorites') return -1;
      if (b == 'Favorites') return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return genreList;
  }

  /// Get songs by a specific artist
  List<SongData> getSongsByArtist(String artist) {
    return _allSongs.where((song) => 
      song.artist.toLowerCase() == artist.toLowerCase()
    ).toList();
  }

  /// Get songs by "album" (grouping by artist since we don't have album metadata)
  List<SongData> getSongsByAlbum(String album) {
    // Since albums are artist-based groupings
    return getSongsByArtist(album);
  }

  /// Get songs by genre
  List<SongData> getSongsByGenre(String genre) {
    if (genre == 'All Songs') {
      return List.from(_allSongs);
    }
    if (genre == 'Favorites') {
      return List.from(_likedSongs);
    }
    // Otherwise, treat genre as an artist name
    return getSongsByArtist(genre);
  }

  /// Get first song for an artist (for artwork display)
  SongData? getFirstSongByArtist(String artist) {
    try {
      return _allSongs.firstWhere((song) => 
        song.artist.toLowerCase() == artist.toLowerCase()
      );
    } catch (_) {
      return null;
    }
  }

  /// Get song count for an artist
  int getSongCountByArtist(String artist) {
    return _allSongs.where((song) => 
      song.artist.toLowerCase() == artist.toLowerCase()
    ).length;
  }

  // ================= LIBRARY SEARCH =================
  void searchLibrary(String query) {
    _librarySearchQuery = query;
    if (query.isEmpty) {
      _librarySearchResults = [];
    } else {
      final lowercaseQuery = query.toLowerCase();
      _librarySearchResults = _allSongs.where((song) {
        final titleMatch = song.title.toLowerCase().contains(lowercaseQuery);
        final artistLower = song.artist.toLowerCase();
        final isUnknownArtist = artistLower == 'unknown' || 
                                artistLower == 'unknown artist' ||
                                artistLower.isEmpty;
        final artistMatch = !isUnknownArtist && artistLower.contains(lowercaseQuery);
        return titleMatch || artistMatch;
      }).toList();
    }
    notifyListeners();
  }

  void clearLibrarySearch() {
    _librarySearchQuery = '';
    _librarySearchResults = [];
    notifyListeners();
  }

  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  bool get isShuffleModeEnabled => _isShuffleModeEnabled;
  LoopMode get loopMode => _loopMode;
  AudioPlayer get player => _audioPlayer;

  SongData? get currentSong {
    if (_currentPlaylist.isNotEmpty &&
        _currentIndex >= 0 &&
        _currentIndex < _currentPlaylist.length) {
      return _currentPlaylist[_currentIndex];
    }
    if (_currentIndex >= 0 && _currentIndex < _allSongs.length) {
      return _allSongs[_currentIndex];
    }
    return null;
  }

  String? getCustomArtwork(int songId) => _artworkCache[songId];

  // ================= MANUAL ARTWORK SEARCH =================
  Future<List<Map<String, dynamic>>> searchArtwork(String query) async {
    try {
      // Try Deezer first (1000x1000, free, no API key needed)
      final deezerResults = await _searchDeezer(query);
      if (deezerResults.isNotEmpty) {
        debugPrint("✅ Found artwork via Deezer (1000x1000)");
        return deezerResults;
      }

      // Fallback to iTunes (600x600)
      final itunesResults = await _searchItunes(query);
      if (itunesResults.isNotEmpty) {
        debugPrint("✅ Found artwork via iTunes (600x600)");
        return itunesResults;
      }

      debugPrint("❌ No artwork found for: $query");
      return [];
    } catch (e) {
      debugPrint("Error searching artwork: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _searchDeezer(String query) async {
    try {
      final cleanQuery = Uri.encodeComponent(query);
      final url = 'https://api.deezer.com/search?q=$cleanQuery';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['data'] ?? [];
        
        return results.map((item) => {
          'artworkUrl100': item['album']?['cover_xl'] ?? item['album']?['cover_big'] ?? '',
          'trackName': item['title'] ?? '',
          'artistName': item['artist']?['name'] ?? '',
        }).toList().cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint("Deezer API error: $e");
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _searchItunes(String query) async {
    try {
      final cleanQuery = Uri.encodeComponent(query);
      final url = 'https://itunes.apple.com/search?term=$cleanQuery&media=music&limit=10';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        
        return results.map((item) => {
          'artworkUrl100': item['artworkUrl100']?.toString().replaceAll('100x100bb', '600x600bb') ?? '',
          'trackName': item['trackName'] ?? '',
          'artistName': item['artistName'] ?? '',
        }).toList().cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint("iTunes API error: $e");
    }
    return [];
  }

  Future<void> applyChosenArtwork(
      int songId, Map<String, dynamic> artworkData) async {
    try {
      String? imageUrl = artworkData['artworkUrl100']?.toString().replaceAll(
            '100x100bb',
            '600x600bb',
          );

      if (imageUrl == null || imageUrl.isEmpty) {
        debugPrint("No valid artwork URL found for this result");
        return;
      }

      debugPrint("Downloading chosen art from: $imageUrl");

      Directory dir = await getApplicationDocumentsDirectory();
      String filePath = "${dir.path}/art_$songId.jpg";

      await Dio().download(imageUrl, filePath);

      _artworkCache[songId] = filePath;
      await _metadataBox.put(
        songId,
        CachedMetadata(songId: songId, localImagePath: filePath),
      );

      notifyListeners();
      debugPrint("✅ Successfully applied artwork from manual search!");
    } catch (e) {
      debugPrint("Error applying chosen artwork: $e");
    }
  }

  List<SongData> get dailyMixSongs {
    return _songs
        .where((s) => (_playCounts[s.id] ?? 0) >= 3)
        .take(10)
        .toList();
  }

  List<SongData> get discoverySongs {
    final shuffled = List<SongData>.from(_allSongs)..shuffle();
    return shuffled.take(20).toList();
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



  void _setupPlayerListeners() {
    _audioPlayer.playingStream.listen((playing) {
      _isPlaying = playing;
      _updateCustomNotification();
      notifyListeners();
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && _currentIndex != index) {
        _currentIndex = index;
        _handleSongChange(index);
        _updateNotificationMetadata();
        _updateCustomNotification();
        notifyListeners();
      }
    });

    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _currentIndex = -1;
        _isPlaying = false;
        _updateCustomNotification();
        notifyListeners();
      }
    });
  }

  void _updateNotificationMetadata() {
    if (currentSong == null || _handler == null) return;
    
    final song = currentSong!;
    final artworkPath = getCustomArtwork(song.id);
    
    final mediaItem = MediaItem(
      id: song.data,
      title: song.title,
      artist: song.artist,
      artUri: artworkPath != null ? Uri.file(artworkPath) : null,
      duration: _audioPlayer.duration,
    );
    
    _handler!.updateMediaItem(mediaItem);
  }

  // ================= HIVE INIT =================
  Future<void> _initHive() async {
    try {
      _playlistBox = await Hive.openBox<PlaylistData>('playlists');
      _metadataBox = await Hive.openBox<CachedMetadata>('metadata');
      _statsBox = await Hive.openBox('music_stats');
      _isHiveReady = true;

      for (var entry in _metadataBox.values) {
        _artworkCache[entry.songId] = entry.localImagePath;
      }

      _playCounts = Map<int, int>.from(_statsBox.get('playCounts', defaultValue: {}));
      _recentIds = List<int>.from(_statsBox.get('recentIds', defaultValue: []));
      _excludedSongIds = List<int>.from(_statsBox.get('excludedSongIds', defaultValue: []));

      debugPrint("✅ Hive ready | Artwork: ${_artworkCache.length} | Excluded: ${_excludedSongIds.length} | Stats loaded");
      fetchSongs();
    } catch (e) {
      debugPrint("Error initializing Hive: $e");
      _isHiveReady = false;
      fetchSongs();
    }
  }

  void _syncWithHive() {
    if (!_isHiveReady) return;
    for (final data in _playlistBox.values) {
      final matchedSongs = _songs
          .where((s) => data.songIds.contains(s.id))
          .where((s) => File(s.data).existsSync())
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

  void _handleSongChange(int newIndex) {
    final id = _currentPlaylist.isNotEmpty && newIndex < _currentPlaylist.length
        ? _currentPlaylist[newIndex].id
        : _allSongs.isNotEmpty && newIndex < _allSongs.length
        ? _allSongs[newIndex].id
        : null;

    if (id == null) return;

    _playCounts[id] = (_playCounts[id] ?? 0) + 1;

    _recentIds.remove(id);
    _recentIds.insert(0, id);
    if (_recentIds.length > 50) {
      _recentIds.removeRange(50, _recentIds.length);
    }

    _statsBox.put('playCounts', _playCounts);
    _statsBox.put('recentIds', _recentIds);
  }

  // ================= FETCH SONGS =================
  Future<void> fetchSongs() async {
    _isLoading = true;
    notifyListeners();

    try {
      List<SongModel> queriedSongs = await _audioQuery.querySongs(
        ignoreCase: true,
        orderType: OrderType.ASC_OR_SMALLER,
        sortType: SongSortType.TITLE,
        uriType: UriType.EXTERNAL,
      );

      _songs = queriedSongs.map((s) {
        return SongData.fromFile(id: s.id, filePath: s.data);
      }).toList();

      _songs = _songs.where((s) => File(s.data).existsSync()).toList();
      
      // Filter out excluded songs
      _songs = _songs.where((s) => !_excludedSongIds.contains(s.id)).toList();
      
      _songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

      _allSongs = List.from(_songs);
    } catch (e) {
      debugPrint("Error fetching songs: $e");
    }

    _syncWithHive();
  
    _isLoading = false;
    notifyListeners();
    
    autoDownloadArtwork();
  }

  Future<void> autoDownloadArtwork() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('⏸️ No internet connection, skipping auto-download');
      return;
    }

    final songsNeedingArt = _allSongs.where((song) => 
      getCustomArtwork(song.id) == null
    ).toList();

    if (songsNeedingArt.isEmpty) {
      debugPrint('✅ All songs have artwork');
      return;
    }

    debugPrint('🎨 Auto-downloading artwork for ${songsNeedingArt.length} songs...');

    int successCount = 0;
    for (var i = 0; i < songsNeedingArt.length; i++) {
      try {
        final song = songsNeedingArt[i];
        final query = '${song.title} ${song.artist}';
        final results = await searchArtwork(query);
        
        if (results.isNotEmpty) {
          await applyChosenArtwork(song.id, results.first);
          successCount++;
        }
        
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('Failed to download artwork: $e');
      }
    }

    debugPrint('✅ Auto-downloaded $successCount/${songsNeedingArt.length} artworks');
  }

  Future<void> toggleLike(SongData song) async {
    final isLiked = _likedSongs.any((s) => s.id == song.id);
    if (isLiked) {
      _likedSongs.removeWhere((s) => s.id == song.id);
    } else {
      _likedSongs.add(song);
    }
    _playlists["Liked"] = _likedSongs;

    if (!_isHiveReady) return;
    await _savePlaylistToHive("Liked");
    notifyListeners();
  }

  bool isLiked(SongData song) => _likedSongs.any((s) => s.id == song.id);

  // ================= EXCLUDE SONGS =================
  List<int> get excludedSongIds => _excludedSongIds;
  
  /// Excludes a song from the library (persisted across rescans)
  Future<void> excludeSong(SongData song) async {
    if (_excludedSongIds.contains(song.id)) return;
    
    // Check if this song is currently playing
    final isCurrentlyPlaying = currentSong?.id == song.id;
    
    _excludedSongIds.add(song.id);
    _songs.removeWhere((s) => s.id == song.id);
    _allSongs.removeWhere((s) => s.id == song.id);
    _likedSongs.removeWhere((s) => s.id == song.id);
    
    // Remove from current playlist
    _currentPlaylist.removeWhere((s) => s.id == song.id);
    
    // Remove from all playlists
    for (final playlist in _playlists.values) {
      playlist.removeWhere((s) => s.id == song.id);
    }
    
    // If the excluded song was playing, handle playback
    if (isCurrentlyPlaying) {
      if (_currentPlaylist.isNotEmpty && _currentIndex < _currentPlaylist.length) {
        // There are more songs in the queue, play the next one
        await skipToNext();
      } else if (_allSongs.isNotEmpty) {
        // No songs in queue, but library has songs - just stop
        _currentIndex = -1;
        pause();
      } else {
        // No songs left at all
        _currentIndex = -1;
        pause();
      }
    } else if (_currentIndex > 0) {
      // Adjust current index if needed (song before current was removed)
      // Find new index of currently playing song
      final currentId = currentSong?.id;
      if (currentId != null) {
        final newIndex = _currentPlaylist.indexWhere((s) => s.id == currentId);
        if (newIndex != -1) {
          _currentIndex = newIndex;
        }
      }
    }
    
    if (_isHiveReady) {
      await _statsBox.put('excludedSongIds', _excludedSongIds);
    }
    
    notifyListeners();
    debugPrint("🚫 Song excluded: ${song.title} (ID: ${song.id})");
  }
  
  /// Restores a previously excluded song
  Future<void> restoreSong(int songId) async {
    if (!_excludedSongIds.contains(songId)) return;
    
    _excludedSongIds.remove(songId);
    
    if (_isHiveReady) {
      await _statsBox.put('excludedSongIds', _excludedSongIds);
    }
    
    // Refetch songs to include the restored one
    await fetchSongs();
    debugPrint("✅ Song restored (ID: $songId)");
  }
  
  /// Restores all excluded songs
  Future<void> restoreAllSongs() async {
    _excludedSongIds.clear();
    
    if (_isHiveReady) {
      await _statsBox.put('excludedSongIds', _excludedSongIds);
    }
    
    await fetchSongs();
    debugPrint("✅ All excluded songs restored");
  }

  Future<void> createPlaylist(String name) async {
    if (_playlists.containsKey(name)) return;
    _playlists[name] = [];
    
    if (_isHiveReady) {
      await _savePlaylistToHive(name);
    }
    notifyListeners();
  }

  Future<void> deletePlaylist(String name) async {
    if (name == "Liked") return; // Cannot delete Liked playlist
    if (!_playlists.containsKey(name)) return;
    
    _playlists.remove(name);
    
    if (_isHiveReady) {
      final key = _playlistBox.keys.firstWhere(
        (k) => _playlistBox.get(k)?.name == name,
        orElse: () => null,
      );
      if (key != null) {
        await _playlistBox.delete(key);
      }
    }
    notifyListeners();
    debugPrint("🗑️ Playlist deleted: $name");
  }

  Future<void> addToPlaylist(String playlistName, SongData song) async {
    if (!_playlists.containsKey(playlistName)) return;
    
    final playlist = _playlists[playlistName]!;
    if (!playlist.any((s) => s.id == song.id)) {
      playlist.add(song);
      
      if (_isHiveReady) {
        await _savePlaylistToHive(playlistName);
      }
      notifyListeners();
    }
  }

  Future<void> _savePlaylistToHive(String playlistName) async {
    final playlist = _playlists[playlistName];
    if (playlist == null) return;

    final songIds = playlist.map((s) => s.id).toList();
    final playlistData = PlaylistData(name: playlistName, songIds: songIds);
    await _playlistBox.put(playlistName, playlistData);
  }

  // ================= PLAYBACK =================
  Future<void> playSong(int index, {List<SongData>? customList}) async {
    final List<SongData> sourceList = customList ?? _songs;
    if (sourceList.isEmpty || index < 0 || index >= sourceList.length) return;

    _currentPlaylist = sourceList;
    _currentIndex = index;

    debugPrint("🎵 playSong called - audioHandler status: ${_handler != null ? 'AVAILABLE' : 'NULL'}");
    
    if (_handler != null) {
      final mediaItems = sourceList.map((song) {
        final artworkPath = getCustomArtwork(song.id);
        debugPrint("   Creating MediaItem for '${song.title}' - Artwork: ${artworkPath ?? 'NONE'}");
        return MediaItem(
          id: song.data,
          title: song.title,
          artist: song.artist.isEmpty ? 'Unknown Artist' : song.artist,
          album: song.artist.isEmpty ? 'Unknown Album' : song.artist,
          artUri: artworkPath != null ? Uri.file(artworkPath) : null,
        );
      }).toList();

      try {
        await _handler!.playPlaylist(mediaItems, initialIndex: index);
        _isPlaying = true;
        debugPrint('✅ Playing via audio_service: ${mediaItems[index].title}');
        debugPrint('   Initial song artwork URI: ${mediaItems[index].artUri}');
        
        // Update custom notification with fresh artwork
        await _updateCustomNotification();
        
        notifyListeners();
      } catch (e) {
        debugPrint('❌ Error loading audio source via audio_service: $e');
        _fallbackPlayback(sourceList, index);
      }
    } else {
      debugPrint('⚠️ audioHandler is NULL - using fallback playback');
      _fallbackPlayback(sourceList, index);
    }
  }

  // Helper method for fallback playback
  Future<void> _fallbackPlayback(List<SongData> sourceList, int index) async {
    debugPrint('⚠️ Using fallback audio player (audio_service not available)');
    List<AudioSource> audioSources = sourceList.map((song) {
      return AudioSource.file(song.data);
    }).toList();

    try {
      await _audioPlayer.setAudioSource(
        ConcatenatingAudioSource(children: audioSources),
        initialIndex: index,
      );
      await _audioPlayer.play();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading audio source: $e');
    }
  }

  void play() {
    if (_handler != null) {
      _handler!.play();
    } else {
      _audioPlayer.play();
    }
  }

  void pause() {
    if (_handler != null) {
      _handler!.pause();
    } else {
      _audioPlayer.pause();
    }
  }

  void stop() {
    if (_handler != null) {
      _handler!.stop();
    } else {
      _audioPlayer.stop();
    }
  }

  Future<void> skipToNext() async {
    if (_handler != null) {
      await _handler!.skipToNext();
      _currentIndex = _handler!.player.currentIndex ?? 0;
    } else if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
    }
    notifyListeners();
  }

  Future<void> skipToPrevious() async {
    if (_handler != null) {
      await _handler!.skipToPrevious();
      _currentIndex = _handler!.player.currentIndex ?? 0;
    } else if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
    }
    notifyListeners();
  }

  void seekTo(Duration position) {
    if (_handler != null) {
      _handler!.seek(position);
    } else {
      _audioPlayer.seek(position);
    }
  }

  void Function() get playPrevious => skipToPrevious;
  
  void togglePlay() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }
  
  void Function() get playNext => skipToNext;

  void toggleShuffle() {
    _isShuffleModeEnabled = !_isShuffleModeEnabled;
    if (_handler != null) {
      _handler!.player.setShuffleModeEnabled(
        _isShuffleModeEnabled,
      );
    } else {
      _audioPlayer.setShuffleModeEnabled(_isShuffleModeEnabled);
    }
    notifyListeners();
  }

  void toggleRepeat() {
    _loopMode = _loopMode == LoopMode.off
        ? LoopMode.all
        : _loopMode == LoopMode.all
        ? LoopMode.one
        : LoopMode.off;
    
    if (_handler != null) {
      _handler!.player.setLoopMode(_loopMode);
    } else {
      _audioPlayer.setLoopMode(_loopMode);
    }
    notifyListeners();
  }

  // ================= SEARCH =================
  void searchSongs(String query) {
    if (query.isEmpty) {
      _searchResults = [];
    } else {
      final lowercaseQuery = query.toLowerCase();
      _searchResults = _allSongs.where((song) {
        final titleMatch = song.title.toLowerCase().contains(lowercaseQuery);
        
        final artistLower = song.artist.toLowerCase();
        final isUnknownArtist = artistLower == 'unknown' || 
                                artistLower == 'unknown artist' ||
                                artistLower.isEmpty;
        final artistMatch = !isUnknownArtist && artistLower.contains(lowercaseQuery);
        
        return titleMatch || artistMatch;
      }).toList();
    }
    notifyListeners();
  }

  // ================= CATEGORY & MISC =================
  void setActiveCategory(String category) {
    _activeCategory = category;
    notifyListeners();
  }

  void shuffleAndPlay() {
    if (_allSongs.isEmpty) return;
    final shuffled = List<SongData>.from(_allSongs)..shuffle();
    playSong(0, customList: shuffled);
  }

  Future<void> setCustomArtwork(int songId, String filePath) async {
    try {
      _artworkCache[songId] = filePath;
      await _metadataBox.put(
        songId,
        CachedMetadata(songId: songId, localImagePath: filePath),
      );
      notifyListeners();
      debugPrint("✅ Custom artwork set for song $songId");
    } catch (e) {
      debugPrint("Error setting custom artwork: $e");
    }
  }


  // ================= CUSTOM NOTIFICATION =================
  Future<void> _updateCustomNotification() async {
    if (currentSong == null) return;
    
    final artPath = getCustomArtwork(currentSong!.id);
    debugPrint("🔔 Updating Custom Notification: ${currentSong!.title}");
    debugPrint("   Artwork Path: $artPath");
    
    try {
      await platform.invokeMethod('showNotification', {
        'title': currentSong!.title,
        'artist': currentSong!.artist.isEmpty ? 'Unknown Artist' : currentSong!.artist,
        'artworkPath': artPath,
        'isPlaying': _isPlaying,
      });
    } catch (e) {
      debugPrint('Failed to update custom notification: $e');
    }
  }
  
  Future<void> _setupMediaButtonHandler() async {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onMediaButton') {
        final action = call.arguments['action'] as String?;
        switch (action) {
          case 'play':
            play();
            break;
          case 'pause':
            pause();
            break;
          case 'next':
            await skipToNext();
            break;
          case 'previous':
            await skipToPrevious();
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _fallbackPlayer.dispose();
    super.dispose();
  }
}
