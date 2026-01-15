import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:io';

import '../logic/Models/song_data.dart';

import '../logic/music_provider.dart';
import '../widgets/mini_player_safe_scroll.dart';
import '../widgets/mini_player.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistName;
  final List<SongData> songs;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistName,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.read<MusicProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(playlistName, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          songs.isEmpty
              ? const Center(
                  child: Text(
                    "No songs in this playlist yet",
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : MiniPlayerSafeScroll(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: _buildArtwork(song, musicProvider),
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54),
                        ),
                        onTap: () {
                          // 🎵 PLAY FROM THIS PLAYLIST
                          musicProvider.playSong(index, customList: songs, contextName: playlistName);
                        },
                      );
                    },
                  ),
                ),
          // Mini Player
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
  
  Widget _buildArtwork(SongData song, MusicProvider provider) {
    // Check for custom downloaded artwork first
    final customPath = provider.getCustomArtwork(song.id);
    if (customPath != null && File(customPath).existsSync()) {
      return Image.file(
        File(customPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultArtwork(song.id),
      );
    }
    
    // Fall back to embedded artwork using QueryArtworkWidget
    return QueryArtworkWidget(
      id: song.id,
      type: ArtworkType.AUDIO,
      artworkFit: BoxFit.cover,
      artworkBorder: BorderRadius.zero,
      nullArtworkWidget: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.6),
              Colors.blue.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.music_note, color: Colors.white54, size: 24),
      ),
    );
  }
  
  Widget _buildDefaultArtwork(int songId) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.6),
            Colors.blue.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.music_note, color: Colors.white54, size: 24),
    );
  }
}
