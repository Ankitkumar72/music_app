// ignore_for_file: curly_braces_in_flow_control_structures, unused_field, prefer_final_fields
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../logic/music_provider.dart';
import '../widgets/filter_tab.dart';
import '../widgets/playlist_card.dart';
import 'playlist_detail_screen.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  String _selectedFilter = "All Playlists";

  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final allPlaylists = musicProvider.allPlaylists;

    final filteredPlaylists = _filterAndSearchPlaylists(allPlaylists);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(context, allPlaylists),
              const SizedBox(height: 30),
              _buildTitleSection(context, musicProvider),
              const SizedBox(height: 25),
              _buildFilterTabs(),
              const SizedBox(height: 25),
              _buildPlaylistGrid(filteredPlaylists, musicProvider),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────── SEARCH LOGIC ─────────────────────────────────

  Map<String, List<SongModel>> _filterAndSearchPlaylists(
    Map<String, List<SongModel>> playlists,
  ) {
    Map<String, List<SongModel>> categoryFiltered;

    if (_selectedFilter == "Favorites") {
      categoryFiltered = {"Liked": playlists["Liked"] ?? []};
    } else if (_selectedFilter == "My Mixes") {
      categoryFiltered = Map.fromEntries(
        playlists.entries.where((e) => e.key != "Liked"),
      );
    } else {
      categoryFiltered = playlists;
    }

    if (_searchQuery.isEmpty) return categoryFiltered;

    final query = _searchQuery.toLowerCase();
    final Map<String, List<SongModel>> results = {};

    for (final entry in categoryFiltered.entries) {
      final playlistName = entry.key.toLowerCase();
      final songs = entry.value;

      final nameMatch = playlistName.contains(query);
      final songMatch = songs.any(
        (song) =>
            song.title.toLowerCase().contains(query) ||
            (song.artist?.toLowerCase().contains(query) ?? false),
      );

      if (nameMatch || songMatch) {
        results[entry.key] = entry.value;
      }
    }
    return results;
  }

  // ───────────────────────────────── UI SECTIONS ─────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    Map<String, List<SongModel>> allPlaylists,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _showProfileMenu(context),
          child: const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFD4A574),
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white70, size: 28),
          onPressed: () => _showMoreOptions(context),
        ),
      ],
    );
  }

  Widget _buildTitleSection(BuildContext context, MusicProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Playlists",
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        GestureDetector(
          onTap: () => _showCreatePlaylistDialog(context, provider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF5D3FD3).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF5D3FD3).withOpacity(0.5),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.add, color: Color(0xFF8F94FB), size: 18),
                SizedBox(width: 4),
                Text(
                  "NEW",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    final filters = ["All Playlists", "Favorites", "My Mixes"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map(
              (filter) => FilterTab(
                label: filter,
                isSelected: _selectedFilter == filter,
                onTap: () => setState(() => _selectedFilter = filter),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPlaylistGrid(
    Map<String, List<SongModel>> filtered,
    MusicProvider provider,
  ) {
    if (filtered.isEmpty) return _buildEmptyState();

    return Expanded(
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 20,
          childAspectRatio: 0.8,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final name = filtered.keys.elementAt(index);
          final count = filtered[name]?.length ?? 0;
          final isLiked = name == "Liked";

          return PlaylistCard(
            name: name,
            songCount: count,
            isLiked: isLiked,
            gradientColors: _getGradientForIndex(index, isLiked),
            iconType: _getImageForIndex(index, isLiked),
            onTap: () => _navigateToPlaylistDetail(context, name, provider),
            onLongPress: () => _showPlaylistOptions(context, name, provider),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Expanded(
      child: Center(
        child: Text(
          "No playlists found.",
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }

  // ───────────────────────── CREATE PLAYLIST (FIXED) ─────────────────────────

  void _showCreatePlaylistDialog(BuildContext context, MusicProvider provider) {
    final TextEditingController controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Give your playlist a name",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 22),
              decoration: const InputDecoration(
                hintText: "My playlist #1",
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF1DB954)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white60, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isNotEmpty) {
                        provider.createPlaylist(name);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 230, 209, 22),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      "Create",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────── HELPERS ─────────────────────────────────

  List<Color> _getGradientForIndex(int index, bool isLiked) {
    if (isLiked) return [const Color(0xFFE91E63), const Color(0xFF9C27B0)];
    final gradients = [
      [const Color(0xFF4A90E2), const Color(0xFF50C9C3)],
      [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)],
      [const Color(0xFF4E54C8), const Color(0xFF8F94FB)],
      [const Color(0xFFFF9A56), const Color(0xFFFF6A88)],
    ];
    return gradients[index % gradients.length];
  }

  String? _getImageForIndex(int index, bool isLiked) {
    if (isLiked) return 'heart';
    final images = [
      'car',
      'meditation',
      'neon',
      'citylight',
      'abstract',
      'coffee',
      'vinyl',
    ];
    return images[index % images.length];
  }

  void _navigateToPlaylistDetail(
    BuildContext context,
    String name,
    MusicProvider provider,
  ) {
    final songs = provider.allPlaylists[name] ?? [];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PlaylistDetailScreen(playlistName: name, songs: songs),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {}
  void _showMoreOptions(BuildContext context) {}
  void _showPlaylistOptions(
    BuildContext context,
    String name,
    MusicProvider provider,
  ) {}
}
