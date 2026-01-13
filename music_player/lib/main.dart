import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/navigation_shell.dart';
import 'logic/music_provider.dart';
import 'logic/Models/song_data.dart';
import 'logic/audio_handler.dart';

// Global reference to  the audio handler (set after AudioService.init)
AudioPlayerHandler? audioHandler;

/// Request notification permission for Android 13+ (and some Android 12 devices)
Future<void> requestNotificationPermission() async {
  // Check if notification permission is denied
  if (await Permission.notification.isDenied) {
    debugPrint("📢 Requesting notification permission...");
    
    // Request the permission - this will show the system dialog
    final status = await Permission.notification.request();
    
    if (status.isGranted) {
      debugPrint("✅ Notification permission granted");
    } else if (status.isDenied) {
      debugPrint("❌ Notification permission denied");
    } else if (status.isPermanentlyDenied) {
      debugPrint("⚠️ Notification permission permanently denied");
      // You could show a dialog here directing user to app settings
    }
  } else if (await Permission.notification.isGranted) {
    debugPrint("✅ Notification permission already granted");
  }
}

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

  // 4. Request notification permission BEFORE initializing AudioService
  await requestNotificationPermission();

  // 5. Initialize Audio Service for background playback
  try {
    audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.music_player.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: false, // Allow dismissing notification
        androidStopForegroundOnPause: false, // Keep notification when paused
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidShowNotificationBadge: true,
        notificationColor: Color(0xFF6332F6), // App's primary purple color
      ),
    );
    debugPrint("✅ AudioService initialized successfully");
  } catch (e, stack) {
    debugPrint("❌ Error initializing AudioService: $e");
    debugPrint("Stack trace: $stack");
  }

  // 6. Run the App with MultiProvider
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