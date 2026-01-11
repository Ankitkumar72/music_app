class MetadataParser {
  static Map<String, String> parse(String rawName) {
    // 1. Clean the string
    final noiseRegex = RegExp(r'\(.*?\)|\[.*?\]|Full Video|Official Video|Lyrics', caseSensitive: false);
    String cleanString = rawName.replaceAll(noiseRegex, "").trim();

    // 2. Split by separators
    List<String> segments = cleanString
        .split(RegExp(r'[-_|~]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Default values
    String title = rawName;
    String artist = "Unknown Artist";

    if (segments.length >= 2) {
      
      if (segments[1].length > segments[0].length) {
        artist = segments[0];
        title = segments[1];
      } else {
        
        title = segments[0];
        artist = segments[1];
      }
    }

    return {
      'title': title,
      'artist': artist,
    };
  }
}