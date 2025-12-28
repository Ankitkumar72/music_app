import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../logic/music_provider.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final currentSong = musicProvider.currentSong;

    // Hide mini player if nothing is playing
    if (currentSong == null) return const SizedBox.shrink();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const NowPlayingScreen(),
        );
      },
      child: Container(
        height: 70,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            // 🎵 Artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: QueryArtworkWidget(
                id: currentSong.id,
                type: ArtworkType.AUDIO,
                artworkHeight: 45,
                artworkWidth: 45,
                nullArtworkWidget: Container(
                  width: 45,
                  height: 45,
                  color: Colors.grey,
                  child: const Icon(Icons.music_note),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 🎶 Song Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentSong.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    currentSong.artist ?? "Unknown Artist",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // ⏮ Controls (do NOT trigger bottom sheet)
            IconButton(
              onPressed: musicProvider.playPrevious,
              icon: const Icon(Icons.skip_previous),
            ),
            IconButton(
              onPressed: musicProvider.togglePlay,
              icon: Icon(
                musicProvider.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 40,
                color: const Color(0xFF6332F6),
              ),
            ),
            IconButton(
              onPressed: musicProvider.playNext,
              icon: const Icon(Icons.skip_next),
            ),
          ],
        ),
      ),
    );
  }
}
