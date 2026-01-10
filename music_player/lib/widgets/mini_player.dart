import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';


import '../logic/music_provider.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  List<Color> _generateSongGradient(int seed) {
    final gradients = [
      [const Color(0xFF4E54C8), const Color(0xFF8F94FB)],
      [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)],
      [const Color(0xFF2193b0), const Color(0xFF6dd5ed)],
      [const Color(0xFF1DB954), const Color(0xFF1ED760)],
      [const Color(0xFFcc2b5e), const Color(0xFF753a88)],
    ];
    return gradients[seed.abs() % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final currentSong = musicProvider.currentSong;

    if (currentSong == null) return const SizedBox.shrink();

    final gradientColors = _generateSongGradient(currentSong.id);

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
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: QueryArtworkWidget(
                id: currentSong.id,
                type: ArtworkType.AUDIO,
                artworkHeight: 45,
                artworkWidth: 45,
                nullArtworkWidget: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white70,
                    size: 20,
                  ),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    (currentSong.artist == "<unknown>")
                        ? "Local file"
                        : currentSong.artist,
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
                color: gradientColors[1],
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
