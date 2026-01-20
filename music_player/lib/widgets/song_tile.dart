import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/Models/song_data.dart'; 
import '../logic/music_provider.dart';
import 'song_menu.dart';
import 'unified_song_artwork.dart';

class SongTile extends StatelessWidget {
  final SongData song;
  final VoidCallback onTap;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Watch provider to get updates on artwork
    final provider = context.watch<MusicProvider>();

    return ListTile(
      onTap: onTap,
      onLongPress: () => showSongMenu(context, song),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      
      // Leading: Unified Album Art
      leading: UnifiedSongArtwork(
        songId: song.id,
        customArtworkPath: provider.getCustomArtwork(song.id),
        defaultArtworkPath: provider.defaultArtworkPath,
        size: 50,
      ),

      // Title: Bold and handles long names with ellipsis
      title: Text(
        song.title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.white,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),

      // Subtitle: Artist Name (smaller and greyed out)
      subtitle: Text(
        song.artist,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[400],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),

      // Trailing: Options Menu
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, color: Colors.grey),
        onPressed: () => showSongMenu(context, song),
      ),
    );
  }
}
