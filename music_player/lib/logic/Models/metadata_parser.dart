class MetadataParser {
  static Map<String, String> parse(String rawName) {
    // 1. Initial Cleanup: Remove file extensions and common junk
    String cleanString = rawName;
    
    // Remove "official video", "lyrics", "audio", bitrates, etc.
    final noiseRegex = RegExp(
      r'\(.*?\)|\[.*?\]|official\s+video|lyric\s+video|official\s+audio|\d+kbps|www\..*?\.(com|net|org)|[\w-]+\.(com|net|org)',
      caseSensitive: false,
    );
    cleanString = cleanString.replaceAll(noiseRegex, " ").trim();
    
    // Remove extra whitespace
    cleanString = cleanString.replaceAll(RegExp(r'\s+'), ' ');

    String title = cleanString;
    String artist = "Unknown Artist";

    // 2. Intelligent Splitting
    // Priority 1: standard " - " (Space Hyphen Space)
    if (cleanString.contains(" - ")) {
      final parts = cleanString.split(" - ");
      if (parts.length >= 2) {
        artist = parts[0].trim();
        title = parts.sublist(1).join(" - ").trim(); // Join rest as title
      }
    } 
    // Priority 2: " by "
    else if (cleanString.toLowerCase().contains(" by ")) {
      final parts = cleanString.split(RegExp(r'\s+by\s+', caseSensitive: false));
      if (parts.length >= 2) {
        title = parts[0].trim();
        artist = parts[1].trim();
      }
    }
    // Priority 3: Fallback to single hyphen if it looks reasonable
    // (Ensure it's not just a hyphen in a name like "Jay-Z")
    else if (cleanString.contains("-")) {
      final parts = cleanString.split("-");
      // Heuristic: If we have exactly 2 parts, assume Artist - Title
      if (parts.length == 2) {
        artist = parts[0].trim();
        title = parts[1].trim();
      }
      // If many parts, it's risky to guess, so default to Title = Filename
    }

    // 3. Post-Processing
    // Handle "feat." in title or artist
    // (We generally want to keep feat info in the title, not the artist field for display brevity)
    
    return {
      'title': title,
      'artist': artist,
    };
  }
}