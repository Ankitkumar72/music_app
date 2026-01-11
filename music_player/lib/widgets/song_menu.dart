import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/Models/song_data.dart';
import '../logic/music_provider.dart';
import 'artwork_search_dialog.dart';

/// Shows a bottom sheet menu with options for a song
void showSongMenu(BuildContext context, SongData song) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A24),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with song info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.music_note, color: Colors.white54, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 24),

          // Menu Options
          _buildMenuOption(
            context,
            icon: Icons.image_search,
            title: 'Fix Artwork',
            subtitle: 'Search for the correct album cover',
            onTap: () {
              Navigator.pop(context); // Close menu
              showDialog(
                context: context,
                builder: (context) => ArtworkSearchDialog(song: song),
              );
            },
          ),
          _buildMenuOption(
            context,
            icon: Icons.playlist_add,
            title: 'Add to Playlist',
            subtitle: 'Save to your playlists',
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement playlist selection
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Playlist feature coming soon!')),
              );
            },
          ),
          _buildMenuOption(
            context,
            icon: Icons.info_outline,
            title: 'Song Details',
            subtitle: 'View metadata information',
            onTap: () {
              Navigator.pop(context);
              _showSongDetails(context, song);
            },
          ),
          Builder(
            builder: (context) {
              final isLiked = context.watch<MusicProvider>().isLiked(song);
              return _buildMenuOption(
                context,
                icon: Icons.favorite_border,
                title: isLiked ? 'Remove from Liked' : 'Add to Liked',
                subtitle: 'Manage your favorites',
                onTap: () {
                  context.read<MusicProvider>().toggleLike(song);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ],
      ),
    ),
  );
}

Widget _buildMenuOption(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: const Color(0xFF6332F6)),
    title: Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: Colors.white54, fontSize: 12),
    ),
    onTap: onTap,
  );
}

void _showSongDetails(BuildContext context, SongData song) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Song Details',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Title', song.title),
          _buildDetailRow('Artist', song.artist),
          _buildDetailRow('ID', song.id.toString()),
          _buildDetailRow('Path', song.data),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: Color(0xFF6332F6)),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
