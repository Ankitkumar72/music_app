import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/navigation_shell.dart';
import 'logic/music_provider.dart';
import 'logic/Models/song_data.dart';
import 'logic/audio_handler.dart';


AudioPlayerHandler? audioHandler;


Future<void> requestNotificationPermission() async {
  
  if (await Permission.notification.isDenied) {
    debugPrint("📢 Requesting notification permission...");
    
    
    final status = await Permission.notification.request();
    
    if (status.isGranted) {
      debugPrint("✅ Notification permission granted");
    } else if (status.isDenied) {
      debugPrint("❌ Notification permission denied");
    } else if (status.isPermanentlyDenied) {
      debugPrint("⚠️ Notification permission permanently denied");
      
    }
  } else if (await Permission.notification.isGranted) {
    debugPrint("✅ Notification permission already granted");
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


  await requestNotificationPermission();


  try {
    audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.music_player.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: false, 
        androidStopForegroundOnPause: false, 
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidShowNotificationBadge: true,
        notificationColor: Color(0xFF6332F6), 
      ),
    );
    debugPrint("✅ AudioService initialized successfully");
  } catch (e, stack) {
    debugPrint("❌ Error initializing AudioService: $e");
    debugPrint("Stack trace: $stack");
  }


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