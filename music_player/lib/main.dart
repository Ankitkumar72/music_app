import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PlayerProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const MusicPlayerScreen(),
    );
  }
}

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentFileName;

  bool get isPlaying => _isPlaying;
  String? get currentFileName => _currentFileName;

  Future<void> pickAndPlay() async {
    // 1. Pick the file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true, // This is CRITICAL for web to get the bytes
    );

    if (result != null) {
      _currentFileName = result.files.single.name;

      try {
        if (result.files.single.bytes != null) {
          // Logic for WEB: Use bytes to create a Blob URI
          final content = result.files.single.bytes!;
          final blob = Uri.dataFromBytes(content, mimeType: 'audio/mpeg');
          await _audioPlayer.setAudioSource(AudioSource.uri(blob));
        } else {
          // Logic for MOBILE/DESKTOP: Use file path
          await _audioPlayer.setFilePath(result.files.single.path!);
        }

        _audioPlayer.play();
        _isPlaying = true;
        notifyListeners();
      } catch (e) {
        debugPrint("Error loading audio: $e");
      }
    }
  }

  void togglePlayPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

class MusicPlayerScreen extends StatelessWidget {
  const MusicPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("My Music Player")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              player.currentFileName ?? "No song selected",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 64,
                  icon: Icon(
                    player.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                  onPressed: player.currentFileName == null
                      ? null
                      : () => player.togglePlayPause(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => player.pickAndPlay(),
              icon: const Icon(Icons.audiotrack),
              label: const Text("Pick Song"),
            ),
          ],
        ),
      ),
    );
  }
}
