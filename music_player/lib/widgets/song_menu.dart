import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/Models/song_data.dart';
import '../logic/music_provider.dart';

/// Shows a bottom sheet menu with options for a song
void showSongMenu(BuildContext context, SongData song) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A24),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _SongMenuContent(song: song, parentContext: context),
  );
}

class _SongMenuContent extends StatelessWidget {
  final SongData song;
  final BuildContext parentContext;

  const _SongMenuContent({
    required this.song,
    required this.parentContext,
  });

  void _showNotification(BuildContext context, String message, IconData icon) {
    ScaffoldMessenger.of(parentContext).clearSnackBars();
    ScaffoldMessenger.of(parentContext).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF5D3FD3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, MusicProvider provider, SongData song) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete from Library?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${song.title}"',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This song will be hidden from your library permanently. You can restore it from Settings > Excluded Songs.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.excludeSong(song);
              _showNotification(
                context,
                'Removed from library',
                Icons.delete_outline,
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaylistSelector(BuildContext context) {
    final provider = context.read<MusicProvider>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Add to Playlist",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Liked Songs option
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.red, size: 22),
                ),
                title: const Text(
                  "Liked Songs",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                trailing: provider.isLiked(song)
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
                    : null,
                onTap: () {
                  final wasLiked = provider.isLiked(song);
                  provider.toggleLike(song);
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  _showNotification(
                    context,
                    wasLiked ? 'Removed from Liked Songs' : 'Added to Liked Songs',
                    wasLiked ? Icons.favorite_border : Icons.favorite,
                  );
                },
              ),

              const Divider(color: Colors.white10, height: 1),

              // User playlists
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.playlistNames.length,
                  itemBuilder: (listCtx, index) {
                    final name = provider.playlistNames[index];
                    if (name == 'Liked') return const SizedBox.shrink();
                    
                    final isInPlaylist = provider.allPlaylists[name]
                        ?.any((s) => s.id == song.id) ?? false;
                    
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D3FD3).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.queue_music,
                          color: Color(0xFF5D3FD3),
                          size: 22,
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: isInPlaylist
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
                          : null,
                      onTap: () {
                        if (!isInPlaylist) {
                          provider.addToPlaylist(name, song);
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                          _showNotification(
                            context,
                            'Added to "$name"',
                            Icons.playlist_add_check,
                          );
                        } else {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                          _showNotification(
                            context,
                            'Already in "$name"',
                            Icons.info_outline,
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final isLiked = provider.isLiked(song);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header with song info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white54, size: 24),
                ),
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
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            iconColor: isLiked ? Colors.red : const Color(0xFF6332F6),
            title: isLiked ? 'Remove from Liked' : 'Add to Liked',
            subtitle: 'Manage your favorites',
            onTap: () {
              provider.toggleLike(song);
              Navigator.pop(context);
              _showNotification(
                context,
                isLiked ? 'Removed from Liked Songs' : 'Added to Liked Songs',
                isLiked ? Icons.favorite_border : Icons.favorite,
              );
            },
          ),
          _buildMenuOption(
            context,
            icon: Icons.playlist_add,
            title: 'Add to Playlist',
            subtitle: 'Save to your playlists',
            onTap: () => _showPlaylistSelector(context),
          ),
          _buildMenuOption(
            context,
            icon: Icons.delete_outline,
            iconColor: Colors.red.shade300,
            title: 'Delete from Library',
            subtitle: 'Hide this song permanently',
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(parentContext, provider, song);
            },
          ),
          _buildMenuOption(
            context,
            icon: Icons.info_outline,
            title: 'Song Details',
            subtitle: 'View metadata information',
            onTap: () {
              Navigator.pop(context);
              _showSongDetails(parentContext, song);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF6332F6),
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
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
}
