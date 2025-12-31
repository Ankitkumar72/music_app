import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';

import '../logic/music_provider.dart';
import '../widgets/rotating_cd.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  double? _dragValue;

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
              const SizedBox(height: 10),
              const Text(
                "Add to Playlist",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Liked playlist
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: const Text("Liked Songs"),
                onTap: () {
                  provider.toggleLike(currentSong);
                  Navigator.pop(context);
                },
              ),

              const Divider(color: Colors.white10),

              // User playlists
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: provider.playlistNames.map((name) {
                    return ListTile(
                      leading: const Icon(Icons.playlist_add),
                      title: Text(name),
                      onTap: () {
                        provider.addToPlaylist(name, currentSong);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
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
            ),

            const Spacer(),

            // ───── SONG INFO + LIKE ─────
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
                        (currentSong.artist == null ||
                                currentSong.artist == "<unknown>")
                            ? "Local file"
                            : currentSong.artist!,
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
                  onLongPress: () => _showPlaylistMenu(context, musicProvider),
                  child: Icon(
                    musicProvider.isLiked(currentSong)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: musicProvider.isLiked(currentSong)
                        ? Colors.red
                        : Colors.amber,
                    size: 30,
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
