// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../logic/Models/song_data.dart';
import '../logic/music_provider.dart';
import '../widgets/mini_player.dart';

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
              // 1. Header with Gradient and Title
              SliverAppBar(
                expandedHeight: 250,
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
                    child: Center(
                      child: Icon(
                        Icons.music_note,
                        size: 80,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Shuffle Play Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => context.read<MusicProvider>().playSong(
                      0,
                      customList: songs,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      "PLAY MIX",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              // 3. The Song List
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = songs[index];
                  return ListTile(
                    leading: QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      nullArtworkWidget: const Icon(
                        Icons.music_note,
                        color: Colors.white24,
                      ),
                    ),
                    title: Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song.artist,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    onTap: () {
                      context.read<MusicProvider>().playSong(
                        index,
                        customList: songs,
                      );
                    },
                  );
                }, childCount: songs.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          
          // Mini Player at the bottom
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
