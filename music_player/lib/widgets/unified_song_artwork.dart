import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class UnifiedSongArtwork extends StatelessWidget {
  final int songId;
  final String? customArtworkPath;
  final String? defaultArtworkPath;
  final double size;
  final double borderRadius;
  final bool isCircular;

  const UnifiedSongArtwork({
    super.key,
    required this.songId,
    this.customArtworkPath,
    this.defaultArtworkPath,
    this.size = 50,
    this.borderRadius = 8,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = isCircular ? size / 2 : borderRadius;

    // 1. Check Custom Artwork
    if (customArtworkPath != null && File(customArtworkPath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(
          File(customArtworkPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildQueryArtwork(radius),
        ),
      );
    }

    return _buildQueryArtwork(radius);
  }

  Widget _buildQueryArtwork(double radius) {
    // 2. Prepare Default/Fallback Widget
    Widget fallbackWidget;
    
    if (defaultArtworkPath != null && File(defaultArtworkPath!).existsSync()) {
        fallbackWidget = Image.file(
          File(defaultArtworkPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
    } else {
        fallbackWidget = Container(
          width: size,
          height: size,
          color: Colors.white10,
          child: Icon(Icons.music_note, color: Colors.white54, size: size * 0.5),
        );
    }

    // Wrap fallback in clip logic
    final clippedFallback = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: fallbackWidget,
    );

    // 3. Use QueryArtworkWidget
    return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: QueryArtworkWidget(
          id: songId,
          type: ArtworkType.AUDIO,
          artworkWidth: size,
          artworkHeight: size,
          artworkFit: BoxFit.cover,
          nullArtworkWidget: clippedFallback,
          keepOldArtwork: true,
        ),
    );
  }
}
