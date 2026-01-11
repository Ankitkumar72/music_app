// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../logic/Models/song_data.dart';
import '../logic/music_provider.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_menu.dart';
import '../widgets/blob_background.dart';

// Helper function to get time-based greeting
String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) {
    return "Good Morning";
  } else if (hour < 17) {
    return "Good Afternoon";
  } else {
    return "Good Evening";
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the provider to react to new playlists or history changes
    final musicProvider = context.watch<MusicProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. UPDATED: Centered Greeting Header
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const SizedBox.shrink(), 
            actions: [const SizedBox.shrink()], 
            centerTitle: true, 
            toolbarHeight: 80,
            title: Column(
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.amber,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.1,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: const Color(0xFFFFD700).withOpacity(0.8),
                        offset: const Offset(0, 0),
                      ),
                      Shadow(
                        blurRadius: 25.0,
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                const Text(
                  "Pixy",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 2. DYNAMIC Category Chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: musicProvider.playlistNames.map((name) {
                  return _buildCategoryChip(context, name);
                }).toList(),
              ),
            ),
          ),

          // 3. Your Daily Mix Section Header
          _buildSectionHeader(
            context,
            "✨ Your Daily Mix",
            musicProvider.dailyMixSongs,
            const Color(0xFF5D4037),
          ),

          // 4. Large Horizontal Cards
          SliverToBoxAdapter(
            child: SizedBox(
              height: 350,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildLargeDailyMixCard(
                    context,
                    "Daily Mix 1",
                    musicProvider.dailyMixSongs.isEmpty
                        ? "Play more to build your mix"
                        : musicProvider.dailyMixSongs
                            .map((s) => s.artist)
                            .toSet()
                            .take(3)
                            .join(", "),
                    const Color(0xFF5D4037),
                    musicProvider.dailyMixSongs,
                  ),
                  _buildLargeDailyMixCard(
                    context,
                    "Discovery",
                    "New music picked just for you",
                    const Color(0xFF455A64),
                    musicProvider.discoverySongs,
                  ),
                ],
              ),
            ),
          ),

          // 5. Jump Back In Section Header
          _buildSectionHeader(
            context,
            "Jump Back In",
            musicProvider.recentlyPlayed,
            const Color(0xFF6332F6),
          ),

          // 6. Smaller Square Cards (Recently Played History)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: musicProvider.recentlyPlayed.isEmpty
                  ? const Center(
                      child: Text(
                        "No history",
                        style: TextStyle(color: Colors.white24),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: musicProvider.recentlyPlayed.length,
                      itemBuilder: (context, index) {
                        final song = musicProvider.recentlyPlayed[index];
                        return GestureDetector(
                          onTap: () => musicProvider.playSong(
                            index,
                            customList: musicProvider.recentlyPlayed,
                          ),
                          child: _buildSmallRecentCard(
                            song.title,
                            song.id,
                            musicProvider,
                          ),
                        );
                      },
                    ),
            ),
          ),

          // 🔧 FIX: Dynamic Bottom Padding for Mini Player access
          SliverToBoxAdapter(
            child: SizedBox(
              height: musicProvider.currentSong != null ? 160 : 20,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper: Dynamic Category Chip ---
  Widget _buildCategoryChip(BuildContext context, String label) {
    final provider = context.read<MusicProvider>();
    final isActive = provider.activeCategory == label;

    return GestureDetector(
      onTap: () {
        provider.setActiveCategory(label);
        final playlistSongs = provider.allPlaylists[label] ?? [];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MixDetailScreen(
              title: label,
              songs: playlistSongs,
              themeColor: const Color(0xFF6332F6),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFD700) : Colors.white12,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- Helper: Section Headers with Navigation ---
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    List<SongData> songList,
    Color theme,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MixDetailScreen(
                    title: title,
                    songs: songList,
                    themeColor: theme,
                  ),
                ),
              ),
              child: const Text(
                "SEE ALL",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeDailyMixCard(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    List<SongData> songList,
  ) {
    // Different seed for each card to create unique blob patterns
    final seed = title == "Daily Mix 1" ? 42 : 123;
    final secondaryColor = title == "Daily Mix 1" 
        ? const Color(0xFF8D6E63) // Warm brown for Daily Mix
        : const Color(0xFF607D8B); // Cool blue-grey for Discovery

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MixDetailScreen(title: title, songs: songList, themeColor: color),
        ),
      ),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        child: BlobBackground(
          primaryColor: color,
          secondaryColor: secondaryColor,
          seed: seed,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.black, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper: Small Square Cards ---
  Widget _buildSmallRecentCard(
    String title,
    int songId,
    MusicProvider provider,
  ) {
    final String? customPath = provider.getCustomArtwork(songId);

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: Colors.white12,
              height: 140,
              width: 140,
              child: customPath != null && File(customPath).existsSync()
                  ? Image.file(
                      File(customPath),
                      fit: BoxFit.cover,
                    )
                  : QueryArtworkWidget(
                      id: songId,
                      type: ArtworkType.AUDIO,
                      nullArtworkWidget: const Icon(
                        Icons.music_note,
                        color: Colors.white24,
                        size: 50,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// --- Dynamic Detail Screen Class ---
class MixDetailScreen extends StatelessWidget {
  final String title;
  final List<SongData> songs;
  final Color themeColor;

  const MixDetailScreen({
    super.key,
    required this.title,
    required this.songs,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [themeColor, Colors.black],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = songs[index];
                  final provider = context.read<MusicProvider>();
                  final String? customPath = provider.getCustomArtwork(song.id);
                    return ListTile(
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
                                  color: Colors.white24,
                                ),
                              ),
                      ),
                      title: Text(
                        song.title,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.artist ?? "Unknown Artist",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      onTap: () => context.read<MusicProvider>().playSong(
                            index,
                            customList: songs,
                          ),
                      onLongPress: () => showSongMenu(context, song),
                    );
                }, childCount: songs.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          const Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }
}