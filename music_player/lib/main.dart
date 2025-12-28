import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/navigation_shell.dart';
import 'logic/music_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MusicProvider()..fetchSongs()),
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
