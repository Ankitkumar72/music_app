// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../logic/music_provider.dart';
import '../logic/Models/song_data.dart';
import '../widgets/filter_tab.dart';
import '../widgets/song_menu.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedCategory = "Songs";
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<MusicProvider>().searchLibrary(_searchController.text);
  }

  void _openSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    context.read<MusicProvider>().clearLibrarySearch();
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearching) {
          _closeSearch();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A12),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _isSearching
                    ? _buildSearchBar(musicProvider)
                    : _buildTopNavBar(context),
                const SizedBox(height: 25),
                if (!_isSearching) _buildCategoryTabs(),
                if (!_isSearching) const SizedBox(height: 20),
                if (!_isSearching && _selectedCategory == "Songs")
                  _buildShuffleButton(musicProvider),
                if (!_isSearching && _selectedCategory == "Songs")
                  const SizedBox(height: 20),
                Expanded(
                  child: _isSearching
                      ? _buildSearchResults(musicProvider)
                      : _buildCategoryContent(musicProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(MusicProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search songs, artists...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          provider.clearLibrarySearch();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _closeSearch,
          child: const Text(
            "Cancel",
            style: TextStyle(
              color: Color(0xFF5D3FD3),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(MusicProvider provider) {
    final results = provider.librarySearchResults;
    final query = provider.librarySearchQuery;

    if (query.isEmpty) {
      return const Center(
        child: Text(
          "Start typing to search...",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    if (results.isEmpty) {
      return const Center(
        child: Text(
          "No songs found",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: provider.currentSong != null ? 160 : 20),
      itemBuilder: (context, index) {
        final song = results[index];
        return _buildSongTile(song, provider, results, index);
      },
    );
  }

  Widget _buildTopNavBar(BuildContext context) {
    final songCount = context.watch<MusicProvider>().allSongs.length;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Library",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "$songCount songs",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white, size: 28),
          onPressed: _openSearch,
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ["Songs", "Albums", "Artists", "Genres"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map(
              (cat) => FilterTab(
                label: cat,
                isSelected: _selectedCategory == cat,
                onTap: () => setState(() => _selectedCategory = cat),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildShuffleButton(MusicProvider provider) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          provider.shuffleAndPlay();
        },
        icon: const Icon(Icons.shuffle, color: Colors.white, size: 20),
        label: const Text(
          "SHUFFLE ALL",
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5D3FD3),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: const StadiumBorder(),
          elevation: 5,
        ),
      ),
    );
  }

  Widget _buildCategoryContent(MusicProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5D3FD3)),
      );
    }

    switch (_selectedCategory) {
      case "Songs":
        return _buildSongsList(provider);
      case "Albums":
        return _buildAlbumsList(provider);
      case "Artists":
        return _buildArtistsList(provider);
      case "Genres":
        return _buildGenresList(provider);
      default:
        return _buildSongsList(provider);
    }
  }

  // ===================== SONGS TAB =====================
  Widget _buildSongsList(MusicProvider provider) {
    final songs = provider.allSongs;

    if (songs.isEmpty) {
      return const Center(
        child: Text(
          "No songs found on your device.",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: provider.currentSong != null ? 160 : 20),
      itemBuilder: (context, index) {
        final song = songs[index];
        return _buildSongTile(song, provider, songs, index);
      },
    );
  }

  Widget _buildSongTile(
      SongData song, MusicProvider provider, List<SongData> playlist, int index) {
    final String? customPath = provider.getCustomArtwork(song.id);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: customPath != null && File(customPath).existsSync()
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(customPath), fit: BoxFit.cover),
              )
            : QueryArtworkWidget(
                id: song.id,
                type: ArtworkType.AUDIO,
                nullArtworkWidget: provider.defaultArtworkPath != null &&
                        File(provider.defaultArtworkPath!).existsSync()
                    ? Image.file(File(provider.defaultArtworkPath!),
                        fit: BoxFit.cover)
                    : const Icon(
                        Icons.music_note,
                        color: Colors.white54,
                      ),
              ),
      ),
      title: Text(
        song.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: GestureDetector(
        onTap: () => showSongMenu(context, song),
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.more_horiz, color: Colors.white54),
        ),
      ),
      onTap: () {
        provider.playSong(index, customList: playlist);
      },
    );
  }

  // ===================== ALBUMS TAB =====================
  Widget _buildAlbumsList(MusicProvider provider) {
    final albums = provider.albums;

    if (albums.isEmpty) {
      return const Center(
        child: Text(
          "No albums found.",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: provider.currentSong != null ? 160 : 20),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        final firstSong = provider.getFirstSongByArtist(album);
        final songCount = provider.getSongCountByArtist(album);

        return _buildGroupCard(
          provider: provider,
          title: album,
          subtitle: "$songCount songs",
          song: firstSong,
          onTap: () => _showSongsForGroup(album, provider.getSongsByAlbum(album)),
        );
      },
    );
  }

  // ===================== ARTISTS TAB =====================
  Widget _buildArtistsList(MusicProvider provider) {
    final artists = provider.artists;

    if (artists.isEmpty) {
      return const Center(
        child: Text(
          "No artists found.",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: provider.currentSong != null ? 160 : 20),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final firstSong = provider.getFirstSongByArtist(artist);
        final songCount = provider.getSongCountByArtist(artist);

        return _buildGroupCard(
          provider: provider,
          title: artist,
          subtitle: "$songCount songs",
          song: firstSong,
          isCircular: true,
          onTap: () => _showSongsForGroup(artist, provider.getSongsByArtist(artist)),
        );
      },
    );
  }

  // ===================== GENRES TAB =====================
  Widget _buildGenresList(MusicProvider provider) {
    final genres = provider.genres;

    if (genres.isEmpty) {
      return const Center(
        child: Text(
          "No genres found.",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: genres.length,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: provider.currentSong != null ? 160 : 20),
      itemBuilder: (context, index) {
        final genre = genres[index];
        final songs = provider.getSongsByGenre(genre);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getGenreColor(genre),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getGenreIcon(genre),
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Text(
            genre,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            "${songs.length} songs",
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
          onTap: () => _showSongsForGroup(genre, songs),
        );
      },
    );
  }

  Color _getGenreColor(String genre) {
    if (genre == 'All Songs') return const Color(0xFF5D3FD3);
    if (genre == 'Favorites') return const Color(0xFFE91E63);
    // Generate a consistent color from the genre name
    final hash = genre.hashCode.abs();
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.4).toColor();
  }

  IconData _getGenreIcon(String genre) {
    if (genre == 'All Songs') return Icons.library_music;
    if (genre == 'Favorites') return Icons.favorite;
    return Icons.music_note;
  }

  // ===================== GROUP CARD WIDGET =====================
  Widget _buildGroupCard({
    required MusicProvider provider,
    required String title,
    required String subtitle,
    SongData? song,
    bool isCircular = false,
    required VoidCallback onTap,
  }) {
    final String? customPath = song != null ? provider.getCustomArtwork(song.id) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius:
                    isCircular ? BorderRadius.circular(50) : BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius:
                    isCircular ? BorderRadius.circular(50) : BorderRadius.circular(12),
                child: song != null
                    ? (customPath != null && File(customPath).existsSync()
                        ? Image.file(File(customPath), fit: BoxFit.cover)
                        : QueryArtworkWidget(
                            id: song.id,
                            type: ArtworkType.AUDIO,
                            nullArtworkWidget: provider.defaultArtworkPath != null &&
                                    File(provider.defaultArtworkPath!).existsSync()
                                ? Image.file(File(provider.defaultArtworkPath!),
                                    fit: BoxFit.cover)
                                : Icon(
                                    isCircular ? Icons.person : Icons.album,
                                    color: Colors.white54,
                                    size: 40,
                                  ),
                          ))
                    : (provider.defaultArtworkPath != null &&
                            File(provider.defaultArtworkPath!).existsSync()
                        ? Image.file(File(provider.defaultArtworkPath!),
                            fit: BoxFit.cover)
                        : Icon(
                            isCircular ? Icons.person : Icons.album,
                            color: Colors.white54,
                            size: 40,
                          )),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== SHOW SONGS FOR GROUP =====================
  void _showSongsForGroup(String title, List<SongData> songs) {
    final provider = context.read<MusicProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A12),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        "${songs.length} songs",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Play/Shuffle buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            provider.playSong(0, customList: songs);
                          },
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: const Text("Play All"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D3FD3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            final shuffled = List<SongData>.from(songs)..shuffle();
                            provider.playSong(0, customList: shuffled);
                          },
                          icon: const Icon(Icons.shuffle, size: 20),
                          label: const Text("Shuffle"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Songs list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: songs.length,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final String? customPath = provider.getCustomArtwork(song.id);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: customPath != null && File(customPath).existsSync()
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(customPath), fit: BoxFit.cover),
                                )
                              : QueryArtworkWidget(
                                  id: song.id,
                                  type: ArtworkType.AUDIO,
                                  nullArtworkWidget: const Icon(
                                    Icons.music_note,
                                    color: Colors.white54,
                                  ),
                                ),
                        ),
                        title: Text(
                          song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.artist,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          provider.playSong(index, customList: songs);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
