import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:io';

import '../logic/Models/song_data.dart';

import '../logic/music_provider.dart';
import '../widgets/mini_player_safe_scroll.dart';
import '../widgets/mini_player.dart';
import '../widgets/unified_song_artwork.dart';

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
                          child: UnifiedSongArtwork(
                            songId: song.id,
                            customArtworkPath: musicProvider.getCustomArtwork(song.id),
                            defaultArtworkPath: musicProvider.defaultArtworkPath,
                            size: 50,
                          ),
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
  

}
