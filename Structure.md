# Music Player App - Project Structure

## Overview
A modern Flutter music player app with local file support, custom metadata parsing, online artwork fetching, and dynamic UI components.

## Directory Structure

```
lib/
├── main.dart                      # App entry point, Hive initialization
├── core/                          # Core theme and styling
│   ├── colors.dart               # Color palette definitions
│   └── theme.dart                # App-wide theme configuration
│
├── logic/                         # Business logic and data models
│   ├── Models/                   # Data models (Note: capital M)
│   │   ├── song_data.dart       # Song, Playlist, CachedMetadata models
│   │   ├── song_data.g.dart     # Hive type adapters (generated)
│   │   └── metadata_parser.dart # Filename → metadata extraction
│   └── music_provider.dart       # State management, playback, data
│
├── screens/                      # UI screens
│   ├── navigation_shell.dart    # Bottom navigation shell
│   ├── home_screen.dart          # Home with Daily Mix, Discovery
│   ├── library_screen.dart       # All songs library view
│   ├── search_screen.dart        # Search functionality
│   ├── playlist_screen.dart      # Playlist management
│   ├── playlist_detail_screen.dart  # Individual playlist view
│   ├── mix_detail_screen.dart    # Mix/collection detail view
│   ├── now_playing_screen.dart   # Full-screen player
│   └── settings_screen.dart      # App settings
│
├── widgets/                      # Reusable UI components
│   ├── mini_player.dart          # Bottom mini player bar
│   ├── mini_player_safe_scroll.dart  # Scroll-aware mini player
│   ├── song_tile.dart            # Song list item
│   ├── song_menu.dart            # Long-press song menu
│   ├── artwork_search_dialog.dart    # Manual artwork search
│   ├── blob_background.dart      # Organic shape painter
│   ├── category_chip.dart        # Filter chips
│   ├── filter_tab.dart           # Tab filters
│   ├── playlist_card.dart        # Playlist grid card
│   └── rotating_cd.dart          # Rotating album art animation
│
└── constants/
    └── ui_constants.dart         # UI constants and values
```

## Core Components

### 1. State Management (`music_provider.dart`)

**Purpose:** Central state manager using ChangeNotifier pattern

**Key Responsibilities:**
- Song library management
- Audio playback control (just_audio)
- Playlist CRUD operations
- Play history tracking
- Artwork fetching and caching
- Hive database persistence

**Important Getters:**
- `songs` - Filtered/searched songs
- `allSongs` - Complete library
- `currentSong` - Currently playing track
- `dailyMixSongs` - Songs played 3+ times
- `discoverySongs` - Random selection (10 songs)
- `recentlyPlayed` - Last 10 played songs

**Key Methods:**
- `fetchSongs()` - Query device audio files
- `playSong(index, customList)` - Start playback
- `searchArtwork(query)` - iTunes API search
- `setCustomArtwork(songId, url)` - Save custom artwork
- `toggleLike(song)` - Add/remove from favorites

### 2. Data Models (`Models/`)

#### SongData
```dart
@HiveType(typeId: 0)
class SongData extends HiveObject {
  final int id;           // Unique identifier
  final String title;     // Parsed from filename
  final String data;      // File path
  final String artist;    // Parsed from filename
  final String? albumArtUrl;
}
```

#### PlaylistData
```dart
@HiveType(typeId: 1)
class PlaylistData extends HiveObject {
  final String name;
  final List<int> songIds;  // References to SongData
}
```

#### CachedMetadata
```dart
@HiveType(typeId: 2)
class CachedMetadata extends HiveObject {
  final int songId;
  final String? localImagePath;  // Downloaded artwork
}
```

### 3. Metadata Parser (`metadata_parser.dart`)

**Purpose:** Extract song info from filenames

**Input:** `"Artist Name - Song Title.mp3"`  
**Output:** `{artist: "Artist Name", title: "Song Title"}`

**Fallbacks:**
- If no separator: title = filename, artist = "Unknown"
- Handles various formats and edge cases

### 4. Artwork System

**Auto-fetch:** When song plays → iTunes API search → download → cache  
**Manual fix:** Long-press → Fix Artwork → custom search → select

**Storage:**
- Memory: `_artworkCache` (Map<songId, path>)
- Disk: App documents directory (`art_{songId}.jpg`)
- Database: Hive `_metadataBox` for persistence

## Screen Hierarchy

```
NavigationShell (Bottom Nav)
├── HomeScreen
│   ├── Daily Mix Cards (with blob backgrounds)
│   ├── Discovery Card (with blob backgrounds)
│   └── Recently Played Grid
│
├── LibraryScreen
│   └── All Songs List
│
├── SearchScreen
│   └── Search Results
│
├── PlaylistScreen
│   └── Playlist Grid
│       └── PlaylistDetailScreen
│
└── SettingsScreen
```

## Data Flow

### Song Playback Flow
```
User taps song
    ↓
HomeScreen calls musicProvider.playSong(index, customList)
    ↓
MusicProvider creates audio sequence from customList
    ↓
AudioPlayer (just_audio) starts playback
    ↓
CurrentIndexStream updates → UI reflects changes
    ↓
MiniPlayer and NowPlayingScreen show current song
    ↓
Play count incremented → saved to Hive
    ↓
Auto-fetch artwork if not cached
```

### Artwork Fetch Flow
```
Song starts playing
    ↓
fetchInternetArtwork(song) called
    ↓
Check if cached → if yes, skip
    ↓
Query iTunes API with "{title} {artist}"
    ↓
Download high-res image (600x600)
    ↓
Save to app documents directory
    ↓
Update cache and Hive
    ↓
notifyListeners() → UI updates with new artwork
```

### Manual Artwork Fix Flow
```
Long-press song → showSongMenu()
    ↓
Select "Fix Artwork"
    ↓
ArtworkSearchDialog opens
    ↓
User enters custom search term
    ↓
searchArtwork(query) → iTunes API
    ↓
Show grid of results
    ↓
User selects artwork
    ↓
setCustomArtwork(songId, url)
    ↓
Download and save (overwrite existing)
```

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `just_audio` | Audio playback engine |
| `on_audio_query` | Query device audio files |
| `hive` | Local database |
| `http` | iTunes API requests |
| `dio` | Artwork downloads |
| `path_provider` | App directories |

## Important Patterns

### 1. Type Safety
⚠️ **Critical:** Always import from `logic/Models/song_data.dart` (capital M)  
The directory is named `Models` (not `models`)

### 2. Custom Lists
All playback functions accept `customList` parameter to play specific collections (playlists, mixes, search results)

### 3. Hive Persistence
- Songs: Not stored (queried from device each launch)
- Playlists: Stored as `PlaylistData` with song ID lists
- Metadata: Cached artwork paths
- Stats: Play counts, recent IDs

### 4. Responsive UI
- MiniPlayer adapts bottom padding based on presence
- Scroll-safe mini player prevents overlap
- Dynamic greeting based on time of day

## Feature Highlights

✅ **Implemented:**
- Local file playback
- Automatic filename parsing
- iTunes artwork fetching
- Manual artwork search and selection
- Liked songs / playlists
- Play history tracking
- Daily Mix (3+ plays)
- Discovery playlist
- Dynamic blob backgrounds on mix cards
- Glassmorphism effects
- Long-press song menus

🚧 **Potential Enhancements:**
- Equalizer
- Sleep timer
- Lyrics display
- Cross-device sync
- Playlist sharing
- Theme customization
- Gesture controls

## Build & Run

```bash
# Development
flutter run

# Release
flutter build apk --release
flutter build apk --split-per-abi  # Smaller APKs
```

## Notes

- **Image Format:** All custom artwork saved as JPG
- **Artwork Quality:** Downloaded at 600x600 (high-res)
- **Blob Seeds:** Daily Mix = 42, Discovery = 123 (consistent patterns)
- **Color Scheme:** Warm browns for Daily Mix, cool blues for Discovery
