import 'dart:math';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class RotatingCD extends StatefulWidget {
  final int songId;
  final bool isPlaying;

  const RotatingCD({super.key, required this.songId, required this.isPlaying});

  @override
  State<RotatingCD> createState() => _RotatingCDState();
}

class _RotatingCDState extends State<RotatingCD>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Time for one full rotation
    )..repeat();

    if (!widget.isPlaying) _controller.stop();
  }

  @override
  void didUpdateWidget(RotatingCD oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync animation with the play/pause state
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * pi, // Rotate 360 degrees
          child: child,
        );
      },
      child: Center(
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 30, spreadRadius: 5),
            ],
            // This creates the "CD grooves" effect
            gradient: RadialGradient(
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
              ],
              stops: const [0.4, 0.5, 0.6],
            ),
          ),
          child: ClipOval(
            child: QueryArtworkWidget(
              id: widget.songId,
              type: ArtworkType.AUDIO,
              artworkWidth: 280,
              artworkHeight: 280,
              nullArtworkWidget: Container(
                color: Colors.grey[900],
                child: const Icon(
                  Icons.music_note,
                  size: 100,
                  color: Colors.white12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
