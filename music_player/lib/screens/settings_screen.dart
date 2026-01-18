// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../logic/music_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Audio & Playback Settings
  bool _audioFocusEnabled = true;
  int _sleepTimerMinutes = 0; // 0 means disabled
  bool _crossfadeEnabled = false;
  double _crossfadeDuration = 5.0; // seconds

  // Blacklist folders list
  final List<String> _blacklistedFolders = [];

  // App version
  static const String _appVersion = "v1.0.0";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final box = Hive.box('stats');
    setState(() {
      _audioFocusEnabled = box.get('audioFocus', defaultValue: true);
      _sleepTimerMinutes = box.get('sleepTimer', defaultValue: 0);
      _crossfadeEnabled = box.get('crossfade', defaultValue: false);
      _crossfadeDuration = box.get('crossfadeDuration', defaultValue: 5.0);
      final savedBlacklist = box.get('blacklistedFolders', defaultValue: <String>[]);
      _blacklistedFolders.clear();
      _blacklistedFolders.addAll(List<String>.from(savedBlacklist));
    });
  }

  Future<void> _saveSettings() async {
    final box = Hive.box('stats');
    await box.put('audioFocus', _audioFocusEnabled);
    await box.put('sleepTimer', _sleepTimerMinutes);
    await box.put('crossfade', _crossfadeEnabled);
    await box.put('crossfadeDuration', _crossfadeDuration);
    await box.put('blacklistedFolders', _blacklistedFolders);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            toolbarHeight: 80,
            title: Column(
              children: [
                Text(
                  "Settings",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Customize your Pixy experience",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          // Settings Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══════════════════════════════════════════════════════════
                  // AUDIO & PLAYBACK SECTION
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionHeader("🎵 Audio & Playback"),
                  const SizedBox(height: 12),

                  // Audio Focus Toggle
                  _buildSettingCard(
                    icon: Icons.phone_paused_rounded,
                    iconColor: const Color(0xFF6332F6),
                    title: "Audio Focus",
                    subtitle: "Pause music for incoming calls & notifications",
                    trailing: Switch(
                      value: _audioFocusEnabled,
                      activeColor: const Color(0xFFFFD700),
                      onChanged: (value) {
                        setState(() => _audioFocusEnabled = value);
                        _saveSettings();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sleep Timer
                  _buildSettingCard(
                    icon: Icons.bedtime_rounded,
                    iconColor: const Color(0xFF5D4037),
                    title: "Sleep Timer",
                    subtitle: _sleepTimerMinutes == 0
                        ? "Disabled"
                        : "Stop playback after $_sleepTimerMinutes min",
                    trailing: DropdownButton<int>(
                      value: _sleepTimerMinutes,
                      dropdownColor: const Color(0xFF1A1A2E),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text("Off")),
                        DropdownMenuItem(value: 15, child: Text("15 min")),
                        DropdownMenuItem(value: 30, child: Text("30 min")),
                        DropdownMenuItem(value: 45, child: Text("45 min")),
                        DropdownMenuItem(value: 60, child: Text("60 min")),
                        DropdownMenuItem(value: 90, child: Text("90 min")),
                      ],
                      onChanged: (value) {
                        setState(() => _sleepTimerMinutes = value ?? 0);
                        _saveSettings();
                        if (value != null && value > 0) {
                          _showSnackBar("Sleep timer set for $value minutes");
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Crossfade Toggle & Slider
                  _buildSettingCard(
                    icon: Icons.compare_arrows_rounded,
                    iconColor: const Color(0xFF00BCD4),
                    title: "Crossfade",
                    subtitle: _crossfadeEnabled
                        ? "Smooth ${_crossfadeDuration.toInt()}s transitions"
                        : "Songs play back-to-back",
                    trailing: Switch(
                      value: _crossfadeEnabled,
                      activeColor: const Color(0xFFFFD700),
                      onChanged: (value) {
                        setState(() => _crossfadeEnabled = value);
                        _saveSettings();
                      },
                    ),
                  ),

                  // Crossfade Duration Slider (shown when enabled)
                  if (_crossfadeEnabled) ...[
                    const SizedBox(height: 8),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Text("2s", style: TextStyle(color: Colors.white54)),
                          Expanded(
                            child: Slider(
                              value: _crossfadeDuration,
                              min: 2,
                              max: 12,
                              divisions: 10,
                              activeColor: const Color(0xFFFFD700),
                              inactiveColor: Colors.white12,
                              label: "${_crossfadeDuration.toInt()}s",
                              onChanged: (value) {
                                setState(() => _crossfadeDuration = value);
                              },
                              onChangeEnd: (value) => _saveSettings(),
                            ),
                          ),
                          const Text("12s", style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ═══════════════════════════════════════════════════════════
                  // LIBRARY & STORAGE SECTION
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionHeader("📚 Library & Storage"),
                  const SizedBox(height: 12),

                  // Rescan Library
                  _buildActionCard(
                    icon: Icons.refresh_rounded,
                    iconColor: const Color(0xFF4CAF50),
                    title: "Rescan Library",
                    subtitle: "Scan device for new music files",
                    onTap: () => _rescanLibrary(context),
                  ),
                  const SizedBox(height: 12),

                  // Clear Artwork Cache
                  _buildActionCard(
                    icon: Icons.image_not_supported_rounded,
                    iconColor: const Color(0xFFFF9800),
                    title: "Clear Artwork Cache",
                    subtitle: "Delete cached album art to free up space",
                    onTap: () => _clearArtworkCache(context),
                  ),
                  const SizedBox(height: 12),

                  // Blacklist Folders
                  _buildActionCard(
                    icon: Icons.folder_off_rounded,
                    iconColor: const Color(0xFFE91E63),
                    title: "Blacklist Folders",
                    subtitle: _blacklistedFolders.isEmpty
                        ? "No folders blacklisted"
                        : "${_blacklistedFolders.length} folder(s) hidden",
                    onTap: () => _showBlacklistDialog(context),
                  ),
                  const SizedBox(height: 12),

                  // Excluded Songs
                  Builder(
                    builder: (context) {
                      final excludedCount = context.watch<MusicProvider>().excludedSongIds.length;
                      return _buildActionCard(
                        icon: Icons.music_off_rounded,
                        iconColor: const Color(0xFFFF5722),
                        title: "Excluded Songs",
                        subtitle: excludedCount == 0
                            ? "No songs excluded"
                            : "$excludedCount song(s) hidden from library",
                        onTap: () => _showExcludedSongsDialog(context),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Metadata Refresh
                  _buildActionCard(
                    icon: Icons.sync_rounded,
                    iconColor: const Color(0xFF9C27B0),
                    title: "Metadata Refresh",
                    subtitle: "Re-download metadata to fix missing info",
                    onTap: () => _refreshMetadata(context),
                  ),

                  const SizedBox(height: 32),

                  // ═══════════════════════════════════════════════════════════
                  // ABOUT & SUPPORT SECTION
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionHeader("ℹ️ About & Support"),
                  const SizedBox(height: 12),

                  // Privacy Policy
                  _buildActionCard(
                    icon: Icons.privacy_tip_rounded,
                    iconColor: const Color(0xFF4CAF50),
                    title: "Privacy Policy",
                    subtitle: "Read about how we handle your data",
                    onTap: () => _showPrivacyPolicy(context),
                  ),
                  const SizedBox(height: 12),



                  // App Version Display
                  _buildInfoCard(
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFF607D8B),
                    title: "App Version",
                    value: _appVersion,
                  ),
                  const SizedBox(height: 12),

                  // Pixy Credits
                  _buildInfoCard(
                    icon: Icons.auto_awesome,
                    iconColor: const Color(0xFFFFD700),
                    title: "Made with ❤️",
                    value: "Pixy Music Player",
                  ),

                  const SizedBox(height: 32),

                  // ═══════════════════════════════════════════════════════════
                  // DANGER ZONE SECTION
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionHeader("⚠️ Danger Zone", isWarning: true),
                  const SizedBox(height: 12),

                  // Reset App Button
                  _buildDangerCard(
                    icon: Icons.delete_forever_rounded,
                    title: "Reset App",
                    subtitle: "Clear all playlists, history & custom settings",
                    onTap: () => _showResetConfirmation(context),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI HELPER BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isWarning ? const Color(0xFFFF5252) : Colors.white,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5252).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFFF5252), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF5252),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFF5252),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTION HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  Future<void> _rescanLibrary(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
      ),
    );

    try {
      final provider = context.read<MusicProvider>();
      await provider.fetchSongs();
      if (context.mounted) {
        Navigator.pop(context);
        _showSnackBar("Library rescanned successfully!");
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showSnackBar("Error rescanning library: $e");
      }
    }
  }

  Future<void> _clearArtworkCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Clear Artwork Cache?"),
        content: const Text(
          "This will delete all locally saved artwork images. "
          "Album art will be re-downloaded when needed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Clear",
              style: TextStyle(color: Color(0xFFFF9800)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final artworkDir = Directory('${appDir.path}/artwork');
        
        if (await artworkDir.exists()) {
          int deletedCount = 0;
          await for (final entity in artworkDir.list()) {
            if (entity is File && entity.path.endsWith('.jpg')) {
              await entity.delete();
              deletedCount++;
            }
          }
          _showSnackBar("Cleared $deletedCount cached artwork files");
        } else {
          _showSnackBar("No artwork cache found");
        }
      } catch (e) {
        _showSnackBar("Error clearing cache: $e");
      }
    }
  }

  Future<void> _showBlacklistDialog(BuildContext context) async {
    // Common folders that users might want to blacklist
    final commonFolders = [
      "/storage/emulated/0/Ringtones",
      "/storage/emulated/0/Notifications",
      "/storage/emulated/0/Alarms",
      "/storage/emulated/0/WhatsApp/Media/WhatsApp Audio",
      "/storage/emulated/0/WhatsApp/Media/WhatsApp Voice Notes",
      "/storage/emulated/0/Telegram/Telegram Audio",
      "/storage/emulated/0/Download/TikTok",
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.folder_off, color: Color(0xFFE91E63)),
              SizedBox(width: 8),
              Text("Blacklist Folders"),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select folders to hide from your library:",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: commonFolders.length,
                    itemBuilder: (context, index) {
                      final folder = commonFolders[index];
                      final folderName = folder.split('/').last;
                      final isBlacklisted = _blacklistedFolders.contains(folder);

                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          folderName,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          folder,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.4),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: isBlacklisted,
                        activeColor: const Color(0xFFFFD700),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              _blacklistedFolders.add(folder);
                            } else {
                              _blacklistedFolders.remove(folder);
                            }
                          });
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _saveSettings();
                Navigator.pop(context);
                _showSnackBar(
                  "${_blacklistedFolders.length} folder(s) blacklisted. Rescan library to apply.",
                );
              },
              child: const Text(
                "Save",
                style: TextStyle(color: Color(0xFFFFD700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshMetadata(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Refresh Metadata?"),
        content: const Text(
          "This will re-download metadata for all songs in your library. "
          "This may take a while and will use your internet connection.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Refresh",
              style: TextStyle(color: Color(0xFF9C27B0)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFFFD700)),
              SizedBox(height: 16),
              Text(
                "Refreshing metadata...",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      try {
        // Clear metadata cache via provider to ensure memory state is also updated
        await context.read<MusicProvider>().clearMetadataCache();

        if (context.mounted) {
          Navigator.pop(context);
          _showSnackBar("Metadata cache cleared. Re-downloading artwork...");
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          _showSnackBar("Error refreshing metadata: $e");
        }
      }
    }
  }

  Future<void> _showResetConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252)),
            SizedBox(width: 8),
            Text("Reset App?", style: TextStyle(color: Color(0xFFFF5252))),
          ],
        ),
        content: const Text(
          "This action cannot be undone!\n\n"
          "The following data will be permanently deleted:\n"
          "• All playlists\n"
          "• Listening history\n"
          "• Liked songs\n"
          "• Custom artwork\n"
          "• All settings",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Reset Everything",
              style: TextStyle(color: Color(0xFFFF5252)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Clear all Hive boxes
        await Hive.box('stats').clear();
        
        final playlistsBox = Hive.box('playlists');
        if (playlistsBox.isOpen) await playlistsBox.clear();
        
        final metadataBox = Hive.box('metadata');
        if (metadataBox.isOpen) await metadataBox.clear();

        // Clear artwork directory
        final appDir = await getApplicationDocumentsDirectory();
        final artworkDir = Directory('${appDir.path}/artwork');
        if (await artworkDir.exists()) {
          await artworkDir.delete(recursive: true);
        }

        // Reset local state
        setState(() {
          _audioFocusEnabled = true;
          _sleepTimerMinutes = 0;
          _crossfadeEnabled = false;
          _crossfadeDuration = 5.0;
          _blacklistedFolders.clear();
        });

        if (context.mounted) {
          _showSnackBar("App has been reset to default settings");
        }
      } catch (e) {
        _showSnackBar("Error resetting app: $e");
      }
    }
  }

  Future<void> _showExcludedSongsDialog(BuildContext context) async {
    final provider = context.read<MusicProvider>();
    final excludedIds = List<int>.from(provider.excludedSongIds);

    if (excludedIds.isEmpty) {
      _showSnackBar("No songs have been excluded");
      return;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.music_off_rounded, color: Color(0xFFFF5722)),
              const SizedBox(width: 8),
              const Text("Excluded Songs"),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${excludedIds.length}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFF5722),
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tap a song to restore it to your library:",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: excludedIds.isEmpty
                      ? const Center(
                          child: Text(
                            "All songs have been restored!",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: excludedIds.length,
                          itemBuilder: (context, index) {
                            final songId = excludedIds[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                "Song ID: $songId",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: const Text(
                                "Tap to restore",
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.restore,
                                  color: Color(0xFF4CAF50),
                                ),
                                onPressed: () async {
                                  await provider.restoreSong(songId);
                                  setDialogState(() {
                                    excludedIds.remove(songId);
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      SnackBar(
                                        content: const Text("Song restored to library"),
                                        backgroundColor: const Color(0xFF4CAF50),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            if (excludedIds.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await provider.restoreAllSongs();
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  _showSnackBar("All songs restored to library");
                },
                child: const Text(
                  "Restore All",
                  style: TextStyle(color: Color(0xFF4CAF50)),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Close"),
            ),
          ],
        ),
      ),
    );
  }
  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip, color: Color(0xFF4CAF50)),
            SizedBox(width: 8),
            Text("Privacy Policy"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Your Privacy Matters",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Pixy Music Player is designed to respect your privacy and data security.",
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
              const SizedBox(height: 16),
              _buildPrivacyPoint(
                "💾 Local Storage Only",
                "Your music library, playlists, and listening history are stored locally on your device. We do not upload your personal files to any server.",
              ),
              const SizedBox(height: 8),
              _buildPrivacyPoint(
                "🌐 Internet Usage",
                "The app uses internet connection solely for:\n• Downloading album artwork (via iTunes/Deezer APIs)\n• Fetching lyrics (future feature)\n\nAll network communication is secured via HTTPS.",
              ),
              const SizedBox(height: 8),
              _buildPrivacyPoint(
                "🕵️ No Tracking",
                "We do not collect usage analytics, personal identifiers, or sell your data to third parties.",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(color: Color(0xFFFFD700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPoint(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
        ),
      ],
    );
  }
}
