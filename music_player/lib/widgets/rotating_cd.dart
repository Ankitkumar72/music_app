import 'dart:math';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:io';

class RotatingCD extends StatefulWidget {
  final int songId;
  final bool isPlaying;
  final String? customArtworkPath;

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
      [const Color(0xFF6A4CF6), const Color(0xFF4A2EC7)], 
      [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)], 
      [const Color(0xFF2193b0), const Color(0xFF6dd5ed)], 
      [const Color(0xFF0F0C29), const Color(0xFF302B63)],
      [const Color(0xFFEE0979), const Color(0xFFFF6A00)], 
      [const Color(0xFF11998E), const Color(0xFF38EF7D)], 
      [const Color(0xFFcc2b5e), const Color(0xFF753a88)], 
    ];
    return gradients[seed.abs() % gradients.length];
  }

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
          // Shape set back to circle
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.45),
              blurRadius: 60,
              spreadRadius: 6,
            ),
          ],
        ),
        child: ClipOval(
          // This keeps the image in a perfect circle
          child: widget.customArtworkPath != null &&
                  File(widget.customArtworkPath!).existsSync()
              ? Image.file(
                  File(widget.customArtworkPath!),
                  width: 280,
                  height: 280,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildQueryArtwork(colors);
                  },
                )
              : _buildQueryArtwork(colors),
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
        child: const Center(
          child: Icon(
            Icons.music_note,
            size: 80,
            color: Colors.white38,
          ),
        ),
      ),
    );
  }
}