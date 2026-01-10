// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../logic/music_provider.dart';
import '../widgets/filter_tab.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedCategory = "Songs";

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A12),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildTopNavBar(context),
                const SizedBox(height: 25),
                _buildCategoryTabs(),
                const SizedBox(height: 20),
                _buildShuffleButton(musicProvider),
                const SizedBox(height: 20),
                Expanded(child: _buildCategoryContent(musicProvider)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Library",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white, size: 28),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ["Songs", "Albums", "Artists", "Genres"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map(
              (cat) => FilterTab(
                label: cat,
                isSelected: _selectedCategory == cat,
                onTap: () => setState(() => _selectedCategory = cat),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildShuffleButton(MusicProvider provider) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          provider.shuffleAndPlay();
        },
        icon: const Icon(Icons.shuffle, color: Colors.white, size: 20),
        label: const Text(
          "SHUFFLE ALL",
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5D3FD3),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: const StadiumBorder(),
          elevation: 5,
        ),
      ),
    );
  }

  Widget _buildCategoryContent(MusicProvider provider) {
    final songs = provider.allSongs;

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5D3FD3)),
      );
    }

    if (songs.isEmpty) {
      return const Center(
        child: Text(
          "No songs found on your device.",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: provider.currentSong != null ? 160 : 20),
      itemBuilder: (context, index) {
        final song = songs[index];

        // 🔧 FIX: Check for custom internet artwork path
        final String? customPath = provider.getCustomArtwork(song.id);

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            // Logic to display Internet Art -> System Art -> Default Icon
            child: customPath != null && File(customPath).existsSync()
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(customPath), fit: BoxFit.cover),
                  )
                : QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: const Icon(
                      Icons.music_note,
                      color: Colors.white54,
                    ),
                  ),
          ),
          title: Text(
            song.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            song.artist,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          trailing: const Icon(Icons.more_horiz, color: Colors.white54),
          onTap: () {
            provider.playSong(index);
          },
        );
      },
    );
  }
}
