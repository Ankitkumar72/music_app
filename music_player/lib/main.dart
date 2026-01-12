import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'screens/navigation_shell.dart';
import 'logic/music_provider.dart';
import 'logic/Models/song_data.dart';
import 'logic/audio_handler.dart';

AudioPlayerHandler? audioHandler;

void main() async {
  // 1. Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Hive and Register Adapters
  await Hive.initFlutter();
  Hive.registerAdapter(SongDataAdapter());
  Hive.registerAdapter(PlaylistDataAdapter());
  Hive.registerAdapter(CachedMetadataAdapter());

  // 3. Open required Hive boxes before Provider initialization
  await Hive.openBox<PlaylistData>('playlists');
  await Hive.openBox<CachedMetadata>('metadata');
  await Hive.openBox('stats');

  // 4. Initialize Audio Service for background playback
  try {
    audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.example.music_player.debug.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
    debugPrint("✅ AudioService initialized successfully: $audioHandler");
  } catch (e, stack) {
    debugPrint("❌ Error initializing AudioService: $e");
    debugPrint("Stack trace: $stack");
  }

  // 5. Run the App with MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MusicProvider()..fetchSongs(),
        ),
      ],
      child: const MusicPlayerApp(),
    ),
  );
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pixy',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A12),
        primaryColor: const Color(0xFF6332F6),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6332F6),
          secondary: Color(0xFFFFC107),
        ),
      ),
      home: const NavigationShell(),
    );
  }
}