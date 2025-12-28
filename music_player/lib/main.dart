import 'package:flutter/material.dart';
import 'screens/navigation_shell.dart';

void main() => runApp(const MusicPlayerApp());

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pixy Music',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(
          0xFF0A0A12,
        ), // Deep navy from your UI
        primaryColor: const Color(0xFF6332F6), // Purple accent
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6332F6),
          secondary: Color(0xFFFFC107), // Yellow accent for play buttons
        ),
      ),
      home: const NavigationShell(),
    );
  }
}