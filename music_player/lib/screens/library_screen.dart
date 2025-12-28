import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/music_provider.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();

    return Scaffold(
      body: musicProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : musicProvider.songs.isEmpty
          ? const Center(
              child: Text(
                'No songs found',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: musicProvider.songs.length + 1, // +1 for Shuffle All
              itemBuilder: (context, index) {
                // 🔀 SHUFFLE ALL BUTTON (TOP)
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.shuffle,
                        color: Color(0xFFFFC107),
                      ),
                      title: const Text(
                        'Shuffle All',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Play songs in random order'),
                      tileColor: Colors.white10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        // Enable shuffle and start playback
                        musicProvider.toggleShuffle();
                        musicProvider.playSong(0);
                      },
                    ),
                  );
                }

                // 🎵 NORMAL SONG ITEMS
                final song = musicProvider.songs[index - 1];

                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song.artist?.isNotEmpty == true
                        ? song.artist!
                        : 'Unknown Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    // Disable shuffle when user explicitly selects a song
                    if (musicProvider.isShuffleModeEnabled) {
                      musicProvider.toggleShuffle();
                    }
                    musicProvider.playSong(index - 1);
                  },
                );
              },
            ),
    );
  }
}
