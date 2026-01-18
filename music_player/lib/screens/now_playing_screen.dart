// ignore_for_file: deprecated_member_use

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

  // ───── OPTIONS MENU ─────
  void _showOptionsMenu(BuildContext context, MusicProvider provider) {
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
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildOptionItem(context, Icons.queue_music, "Add to Queue", () {
                Navigator.pop(context);
                final song = provider.currentSong;
                if (song != null) {
                  provider.addToQueue(song);
                  _showNotification("Added to Queue", Icons.check);
                }
              }),
              _buildOptionItem(context, Icons.list, "Go to Queue", () {
                Navigator.pop(context);
                _showQueueSheet(context, provider);
              }),
               _buildOptionItem(context, Icons.album, "Go to Album", () {
                Navigator.pop(context);
                _showAlbumSheet(context, provider);
              }),
              _buildOptionItem(context, Icons.info_outline, "Song Details", () {
                Navigator.pop(context);
                _showDetailsDialog(context, provider.currentSong!);
              }),
              _buildOptionItem(context, Icons.playlist_add, "Add to Playlist", () {
                Navigator.pop(context);
                _showAddToPlaylistSheet(context, provider);
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  // ───── SUB-MENUS ─────
  
  void _showQueueSheet(BuildContext context, MusicProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            final playNextQueue = provider.playNextQueue;
            final addedToQueue = provider.addedToQueue;
            final fullQueue = provider.fullQueue;
            
            return ListView(
              controller: controller,
              children: [
                // Header
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Queue • ${provider.playbackContextName}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                // Now Playing
                if (provider.currentSong != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "NOW PLAYING",
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildQueueTile(provider.currentSong!, isPlaying: true),
                ],
                
                // Play Next section
                if (playNextQueue.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "PLAYING NEXT",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...playNextQueue.asMap().entries.map((entry) => _buildQueueTile(
                    entry.value,
                    icon: Icons.playlist_play,
                    iconColor: Colors.greenAccent,
                    onTap: () {
                      provider.playFromQueue(entry.value);
                      Navigator.pop(context);
                    },
                  )),
                ],
                
                // Up Next (context songs)
                if (fullQueue.where((s) => 
                    !playNextQueue.any((p) => p.id == s.id) && 
                    !addedToQueue.any((a) => a.id == s.id)).isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "UP NEXT",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...fullQueue.where((s) => 
                      !playNextQueue.any((p) => p.id == s.id) && 
                      !addedToQueue.any((a) => a.id == s.id))
                    .map((song) => _buildQueueTile(
                      song,
                      onTap: () {
                        provider.playFromQueue(song);
                        Navigator.pop(context);
                      },
                    )),
                ],
                
                // Added to Queue section
                if (addedToQueue.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "ADDED TO QUEUE",
                      style: TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...addedToQueue.map((song) => _buildQueueTile(
                    song,
                    icon: Icons.queue_music,
                    iconColor: Colors.purpleAccent,
                    onTap: () {
                      provider.playFromQueue(song);
                      Navigator.pop(context);
                    },
                  )),
                ],
                
                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }
  
  Widget _buildQueueTile(SongData song, {
    bool isPlaying = false, 
    IconData? icon, 
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: icon != null 
          ? Icon(icon, color: iconColor ?? Colors.white54, size: 20)
          : null,
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: isPlaying ? Colors.amber : Colors.white),
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        style: TextStyle(color: isPlaying ? Colors.amber.withOpacity(0.7) : Colors.white54),
      ),
      trailing: isPlaying ? const Icon(Icons.equalizer, color: Colors.amber) : null,
      onTap: onTap,
    );
  }

  void _showAlbumSheet(BuildContext context, MusicProvider provider) {
    final currentAlbum = provider.currentSong?.album;
    if (currentAlbum == null) return;

    final albumSongs = provider.allSongs.where((s) => s.album == currentAlbum).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Album: $currentAlbum",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: albumSongs.length,
                itemBuilder: (context, index) {
                  final song = albumSongs[index];
                  return ListTile(
                    leading: const Icon(Icons.music_note, color: Colors.white54),
                    title: Text(song.title, style: const TextStyle(color: Colors.white)),
                    onTap: () {
                       // Find index in main list to play?
                       // Or play mostly likely not supported directly without context switch.
                       // Just showing list for now.
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDetailsDialog(BuildContext context, SongData song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Song Details", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _detailRow("Title", song.title),
             _detailRow("Artist", song.artist),
             _detailRow("Album", song.album),
             _detailRow("Duration", _format(Duration(milliseconds: song.duration ?? 0))),
             const SizedBox(height: 8),
             Text("Path: ${song.data}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.amber)),
          )
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // ───── ADD TO PLAYLIST (Refactored) ─────
  void _showAddToPlaylistSheet(BuildContext context, MusicProvider provider) {
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
                Column(
                  children: [
                    const Text(
                      "PLAYING FROM",
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: Colors.amber,
                      ),
                    ),
                    Text(
                      musicProvider.playbackContextName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () => _showOptionsMenu(context, musicProvider),
                ),
              ],
            ),

            const Spacer(),

            // ───── ROTATING CD (FIXED & DYNAMIC) ─────
            RotatingCD(
              songId: currentSong.id,
              isPlaying: musicProvider.isPlaying,
              customArtworkPath: musicProvider.getCustomArtwork(currentSong.id),
              defaultArtworkPath: musicProvider.defaultArtworkPath,
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
                  onLongPress: () => _showOptionsMenu(context, musicProvider),
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
                  onPressed: musicProvider.skipToNext,
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
            
            const SizedBox(height: 20),
            
            // ───── BOTTOM ACTION BAR ─────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Device/Cast button
                IconButton(
                  icon: const Icon(Icons.devices, color: Colors.white54),
                  onPressed: () {
                    _showNotification('Device selection not available', Icons.devices);
                  },
                ),
                // Share button
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white54),
                  onPressed: () {
                    _showNotification('Share feature coming soon', Icons.share);
                  },
                ),
                // Queue button
                IconButton(
                  icon: const Icon(Icons.queue_music, color: Colors.white54, size: 28),
                  onPressed: () => _showQueueSheet(context, musicProvider),
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
