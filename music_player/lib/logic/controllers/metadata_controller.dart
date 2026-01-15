import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../Models/song_data.dart';
import '../audio_handler.dart';

/// 🧠 MetadataController (The Brain of Metadata)
/// 
/// Purpose:
/// 🔹 Owns current song metadata
/// 🔹 Owns artwork resolution
/// 🔹 Owns notification updates
/// 
/// Rules:
/// ✅ Only class allowed to call audioHandler.updateMediaItem(...)
/// ✅ Atomic updates (title + artist + artwork together)
/// ❌ Never reacts to playbackState directly
class MetadataController {
  final AudioPlayerHandler? _handler;
  final AudioPlayer _player;
  
  Timer? _debounceTimer;
  String? _transparentArtworkPath;

  MetadataController(this._handler, this._player) {
    _initTransparentImage();
  }

  /// Generate a 1x1 transparent PNG to force Android to clear artwork
  Future<void> _initTransparentImage() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/transparent_1x1.png');
      
      if (!await file.exists()) {
        // Base64 for 300x300 transparent PNG
        // 1x1 is often ignored by Android MediaStyle, causing the old artwork to stick.
        // We use a larger dimension to ensure it replaces the buffer.
        final bytes = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAASwAAAEsCAYAAAB5fY51AAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAALEgAACxIB0t1+/AAAABZ0RVh0Q3JlYXRpb24gVGltZQAwMS8xNS8yNlDv4QkAAAAcdEVYdFNvZnR3YXJlAEFkb2JlIEZpcmV3b3JrcyBDUzQGstOgAAAAB3RJTUUH6gEPDRQA8xYqJAAAABR0RVh0Q29tbWVudABDb3B5cmlnaHQgMjAyNqWqVOcAAAA5SURBVGje7cExAQAAAMKg9U9tDQ+gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOAOs54AAX+DeEAAAAAASUVORK5CYII='
        );
        await file.writeAsBytes(bytes);
      }
      
      _transparentArtworkPath = file.path;
      // Use Unique Cache Buster to force reload (even if file is same)
      // Note: File URIs don't support query params well in all Android versions, 
      // but the size change itself should trigger a refresh now.
      debugPrint("✅ [MetadataCtrl] Transparent 300x300 placeholder ready");
    } catch (e) {
      debugPrint("❌ [MetadataCtrl] Failed to create transparent image: $e");
    }
  }

  /// 🔒 Main Entry Point: Update metadata for a specific song
  /// This is the "Single Source of Truth" update.
  void updateForSong(SongData song, {String? artworkPath}) {
    _scheduleUpdate(() {
      _performUpdate(song, artworkPath);
    });
  }

  /// Debounce the update to prevent notification spam
  void _scheduleUpdate(VoidCallback action) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 80), action);
  }

  /// The actual update logic (Atomic)
  void _performUpdate(SongData song, String? artworkPath) {
    if (_handler == null) return;

    debugPrint("🎵 [MetadataCtrl] Updating: ${song.title}");
    debugPrint("   Artwork: ${artworkPath ?? 'NONE'}");

    final artUri = artworkPath != null 
        ? Uri.file(artworkPath)
        : (_transparentArtworkPath != null 
            ? Uri.file(_transparentArtworkPath!) 
            : null); // Fallback if file gen failed (unlikely)

    final mediaItem = MediaItem(
      id: song.data,
      title: song.title,
      artist: song.artist.isEmpty ? 'Unknown Artist' : song.artist,
      album: song.artist.isEmpty ? 'Unknown Album' : song.artist,
      artUri: artUri,
      duration: _player.duration,
    );

    // ✅ The ONE place that writes to MediaItem
    _handler!.updateMediaItem(mediaItem);
  }
  
  void dispose() {
    _debounceTimer?.cancel();
  }
}
