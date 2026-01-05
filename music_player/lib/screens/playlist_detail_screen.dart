import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../logic/music_provider.dart';
import '../widgets/mini_player_safe_scroll.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistName;
  final List<SongModel> songs;

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
      body: songs.isEmpty
          ? const Center(
              child: Text(
                "No songs in this playlist yet",
                style: TextStyle(color: Colors.white54),
              ),
            )
          : MiniPlayerSafeScroll(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];

                  return ListTile(
                    leading: const Icon(
                      Icons.music_note,
                      color: Colors.white54,
                    ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      song.artist ?? "Unknown Artist",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    onTap: () {
                      // 🎵 PLAY FROM THIS PLAYLIST
                      musicProvider.playSong(index, customList: songs);
                    },
                  );
                },
              ),
            ),
    );
  }
}
