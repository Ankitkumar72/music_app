import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/navigation_shell.dart';
import 'logic/music_provider.dart';
import 'logic/Models/song_data.dart';
// import 'logic/audio_handler.dart';

// AudioPlayerHandler? audioHandler;


Future<void> requestPermissions() async {
  // Request Notification Permission
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // Request Storage/Audio Permission based on Android version
  if (await Permission.audio.status.isDenied) {
    // Android 13+
    await Permission.audio.request();
  }
  
  if (await Permission.storage.status.isDenied) {
    // Android < 13
    await Permission.storage.request();
    // Also manage external storage if needed for Android 11+ (Scoped Storage)
    if (await Permission.manageExternalStorage.status.isDenied) {
      // customized checking often needed here, but standard storage request usually sufficient for media in public dirs
    }
  }
}

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();

  
  await Hive.initFlutter();
  Hive.registerAdapter(SongDataAdapter());
  Hive.registerAdapter(PlaylistDataAdapter());
  Hive.registerAdapter(CachedMetadataAdapter());

  
  await Hive.openBox<PlaylistData>('playlists');
  await Hive.openBox<CachedMetadata>('metadata');
  await Hive.openBox('stats');


  await requestPermissions();


  // AudioService initialization removed
  debugPrint("✅ AudioService removed, using CustomNativeService");


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