import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import '../logic/music_provider.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  double? _dragValue; // Prevents seekbar glitching
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    // Initialize the rotation for the CD animation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose(); // Required to fix the @mustCallSuper warning
  }
  @override
  void _showPlaylistDialog(BuildContext context, MusicProvider provider, SongModel song) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A2E),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Add to Playlist", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white10),
            ...provider.playlistNames.map((name) => ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.amber),
              title: Text(name),
              onTap: () {
                provider.addToPlaylist(name, song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Added to $name"), duration: const Duration(seconds: 1)),
                );
              },
            )),
          ],
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final currentSong = musicProvider.currentSong;

    if (currentSong == null) {
      return const Scaffold(body: Center(child: Text("No song playing")));
    }

    // --- SYNC ROTATION WITH PLAYBACK STATE ---
    // This ensures the CD spins only when music is actually playing
    if (musicProvider.isPlaying) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      _rotationController.stop();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            // --- HEADER SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 30),
                ),
                const Column(
                  children: [
                    Text(
                      "PLAYING FROM PLAYLIST",
                      style: TextStyle(
                        letterSpacing: 1.5,
                        fontSize: 10,
                        color: Colors.amber,
                      ),
                    ),
                    Text(
                      "Local Library",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),
            const Spacer(),

            // --- ROTATING CD ANIMATION ---
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * pi,
                  child: child,
                );
              },
              child: Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF6332F6,
                        ).withValues(alpha: 0.4), // Dynamic purple glow
                        blurRadius: 50,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: QueryArtworkWidget(
                      id: currentSong.id,
                      type: ArtworkType.AUDIO,
                      artworkWidth: 280,
                      artworkHeight: 280,
                      nullArtworkWidget: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6332F6), Colors.black],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          size: 100,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),

            // --- SONG INFO ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSong.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentSong.artist ?? "Unknown Artist",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => musicProvider.toggleLike(currentSong),
                  onLongPress: () =>
                      _showPlaylistDialog(context, musicProvider, currentSong),
                  child: Icon(
                    musicProvider.isLiked(currentSong)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: musicProvider.isLiked(currentSong)
                        ? Colors.red
                        : Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- SMOOTH SEEKBAR SECTION ---
            StreamBuilder<Duration>(
              stream: musicProvider.player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = musicProvider.player.duration ?? Duration.zero;

                return Column(
                  children: [
                    Slider(
                      activeColor: Colors.amber,
                      inactiveColor: Colors.white12,
                      // Using _dragValue prevents the slider from "snapping" back
                      value:
                          _dragValue ??
                          position.inMilliseconds.toDouble().clamp(
                            0.0,
                            duration.inMilliseconds.toDouble(),
                          ),
                      max: duration.inMilliseconds.toDouble(),
                      onChangeStart: (v) => setState(() => _dragValue = v),
                      onChanged: (v) => setState(() => _dragValue = v),
                      onChangeEnd: (v) {
                        musicProvider.player.seek(
                          Duration(milliseconds: v.toInt()),
                        );
                        setState(() => _dragValue = null);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            // --- PLAYBACK CONTROLS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => musicProvider.toggleShuffle(),
                  icon: Icon(
                    Icons.shuffle,
                    color: musicProvider.isShuffleModeEnabled
                        ? Colors.amber
                        : Colors.white54,
                  ),
                ),
                IconButton(
                  onPressed: () => musicProvider.playPrevious(),
                  icon: const Icon(Icons.skip_previous, size: 40),
                ),
                IconButton(
                  onPressed: () => musicProvider.togglePlay(),
                  icon: Icon(
                    musicProvider.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 70,
                    color: Colors.amber,
                  ),
                ),
                IconButton(
                  onPressed: () => musicProvider.playNext(),
                  icon: const Icon(Icons.skip_next, size: 40),
                ),
                IconButton(
                  onPressed: () => musicProvider.toggleRepeat(),
                  icon: Icon(
                    musicProvider.loopMode == LoopMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                    color: musicProvider.loopMode != LoopMode.off
                        ? Colors.amber
                        : Colors.white54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}
