import 'package:hive/hive.dart';

part 'song_data.g.dart';

@HiveType(typeId: 0)
class SongData extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String data; // File path/URI

  SongData({required this.id, required this.title, required this.data});
}

@HiveType(typeId: 1)
class PlaylistData extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final List<int> songIds; // Store only song IDs

  PlaylistData({required this.name, required this.songIds});
}

@HiveType(typeId: 2) // Ensure this is unique
class CachedMetadata extends HiveObject {
  @HiveField(0)
  final int songId;

  @HiveField(1)
  final String? localImagePath;

  CachedMetadata({required this.songId, this.localImagePath});
}
