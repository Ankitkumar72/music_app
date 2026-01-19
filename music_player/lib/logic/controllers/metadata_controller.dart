import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../Models/song_data.dart';
import '../audio_handler.dart';


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
       
        final bytes = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAASwAAAEsCAYAAAB5fY51AAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAALEgAACxIB0t1+/AAAABZ0RVh0Q3JlYXRpb24gVGltZQAwMS8xNS8yNlDv4QkAAAAcdEVYdFNvZnR3YXJlAEFkb2JlIEZpcmV3b3JrcyBDUzQGstOgAAAAB3RJTUUH6gEPDRQA8xYqJAAAABR0RVh0Q29tbWVudABDb3B5cmlnaHQgMjAyNqWqVOcAAAA5SURBVGje7cExAQAAAMKg9U9tDQ+gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOAOs54AAX+DeEAAAAAASUVORK5CYII='
        );
        await file.writeAsBytes(bytes);
      }
      
      _transparentArtworkPath = file.path;
      
      debugPrint("✅ [MetadataCtrl] Transparent 300x300 placeholder ready");
    } catch (e) {
      debugPrint("❌ [MetadataCtrl] Failed to create transparent image: $e");
    }
  }

  
  void updateForSong(SongData song, {String? artworkPath}) {
    _scheduleUpdate(() {
      _performUpdate(song, artworkPath);
    });
  }

  
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
