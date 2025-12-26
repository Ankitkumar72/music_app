import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MusicPlayerApp());

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFBB86FC),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _player = AudioPlayer();

  // Track state for the UI
  SongModel? _currentSong;
  bool _isPlaying = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    try {
      // Request storage permission
      PermissionStatus status;

      // For Android 13+ (API 33+)
      if (await Permission.audio.isGranted) {
        status = PermissionStatus.granted;
      } else {
        status = await Permission.audio.request();
      }

      // For Android 12 and below
      if (status.isDenied || status.isPermanentlyDenied) {
        status = await Permission.storage.request();
      }

      setState(() {
        _hasPermission = status.isGranted;
      });

      if (!_hasPermission) {
        _showPermissionDialog();
      }
    } catch (e) {
      debugPrint("Permission error: $e");
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
          "This app needs access to your music files to play them. "
          "Please grant the permission in settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  void _playSong(SongModel song) async {
    try {
      await _player.setFilePath(song.data);
      _player.play();
      setState(() {
        _currentSong = song;
        _isPlaying = true;
      });

      // Listen to player state
      _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });
    } catch (e) {
      debugPrint("Error playing song: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error playing song: $e")));
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "PixelPlay Music",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: !_hasPermission
          ? _buildPermissionScreen()
          : Stack(
              children: [
                Column(
                  children: [
                    _buildHeroSection(),
                    Expanded(
                      child: FutureBuilder<List<SongModel>>(
                        future: _audioQuery.querySongs(
                          sortType: null,
                          orderType: OrderType.ASC_OR_SMALLER,
                          uriType: UriType.EXTERNAL,
                          ignoreCase: true,
                        ),
                        builder: (context, item) {
                          if (item.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (item.hasError) {
                            return Center(child: Text("Error: ${item.error}"));
                          }

                          if (item.data == null || item.data!.isEmpty) {
                            return const Center(
                              child: Text(
                                "No Music Found\n\nMake sure you have music files on your device",
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: item.data!.length,
                            itemBuilder: (context, index) {
                              SongModel song = item.data![index];
                              return _buildSongTile(song);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (_currentSong != null) _buildMiniPlayer(),
              ],
            ),
    );
  }

  Widget _buildPermissionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_off, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "Storage Permission Required",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "We need access to your music files to play them.",
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _requestPermissions,
              child: const Text("Grant Permission"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "Currently Listening To",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            _currentSong?.title ?? "Select a Song",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Container(
            height: 80,
            width: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFBB86FC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 50,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(SongModel song) {
    return ListTile(
      leading: QueryArtworkWidget(
        id: song.id,
        type: ArtworkType.AUDIO,
        artworkBorder: BorderRadius.circular(8),
        nullArtworkWidget: const Icon(Icons.music_note, color: Colors.grey),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        song.artist ?? "Unknown Artist",
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: _currentSong?.id == song.id
          ? const Icon(Icons.bar_chart, color: Color(0xFFBB86FC))
          : null,
      onTap: () => _playSong(song),
    );
  }

  Widget _buildMiniPlayer() {
    return Positioned(
      bottom: 10,
      left: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: QueryArtworkWidget(
                id: _currentSong!.id,
                type: ArtworkType.AUDIO,
                size: 50,
                artworkBorder: BorderRadius.circular(8),
                nullArtworkWidget: const Icon(Icons.music_note, size: 30),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentSong!.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _currentSong!.artist ?? "Unknown",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                if (_isPlaying) {
                  _player.pause();
                } else {
                  _player.play();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
