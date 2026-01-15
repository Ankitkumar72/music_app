// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../logic/music_provider.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  Color _backgroundColor = Colors.grey;
  int? _lastSongId;

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

  Future<void> _updatePalette(int songId) async {
    // Only update if song has changed
    if (_lastSongId == songId) return;
    _lastSongId = songId;

    // Use gradient-based color directly (NetworkImage with content:// doesn't work)
    if (mounted) {
      setState(() {
        _backgroundColor = _generateSongGradient(songId)[0];
      });
    }
  }

  Widget _buildArtwork({
    required int songId,
    required String? customArtworkPath,
    required List<Color> gradientColors,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    // Prioritize custom downloaded artwork
    if (customArtworkPath != null && File(customArtworkPath).existsSync()) {
      return Image.file(
        File(customArtworkPath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to QueryArtworkWidget if file fails
          return _buildQueryArtwork(
            songId: songId,
            gradientColors: gradientColors,
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    }
    
    // Fallback to QueryArtworkWidget for embedded artwork
    return _buildQueryArtwork(
      songId: songId,
      gradientColors: gradientColors,
      width: width,
      height: height,
      fit: fit,
    );
  }

  Widget _buildQueryArtwork({
    required int songId,
    required List<Color> gradientColors,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    // QueryArtworkWidget doesn't accept nullable width/height,
    // so we build it differently based on whether dimensions are provided
    if (width != null && height != null) {
      return QueryArtworkWidget(
        id: songId,
        type: ArtworkType.AUDIO,
        artworkFit: fit,
        artworkHeight: height,
        artworkWidth: width,
        nullArtworkWidget: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: width < 50
              ? const Icon(
                  Icons.music_note,
                  color: Colors.white70,
                  size: 20,
                )
              : null,
        ),
      );
    } else {
      // For background images without specific dimensions
      return QueryArtworkWidget(
        id: songId,
        type: ArtworkType.AUDIO,
        artworkFit: fit,
        nullArtworkWidget: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final currentSong = musicProvider.currentSong;

    if (currentSong == null) return const SizedBox.shrink();

    // Update palette when song changes
    _updatePalette(currentSong.id);

    final gradientColors = _generateSongGradient(currentSong.id);
    final customArtworkPath = musicProvider.getCustomArtwork(currentSong.id);

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
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Stack(
          children: [
            // LAYER 1: Background Image
            Positioned.fill(
              child: _buildArtwork(
                songId: currentSong.id,
                customArtworkPath: customArtworkPath,
                gradientColors: gradientColors,
                fit: BoxFit.cover,
              ),
            ),

            // LAYER 2: Blur Effect & Gradient Overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _backgroundColor.withOpacity(0.4),
                          _backgroundColor.withOpacity(0.8),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // LAYER 3: Player Controls & Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildArtwork(
                        songId: currentSong.id,
                        customArtworkPath: customArtworkPath,
                        gradientColors: gradientColors,
                        width: 45,
                        height: 45,
                        fit: BoxFit.cover,
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
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            (currentSong.artist == "<unknown>")
                                ? "Local file"
                                : currentSong.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ⏮ Controls
                    IconButton(
                      onPressed: musicProvider.playPrevious,
                      icon: const Icon(Icons.skip_previous, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: musicProvider.togglePlay,
                      icon: Icon(
                        musicProvider.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: musicProvider.skipToNext,
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
