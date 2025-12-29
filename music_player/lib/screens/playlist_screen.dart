// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final allPlaylists = musicProvider.allPlaylists;
    final filteredPlaylists = _filterPlaylists(allPlaylists);

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
              _buildTitleSection(context),
              const SizedBox(height: 25),
              _buildFilterTabs(),
              const SizedBox(height: 25),
              _buildPlaylistGrid(filteredPlaylists, musicProvider),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(context, musicProvider),
    );
  }

  // --- UI SECTIONS ---

  Widget _buildHeader(
    BuildContext context,
    Map<String, List<dynamic>> allPlaylists,
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
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white70, size: 28),
              onPressed: () => _showSearchDialog(context, allPlaylists),
            ),
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white70,
                size: 28,
              ),
              onPressed: () => _showMoreOptions(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleSection(BuildContext context) {
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
        _buildIconButton(Icons.grid_view_rounded, () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Grid view active')));
        }),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        child: Icon(icon, color: Colors.white70, size: 22),
      ),
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
    Map<String, List<dynamic>> filtered,
    MusicProvider provider,
  ) {
    if (filtered.isEmpty) return _buildEmptyState();

    return Expanded(
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 20,
          childAspectRatio: 0.8,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          String name = filtered.keys.elementAt(index);
          int count = filtered[name]?.length ?? 0;
          bool isLiked = name == "Liked";

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
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_add,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedFilter == "All Playlists"
                  ? "No playlists found.\nCreate your first one!"
                  : "No playlists in this category",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context, MusicProvider provider) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreatePlaylistDialog(context, provider),
      backgroundColor: const Color(0xFF5D3FD3),
      elevation: 8,
      icon: const Icon(Icons.add, color: Colors.white, size: 24),
      label: const Text(
        "New Playlist",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // --- LOGIC & DIALOGS ---

  Map<String, List<dynamic>> _filterPlaylists(
    Map<String, List<dynamic>> playlists,
  ) {
    if (_selectedFilter == "Favorites") {
      return {"Liked": playlists["Liked"] ?? []};
    } else if (_selectedFilter == "My Mixes") {
      return Map.fromEntries(
        playlists.entries.where((entry) => entry.key != "Liked"),
      );
    }
    return playlists;
  }

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

  // (Helper Dialogs: Profile, Search, Options, Create, Rename, Delete)
  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text(
              "View Profile",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(
    BuildContext context,
    Map<String, List<dynamic>> playlists,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          "Search Playlists",
          style: TextStyle(color: Colors.white),
        ),
        content: const TextField(style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (context) => ListTile(
        leading: const Icon(Icons.sort, color: Colors.white),
        title: const Text(
          "Sort Playlists",
          style: TextStyle(color: Colors.white),
        ),
        onTap: () => Navigator.pop(context),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, MusicProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          "New Playlist",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.createPlaylist(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(
    BuildContext context,
    String name,
    MusicProvider provider,
  ) {
    if (name == "Liked") return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (context) => ListTile(
        leading: const Icon(Icons.delete, color: Colors.red),
        title: const Text(
          "Delete Playlist",
          style: TextStyle(color: Colors.red),
        ),
        onTap: () {
          provider.deletePlaylist(name);
          Navigator.pop(context);
        },
      ),
    );
  }
}
