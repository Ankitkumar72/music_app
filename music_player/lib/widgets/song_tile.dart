import 'package:flutter/material.dart';
import '../logic/Models/song_data.dart'; 

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
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      
      // 1. Leading: Album Art with Rounded Corners
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 50,
          height: 50,
          color: Colors.grey[800], // Background color while loading
          child: song.albumArtUrl != null 
            ? Image.network(song.albumArtUrl!, fit: BoxFit.cover)
            : const Icon(Icons.music_note, color: Colors.white70),
        ),
      ),

      // 2. Title: Bold and handles long names with ellipsis
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

      // 3. Subtitle: Artist Name (smaller and greyed out)
      subtitle: Text(
        song.artist,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[400],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),

      // 4. Trailing: Options Menu
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, color: Colors.grey),
        onPressed: () {
          // Add logic for "Add to Playlist", "Delete", etc.
        },
      ),
    );
  }
}