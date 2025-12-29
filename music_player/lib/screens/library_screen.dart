import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    // context.watch ensures the UI updates when notifyListeners() is called in the provider
    final musicProvider = context.watch<MusicProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // --- TOP NAVBAR AREA ---
              _buildTopNavBar(context),

              const SizedBox(height: 25),

              // --- CATEGORY TABS ---
              _buildCategoryTabs(),

              const SizedBox(height: 20),

              // --- SHUFFLE ALL BUTTON ---
              _buildShuffleButton(musicProvider),

              const SizedBox(height: 20),

              // --- SONG/ITEM LIST ---
              Expanded(child: _buildCategoryContent(musicProvider)),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Library Title and Search Button
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
          onPressed: () {
            // Logic for searching within the library
          },
        ),
      ],
    );
  }

  // 2. Categories: Songs, Albums, Artists, Genres
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

  // 3. Round Shuffle All Button - Linked to MusicProvider
  Widget _buildShuffleButton(MusicProvider provider) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          // Calls the shuffleAndPlay method we added to your provider
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

  // 4. Content based on selected category - Now using REAL data
  Widget _buildCategoryContent(MusicProvider provider) {
    // Use the actual song list from the provider
    final songs = provider.allSongs;

    // Show a loading indicator if the app is still fetching songs
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5D3FD3)),
      );
    }

    // Handle the empty state if no songs are found on the device
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
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_note, color: Colors.white54),
          ),
          title: Text(
            song.title, // Accesses the real title from SongModel
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            song.artist ?? "Unknown Artist", // Accesses the real artist
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          trailing: const Icon(Icons.more_horiz, color: Colors.white54),
          onTap: () {
            // Plays the specific song from the library
            provider.playSong(index);
          },
        );
      },
    );
  }
}
