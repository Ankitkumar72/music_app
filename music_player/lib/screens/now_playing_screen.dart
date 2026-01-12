import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';

import '../logic/music_provider.dart';
import '../logic/Models/song_data.dart';
import '../widgets/rotating_cd.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  double? _dragValue;
  
  // Animation controller for heart button
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnimation;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _heartAnimController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  void _onHeartTap(MusicProvider provider, SongData song) {
    // Trigger animation
    _heartAnimController.forward(from: 0);
    
    // Toggle like
    final wasLiked = provider.isLiked(song);
    provider.toggleLike(song);
    
    // Show notification
    _showNotification(
      wasLiked ? 'Removed from Liked Songs' : 'Added to Liked Songs',
      wasLiked ? Icons.favorite_border : Icons.favorite,
    );
  }

  void _showNotification(String message, IconData icon) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
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

  // ───── PLAYLIST MENU ─────
  void _showPlaylistMenu(BuildContext context, MusicProvider provider) {
    final currentSong = provider.currentSong;
    if (currentSong == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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

              // Liked playlist
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
                trailing: provider.isLiked(currentSong)
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
                    : null,
                onTap: () {
                  final wasLiked = provider.isLiked(currentSong);
                  provider.toggleLike(currentSong);
                  Navigator.pop(context);
                  _showNotification(
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
                  itemBuilder: (context, index) {
                    final name = provider.playlistNames[index];
                    if (name == 'Liked') return const SizedBox.shrink();
                    
                    final isInPlaylist = provider.allPlaylists[name]
                        ?.any((s) => s.id == currentSong.id) ?? false;
                    
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
                          provider.addToPlaylist(name, currentSong);
                          Navigator.pop(context);
                          _showNotification(
                            'Added to "$name"',
                            Icons.playlist_add_check,
                          );
                        } else {
                          Navigator.pop(context);
                          _showNotification(
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
    final musicProvider = context.watch<MusicProvider>();
    final currentSong = musicProvider.currentSong;

    if (currentSong == null) {
      return const Scaffold(body: Center(child: Text("No song playing")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            // ───── HEADER ─────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                const Column(
                  children: [
                    Text(
                      "PLAYING FROM PLAYLIST",
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
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
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () => _showPlaylistMenu(context, musicProvider),
                ),
              ],
            ),

            const Spacer(),

            // ───── ROTATING CD (FIXED & DYNAMIC) ─────
            RotatingCD(
              songId: currentSong.id,
              isPlaying: musicProvider.isPlaying,
              customArtworkPath: musicProvider.getCustomArtwork(currentSong.id),
            ),

            const Spacer(),

            // ───── SONG INFO + ANIMATED LIKE BUTTON ─────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSong.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        (currentSong.artist == "<unknown>")
                            ? "Local file"
                            : currentSong.artist,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Animated heart button
                GestureDetector(
                  onTap: () => _onHeartTap(musicProvider, currentSong),
                  onLongPress: () => _showPlaylistMenu(context, musicProvider),
                  child: AnimatedBuilder(
                    animation: _heartScaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _heartScaleAnimation.value,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(scale: animation, child: child);
                          },
                          child: Icon(
                            musicProvider.isLiked(currentSong)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            key: ValueKey(musicProvider.isLiked(currentSong)),
                            color: musicProvider.isLiked(currentSong)
                                ? Colors.red
                                : Colors.amber,
                            size: 30,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ───── SEEKBAR ─────
            StreamBuilder<Duration>(
              stream: musicProvider.player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = musicProvider.player.duration ?? Duration.zero;

                final maxMillis = max(duration.inMilliseconds.toDouble(), 1.0);

                return Column(
                  children: [
                    Slider(
                      activeColor: Colors.amber,
                      inactiveColor: Colors.white12,
                      value: (_dragValue ?? position.inMilliseconds.toDouble())
                          .clamp(0.0, maxMillis),
                      max: maxMillis,
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
                          Text(_format(position)),
                          Text(_format(duration)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ───── CONTROLS ─────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: musicProvider.isShuffleModeEnabled
                        ? Colors.amber
                        : Colors.white54,
                  ),
                  onPressed: musicProvider.toggleShuffle,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 40),
                  onPressed: musicProvider.playPrevious,
                ),
                IconButton(
                  icon: Icon(
                    musicProvider.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 70,
                    color: Colors.amber,
                  ),
                  onPressed: musicProvider.togglePlay,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 40),
                  onPressed: musicProvider.playNext,
                ),
                IconButton(
                  icon: Icon(
                    musicProvider.loopMode == LoopMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                    color: musicProvider.loopMode != LoopMode.off
                        ? Colors.amber
                        : Colors.white54,
                  ),
                  onPressed: musicProvider.toggleRepeat,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}
