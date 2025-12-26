Pixy Music Player 🎵
Pixy is a high-performance, lightweight local music player built with Flutter. It focuses on a smooth user experience by utilizing optimized state management for real-time seek bar updates and efficient asset rendering.

✨ Features
Local Library Scanning: Automatically queries and lists all audio files from your device.

High-Performance Seek Bar: Uses ValueNotifier to handle progress and buffering updates without rebuilding the entire UI, ensuring 60+ FPS.

Album Art Support: Dynamically fetches and displays high-quality artwork using the on_audio_query engine.

Dual-Layer Slider: A sophisticated progress bar that shows both the current playback position and the buffered data.

Modern Dark UI: A sleek, minimal aesthetic designed for focus and ease of use.

Smart Permissions: Seamlessly handles storage and audio permissions for Android and iOS.

🛠️ Tech Stack
Framework: Flutter

Audio Engine: just_audio

Storage Query: on_audio_query

Permissions: permission_handler

🚀 Getting Started
Prerequisites
Flutter SDK: >=3.0.0

Android API Level: 21 or higher

iOS: 12.0 or higher

Installation
Clone the repository:

Bash

git clone https://github.com/your-username/pixy-music-player.git
cd pixy-music-player
Install dependencies:

Bash

flutter pub get
Platform Setup:

Android: Add the following to your AndroidManifest.xml:

XML

<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
iOS: Add the following to your Info.plist:

XML

<key>NSAppleMusicUsageDescription</key>
<string>Pixy needs access to your music library to play local songs.</string>
Run the app:

Bash

flutter run
🏗️ Project Architecture
The app is designed with performance in mind:

State Management: Utilizes ValueNotifier for granular UI updates (Position, Duration, Buffered state).

Caching: Implements Widget caching for the song list and artwork to prevent flickering during list scrolling.

Rendering: Uses RepaintBoundary to isolate the "Now Playing" section from the "Song List" section, reducing the paint cost during playback animations.
