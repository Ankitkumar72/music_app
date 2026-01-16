
---

# 🎵 Pixy Music Player

<p align="center">
  <img src="music_player/assets/images/default_cover.png" width="120" alt="Pixy Logo"/>
</p>

**Pixy** is a modern, high-performance Flutter music player designed for local audio playback. It features a stunning dynamic UI, smart playlist management, background playback with notification controls, and a robust state management system powered by Provider.

---

## ✨ Features

### 🏠 Dynamic Home Screen
- **Your Daily Mix** – Automatically curated with your most-played songs (3+ plays)
- **Discovery Mix** – Random selection of 20 songs to explore your library
- **Jump Back In** – Recent play history (last 10 tracks) with persistence
- **Dynamic Category Chips** – Quick access to all your playlists

### 🎧 Now Playing Experience
- **Full-Screen Player** – Beautiful album art with gradient backgrounds
- **Rotating CD Animation** – Vinyl-style rotating artwork while playing
- **Seek Bar** – Precise playback control with time indicators
- **Playback Controls** – Play/Pause, Skip, Previous, Shuffle, Repeat modes
- **Like Songs** – Add to favorites with animated heart button
- **Queue Management** – View and manage upcoming songs
- **Add to Playlist** – Quick add from the now playing screen

### 📚 Library Management
- **Complete Song Library** – Browse all local audio files
- **Sort Options** – Organize by title, artist, album, or date
- **Grid/List View** – Switch between viewing modes
- **Album Art Display** – Beautiful artwork for all songs

### 🔍 Smart Search
- **Real-time Search** – Instant results as you type
- **Multi-field Search** – Search by song title or artist name
- **Search History** – Quick access to recently played from search
- **Case-insensitive** – Find songs regardless of capitalization

### 📁 Playlist System
- **Create Custom Playlists** – Organize your music your way
- **Liked Songs** – Dedicated favorites playlist
- **Add/Remove Songs** – Easy playlist management
- **Play Next / Add to Queue** – Queue songs from any playlist

### 🎨 Artwork Management
- **Auto-Download Artwork** – Automatically fetches album art from the web
- **Manual Search** – Search and apply custom artwork
- **Custom Artwork** – Set your own images for any song
- **Artwork Cache** – Efficient storage for fast loading

### 🔔 Background Playback & Notifications
- **Foreground Service** – Music continues playing when app is minimized
- **Media Notification** – Control playback from notification shade
- **Lock Screen Controls** – Play/pause/skip from lock screen
- **Bluetooth/Headphone Controls** – Media buttons support
- **Fast Response** – Optimized notification updates with bitmap caching

### ⚙️ Settings & Customization
- **Library Management** – Rescan, clear cache, refresh metadata
- **Excluded Songs** – Hide songs from library (recoverable)
- **Blacklist Folders** – Exclude entire directories
- **Reset Options** – Clear playlists, history, or all data
- **App Statistics** – View total songs, playlists, and storage

### 🛡️ Quality & Performance
- **Hive Database** – Lightning-fast local storage
- **Background Optimization** – Minimal battery usage
- **Graceful Error Handling** – Handles missing files smoothly
- **Memory Efficient** – Smart artwork caching

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|------------|
| **Framework** | Flutter / Dart |
| **State Management** | Provider |
| **Audio Playback** | `just_audio` |
| **Audio Query** | `on_audio_query` |
| **Local Database** | Hive |
| **Permissions** | `permission_handler` |
| **Network** | Dio / HTTP |
| **Connectivity** | `connectivity_plus` |
| **Native Integration** | Kotlin (Android) |

---

## 📱 Screenshots

> Coming soon...

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (v3.10.0 or later)
- Android Studio / VS Code
- Android device or emulator with audio files

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Ankitkumar72/music_app.git
   cd music_app/music_player
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

4. **Build release APK:**
   ```bash
   flutter build apk --release
   ```

---

## 🏗️ Project Structure

```text
music_player/
├── android/
│   └── app/src/main/kotlin/
│       ├── MainActivity.kt           # Flutter/Native bridge
│       ├── CustomMediaService.kt     # Background playback service
│       ├── CustomNotificationManager.kt  # Media notification
│       └── MediaControlReceiver.kt   # Broadcast receiver
├── lib/
│   ├── main.dart                     # App entry point
│   ├── logic/
│   │   ├── music_provider.dart       # Central state & audio logic
│   │   └── Models/
│   │       └── song_data.dart        # Hive TypeAdapters
│   ├── screens/
│   │   ├── navigation_shell.dart     # Bottom navigation
│   │   ├── home_screen.dart          # Dynamic dashboard
│   │   ├── library_screen.dart       # Song library
│   │   ├── search_screen.dart        # Search functionality
│   │   ├── playlist_screen.dart      # Playlist manager
│   │   ├── now_playing_screen.dart   # Full player UI
│   │   └── settings_screen.dart      # App settings
│   └── widgets/
│       ├── mini_player.dart          # Persistent player bar
│       ├── rotating_cd.dart          # Vinyl animation
│       ├── song_menu.dart            # Context menu
│       └── blob_background.dart      # Gradient effects
└── assets/
    └── images/
        └── default_cover.png         # Fallback artwork
```

📖 **[View Detailed Structure →](https://github.com/Ankitkumar72/music_app/blob/main/Structure.md)**

---

## 🔧 Key Features Implementation

### Background Playback
Pixy uses a custom foreground service (`CustomMediaService`) with `MediaSession` integration for seamless background playback and system media controls.

### Bitmap Caching
The notification system caches decoded bitmaps to ensure instant play/pause response without re-decoding artwork on every state change.

### Queue System
- **Play Next** – Insert songs immediately after current
- **Add to Queue** – Append songs to the end
- **Context-aware** – Maintains original playlist order

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Ankit Kumar**
- GitHub: [@Ankitkumar72](https://github.com/Ankitkumar72)

---

<p align="center">
  Made with ❤️ and Flutter
</p>
