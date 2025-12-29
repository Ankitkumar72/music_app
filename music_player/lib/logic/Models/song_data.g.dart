// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongDataAdapter extends TypeAdapter<SongData> {
  @override
  final int typeId = 0;

  @override
  SongData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SongData(
      id: fields[0] as int,
      title: fields[1] as String,
      data: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SongData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.data);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlaylistDataAdapter extends TypeAdapter<PlaylistData> {
  @override
  final int typeId = 1;

  @override
  PlaylistData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaylistData(
      name: fields[0] as String,
      songIds: (fields[1] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, PlaylistData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.songIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
