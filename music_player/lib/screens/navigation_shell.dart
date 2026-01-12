import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'search_screen.dart';
import 'playlist_screen.dart';
import 'settings_screen.dart';
import '../widgets/mini_player.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _selectedIndex = 0;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      // Add delay to ensure Activity is ready
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (Platform.isAndroid) {
        // Request audio/storage permission
        if (await Permission.audio.isGranted || await Permission.storage.isGranted) {
           // already granted
        } else {
           PermissionStatus status = await Permission.audio.request();
           if (!status.isGranted) {
             await Permission.storage.request();
           }
        }
        
        // Request notification permission for Android 13+
        if (await Permission.notification.isDenied) {
          await Permission.notification.request();
        }
      }
      
      setState(() => _hasPermission = true); // Allow access even if partial denied, to avoid blocking UI loop
    } catch (e) {
      debugPrint('Permission check error: $e');
      // Continue anyway
      setState(() => _hasPermission = true);
    }
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const LibraryScreen(),
    const SearchScreen(),
    const PlaylistScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return const Scaffold(
        body: Center(
          child: Text("Please grant storage permissions to continue."),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        if (_selectedIndex == 0) {
          // On Home tab - exit the app
          SystemNavigator.pop();
        } else {
          // Not on Home tab - go to Home first
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(index: _selectedIndex, children: _screens),

            // Mini Player
            const Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: MiniPlayer(),
            ),
          ],
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(canvasColor: const Color(0xFF0A0A12)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF6332F6),
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: "Library",
              ),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
              BottomNavigationBarItem(
                icon: Icon(Icons.playlist_play),
                label: "Playlists",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: "Settings",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
