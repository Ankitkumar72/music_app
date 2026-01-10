import 'dart:math';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:io';

class RotatingCD extends StatefulWidget {
  final int songId;
  final bool isPlaying;
  final String? customArtworkPath; // Add custom artwork support

  const RotatingCD({
    super.key,
    required this.songId,
    required this.isPlaying,
    this.customArtworkPath,
  });

  @override
  State<RotatingCD> createState() => _RotatingCDState();
}

class _RotatingCDState extends State<RotatingCD>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int _hashSeed(int value) {
    var x = value;
    x = ((x >> 16) ^ x) * 0x45d9f3b;
    x = ((x >> 16) ^ x) * 0x45d9f3b;
    x = (x >> 16) ^ x;
    return x;
  }

  List<Color> _generateSongGradient(int seed) {
    final gradients = [
      [const Color(0xFF6A4CF6), const Color(0xFF4A2EC7)], // purple
      [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)], // red-yellow
      [const Color(0xFF2193b0), const Color(0xFF6dd5ed)], // blue-cyan
      [const Color(0xFF0F0C29), const Color(0xFF302B63)],
      [
        const Color(0xFFEE0979),
        const Color(0xFFFF6A00),
      ], // Lush (Vibrant/Dance)
      [const Color(0xFF11998E), const Color(0xFF38EF7D)], // teal-green
      [const Color(0xFFcc2b5e), const Color(0xFF753a88)], // magenta
    ];
    return gradients[seed.abs() % gradients.length];
  }

  // ───────── ROTATION ─────────
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );

    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant RotatingCD oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.isPlaying ? _controller.repeat() : _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ───────── UI ─────────
  @override
  Widget build(BuildContext context) {
    final colors = _generateSongGradient(_hashSeed(widget.songId));

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Transform.rotate(
          angle: _controller.value * 2 * pi,
          child: _buildDisc(colors),
        );
      },
    );
  }

  Widget _buildDisc(List<Color> colors) {
    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,

          // Soft glow halo (always visible)
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.45),
              blurRadius: 60,
              spreadRadius: 6,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Main album artwork - prioritize custom downloaded artwork
            ClipOval(
              child: widget.customArtworkPath != null &&
                      File(widget.customArtworkPath!).existsSync()
                  ? Image.file(
                      File(widget.customArtworkPath!),
                      width: 280,
                      height: 280,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to QueryArtworkWidget if file fails
                        return _buildQueryArtwork(colors);
                      },
                    )
                  : _buildQueryArtwork(colors),
            ),

            // CD center - filled with gradient to complete the music icon look
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors[1].withValues(alpha: 0.8),
                    colors[0].withValues(alpha: 0.6),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueryArtwork(List<Color> colors) {
    return QueryArtworkWidget(
      id: widget.songId,
      type: ArtworkType.AUDIO,
      artworkWidth: 280,
      artworkHeight: 280,
      artworkFit: BoxFit.cover,
      quality: 100,
      artworkQuality: FilterQuality.high,
      keepOldArtwork: true,
      nullArtworkWidget: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [colors[0], colors[1], const Color(0xFF0B0B0B)],
            radius: 0.9,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.music_note,
            size: 80,
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
