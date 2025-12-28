import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final OnAudioQuery audioQuery = OnAudioQuery();

    return Scaffold(
      appBar: AppBar(title: const Text("Library"), elevation: 0),
      body: FutureBuilder<List<SongModel>>(
        future: audioQuery.querySongs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100), // Space for MiniPlayer
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final song = snapshot.data![index];
              return ListTile(
                leading: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                ),
                title: Text(song.title),
                subtitle: Text(song.artist ?? "Unknown"),
              );
            },
          );
        },
      ),
    );
  }
}
