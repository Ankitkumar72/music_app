---

# Pixy Player 🎵

**Pixy** is a modern, high-performance Flutter music player designed for local audio playback. It features a dynamic UI that syncs with your listening habits, smart playlist management, and a robust state management system powered by Provider.

---

## ✨ Features

### 🏠 Dynamic Home Screen

* **Your Daily Mix**: Automatically populates with your "hits"—songs you've played 3 or more times.
* **Discovery Mix**: A randomly generated selection of 10 songs from your library to keep your listening experience fresh.
* **Jump Back In**: A persistence-based "Recently Played" section that tracks and displays your last 10 tracks.
* **Synced Categories**: Top chips are dynamically generated from your Hive-stored playlists.

### 📂 Smart Playlist Management

* **Hive Persistence**: All playlists, play counts, and history are saved locally using Hive for near-instant load times.
* **Intelligent Search**: A deep-search algorithm that filters playlists by name, song title, or artist name with case-insensitivity.
* **Category Tabs**: Easily filter between "All Playlists," "Favorites," and custom "My Mixes".

### 🎧 Audio & Performance

* **OnAudioQuery**: Efficiently fetches and manages local `.mp3` and `.m4a` files from device storage.
* **JustAudio**: High-fidelity audio playback with support for shuffling, looping, and gapless transitions.
* **Mini-Player**: A persistent UI element across the app for quick playback control.

---

## 🛠️ Tech Stack

| Component | Technology |
| --- | --- |
| **Language** | Dart / Flutter |
| **State Management** | Provider |
| **Audio Library** | `on_audio_query` & `just_audio` |
| **Local Database** | Hive |
| **Permissions** | `permission_handler` |

---

## 🚀 Getting Started

### Prerequisites

* Flutter SDK (Latest Version)
* Android Studio / VS Code
* An Android device or emulator with audio files

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/Ankitkumar72/music_app.git

```


2. **Install dependencies:**
```bash
flutter pub get

```


3. **Run the app:**
```bash
flutter run

```



---

## 🏗️ Project Structure

```text
lib/
├── logic/
│   ├── music_provider.dart    # Central state & audio logic
│   └── models/
│       └── song_data.dart     # Hive TypeAdapters for Playlists
├── screens/
│   ├── home_screen.dart       # Dynamic dashboard
│   ├── playlist_screen.dart   # Searchable playlist manager
│   └── mix_detail_screen.dart # Filtered list view for mixes
└── widgets/
    ├── mini_player.dart       # Global playback controller
    └── playlist_card.dart     # Custom UI for playlist tiles

```

---

## 🤝 Contributing

Feel free to fork this project and submit pull requests. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is licensed under the MIT License.

---
