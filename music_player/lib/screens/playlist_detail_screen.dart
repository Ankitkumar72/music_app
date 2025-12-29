import 'package:flutter/material.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistName;
  final List<dynamic> songs;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistName,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
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
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  leading: const Icon(Icons.music_note, color: Colors.white54),
                  title: Text(
                    song.title ?? "Unknown",
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    song.artist ?? "Unknown Artist",
                    style: const TextStyle(color: Colors.white54),
                  ),
                  onTap: () {
                    /* Play logic */
                  },
                );
              },
            ),
    );
  }
}
