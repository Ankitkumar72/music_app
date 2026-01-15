import 'package:hive/hive.dart';
import 'metadata_parser.dart';

part 'song_data.g.dart';

@HiveType(typeId: 0)
class SongData extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String data;

  @HiveField(3)
  final String artist;

  @HiveField(4)
  final String? albumArtUrl;

  @HiveField(5)
  final String album;

  @HiveField(6)
  final int? duration;

  SongData({
    required this.id,
    required this.title,
    required this.data,
    required this.artist,
    this.albumArtUrl,
    this.album = 'Unknown Album',
    this.duration,
  });

  // REQUIRED: This fixes the 'fromFile' method error in music_provider.dart
  factory SongData.fromFile({required int id, required String filePath, int? duration, String? album}) {
    String rawFileName = filePath.split('/').last.split('.').first;
    final metadata = MetadataParser.parse(rawFileName);

    return SongData(
      id: id,
      title: metadata['title']!,
      artist: metadata['artist']!,
      data: filePath,
      albumArtUrl: null,
      album: album ?? 'Unknown Album',
      duration: duration,
    );
  }
}

@HiveType(typeId: 1)
class PlaylistData extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final List<int> songIds;

  PlaylistData({required this.name, required this.songIds});
}

@HiveType(typeId: 2)
class CachedMetadata extends HiveObject {
  @HiveField(0)
  final int songId;

  @HiveField(1)
  final String? localImagePath;

  CachedMetadata({required this.songId, this.localImagePath});
}

