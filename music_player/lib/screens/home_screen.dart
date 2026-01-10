// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../logic/models/song_data.dart';
import '../logic/music_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the provider to react to new playlists or history changes
    final musicProvider = context.watch<MusicProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. App Bar with Profile and Notifications
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Color(0xFF6332F6),
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Good Evening",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  "Pixy",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none),
              ),
            ],
          ),

          // 2. DYNAMIC Category Chips (Synced with your Hive Playlists)
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

          // 4. Large Horizontal Cards (Daily Mix 1 & Discovery)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 350,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Daily Mix 1: Dynamic artists from songs played 3+ times
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
                  // Discovery: Picks 10 random songs from your library
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

          // Bottom Padding for Mini Player and Navigation Bar
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
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
        provider.setActiveCategory(label); // Update selection state
        final playlistSongs =
            provider.allPlaylists[label] ?? []; // Fetch specific playlist data

        // Navigate directly to the detailed view of the selected playlist
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

  // --- Helper: Large Horizontal Cards ---
  Widget _buildLargeDailyMixCard(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    List<SongData> songList,
  ) {
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFFFD700),
              child: Icon(Icons.play_arrow, color: Colors.black),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper: Small Square Cards with Artwork logic ---
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
      body: CustomScrollView(
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
                  song.artist,
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () => context.read<MusicProvider>().playSong(
                  index,
                  customList: songs,
                ),
              );
            }, childCount: songs.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
