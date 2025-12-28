import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/music_provider.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Optimized: Only rebuilds if the playlist NAMES change
    final names = context.select((MusicProvider p) => p.playlistNames);
    final provider = context.read<MusicProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Your Library",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.amber),
            onPressed: () => _showCreatePlaylistDialog(context, provider),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: names.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final name = names[index];
          // Optimized: Only get the count for this specific item
          final songCount = provider.allPlaylists[name]?.length ?? 0;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            tileColor: Colors.white10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF6332F6),
              child: Icon(Icons.music_note, color: Colors.white),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "$songCount songs",
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: name == "Liked Songs"
                ? null
                : const Icon(Icons.chevron_right),
            onLongPress: () {
              if (name != "Liked Songs") provider.deletePlaylist(name);
            },
          );
        },
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, MusicProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("New Playlist"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Playlist Name"),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              provider.createPlaylist(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }
}
