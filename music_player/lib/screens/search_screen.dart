import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../logic/music_provider.dart';
import '../logic/Models/song_data.dart';
import '../widgets/filter_tab.dart';
import 'playlist_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "Top Results";
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Listen to text changes to trigger search on every keystroke
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      // Call the search method in the provider
      context.read<MusicProvider>().searchSongs(_searchQuery);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final searchResults = musicProvider.searchResults;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Search Bar ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search songs, artists, albums...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        _searchController.clear();
                        // Clear search results in provider
                        musicProvider.searchSongs("");
                      },
                    )
                        : const Icon(Icons.mic, color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Category Chips ---
              if (_searchQuery.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["Top Results", "Artists", "Songs", "Albums"]
                        .map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterTab(
                        label: cat,
                        isSelected: _selectedCategory == cat,
                        onTap: () => setState(() => _selectedCategory = cat),
                      ),
                    ))
                        .toList(),
                  ),
                ),

              const SizedBox(height: 16),

              // --- Search Results or Browse Section ---
              Expanded(
                child: _searchQuery.isEmpty
                    ? _buildBrowseSection(musicProvider)
                    : _buildSearchResults(searchResults, musicProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the UI when not searching (Recent Searches & Browse)
  Widget _buildBrowseSection(MusicProvider musicProvider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Recent Searches Header ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Searches",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement clear recent searches logic
                },
                child: const Text(
                  "CLEAR ALL",
                  style: TextStyle(color: Color(0xFF6332F6), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // --- No recent searches yet ---
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                "No recent searches",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- Browse Header ---
          const Text(
            "Browse",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // --- Browse Cards ---
          Row(
            children: [
              Expanded(
                child: _buildBrowseCard(
                  "CHARTS",
                  "Top 10\nDaily Mix",
                  const Color(0xFF1E1E2C),
                  Icons.bar_chart,
                  onTap: () {
                    final dailyMix = musicProvider.dailyMixSongs.take(10).toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaylistDetailScreen(
                          playlistName: "Top 10 Daily Mix",
                          songs: dailyMix,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBrowseCard(
                  "TRENDING",
                  "New\nReleases",
                  const Color(0xFF2C1E1E),
                  Icons.local_fire_department,
                  onTap: () {
                    final discovery = musicProvider.discoverySongs;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaylistDetailScreen(
                          playlistName: "Discovery Mix",
                          songs: discovery,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Builds a browse card (Charts, New Releases)
  Widget _buildBrowseCard(
    String subtitle,
    String title,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(
                icon,
                size: 40,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the list of search results
  Widget _buildSearchResults(List<SongData> results, MusicProvider provider) {
    if (results.isEmpty) {
      return const Center(
        child: Text(
          "No results found",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.builder(
      itemCount: results.length,
      padding: EdgeInsets.only(bottom: provider.currentSong != null ? 160 : 20),
      itemBuilder: (context, index) {
        final song = results[index];
        // Logic to get artwork path from provider
        final String? customPath = provider.getCustomArtwork(song.id);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            // Display custom artwork if available, else fallback to QueryArtworkWidget
            child: customPath != null && File(customPath).existsSync()
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(customPath),
                fit: BoxFit.cover,
              ),
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
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            song.artist,
            style: const TextStyle(color: Colors.white54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            // Play the selected song from the search results list
            provider.playSong(index, customList: results);
          },
        );
      },
    );
  }
}