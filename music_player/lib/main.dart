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
        splashFactory: NoSplash.splashFactory,
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

  List<SongModel> _songs = [];
  SongModel? _currentSong;
  int _currentIndex = -1;

  Widget? _cachedArtwork;
  Widget? _cachedSongList;

  bool _hasPermission = false;

  // 🔥 ValueNotifiers (high-FPS safe)
  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _duration = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _buffered = ValueNotifier(Duration.zero);

  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _listenPlayer();
  }

  void _listenPlayer() {
    _player.durationStream.listen((d) {
      if (d != null) _duration.value = d;
    });

    _player.positionStream.listen((p) {
      if (!_isDragging) _position.value = p;
    });

    _player.bufferedPositionStream.listen((b) {
      _buffered.value = b;
    });
  }

  Future<void> _requestPermissions() async {
    PermissionStatus status = await Permission.audio.request();
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    setState(() => _hasPermission = status.isGranted);
  }

  Future<void> _playSong(int index) async {
    _currentIndex = index;
    _currentSong = _songs[index];

    _cachedArtwork = QueryArtworkWidget(
      key: ValueKey(_currentSong!.id),
      id: _currentSong!.id,
      type: ArtworkType.AUDIO,
      artworkHeight: 220,
      artworkWidth: 220,
      artworkFit: BoxFit.cover,
      nullArtworkWidget: const Icon(Icons.music_note, size: 100),
    );

    await _player.setFilePath(_currentSong!.data);
    _player.play();

    setState(() {});
  }

  String _format(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
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
        title: const Text("Pixy"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: !_hasPermission
          ? const Center(child: Text("Permission required"))
          : Column(
              children: [
                RepaintBoundary(child: _buildNowPlaying()),
                Expanded(child: _buildSongList()),
              ],
            ),
    );
  }

  // ================= NOW PLAYING =================

  Widget _buildNowPlaying() {
    if (_currentSong == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("Select a song to play"),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          RepaintBoundary(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _cachedArtwork,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentSong!.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            _currentSong!.artist ?? "Unknown",
            style: const TextStyle(color: Colors.grey),
          ),

          // ===== SEEK + BUFFERED (VALUE NOTIFIER BASED) =====
          ValueListenableBuilder<Duration>(
            valueListenable: _duration,
            builder: (context, dur, child) {
              final double maxMs = dur.inMilliseconds > 0
                  ? dur.inMilliseconds.toDouble()
                  : 1.0;

              return ValueListenableBuilder<Duration>(
                valueListenable: _position,
                builder: (context, pos, child) {
                  final double sliderValue = _isDragging
                      ? _dragValue
                      : pos.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

                  return ValueListenableBuilder<Duration>(
                    valueListenable: _buffered,
                    builder: (context, buf, child) {
                      final double bufferedValue = buf.inMilliseconds
                          .clamp(0, maxMs.toInt())
                          .toDouble();

                      return Column(
                        children: [
                          Stack(
                            children: [
                              Slider(
                                value: bufferedValue,
                                max: maxMs,
                                onChanged: null,
                              ),
                              Slider(
                                value: sliderValue,
                                max: maxMs,
                                onChangeStart: (v) {
                                  _isDragging = true;
                                  _dragValue = v;
                                },
                                onChanged: (v) {
                                  _dragValue = v;
                                },
                                onChangeEnd: (v) async {
                                  _isDragging = false;
                                  await _player.seek(
                                    Duration(milliseconds: v.toInt()),
                                  );
                                },
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [Text(_format(pos)), Text(_format(dur))],
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 42,
                icon: const Icon(Icons.skip_previous),
                onPressed: _currentIndex > 0
                    ? () => _playSong(_currentIndex - 1)
                    : null,
              ),
              IconButton(
                iconSize: 64,
                icon: Icon(
                  _player.playing ? Icons.pause_circle : Icons.play_circle,
                ),
                onPressed: () =>
                    _player.playing ? _player.pause() : _player.play(),
              ),
              IconButton(
                iconSize: 42,
                icon: const Icon(Icons.skip_next),
                onPressed: _currentIndex < _songs.length - 1
                    ? () => _playSong(_currentIndex + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= SONG LIST =================

  Widget _buildSongList() {
    if (_cachedSongList != null) return _cachedSongList!;

    return FutureBuilder<List<SongModel>>(
      future: _audioQuery.querySongs(
        ignoreCase: true,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        _songs = snapshot.data!;

        _cachedSongList = ListView.builder(
          padding: const EdgeInsets.only(bottom: 90),
          itemCount: _songs.length,
          itemBuilder: (context, index) {
            return _SongTile(
              song: _songs[index],
              isPlaying: index == _currentIndex,
              onTap: () => _playSong(index),
            );
          },
        );

        return _cachedSongList!;
      },
    );
  }
}

// ================= SONG TILE =================

class _SongTile extends StatelessWidget {
  final SongModel song;
  final bool isPlaying;
  final VoidCallback onTap;

  const _SongTile({
    required this.song,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      child: ListTile(
        leading: QueryArtworkWidget(
          id: song.id,
          type: ArtworkType.AUDIO,
          nullArtworkWidget: const Icon(Icons.music_note),
        ),
        title: Text(song.title, maxLines: 1),
        subtitle: Text(song.artist ?? "Unknown"),
        trailing: isPlaying
            ? const Icon(Icons.equalizer, color: Color(0xFFBB86FC))
            : null,
        onTap: onTap,
      ),
    );
  }
}
