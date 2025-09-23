import 'package:bebi_app/constants/type_adapter_ids.dart';
import 'package:bebi_app/data/models/story.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class StoryAdapter extends TypeAdapter<Story> {
  @override
  final int typeId = TypeAdapterIds.story;

  @override
  Story read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Story(
      id: fields[0] as String,
      title: fields[1] as String,
      photoUrl: fields[2] as String,
      createdBy: fields[3] as String,
      users: List<String>.from(fields[4] as List),
      createdAt: (fields[5] as DateTime).toUtc(),
      blurHash: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Story obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.photoUrl)
      ..writeByte(3)
      ..write(obj.createdBy)
      ..writeByte(4)
      ..write(obj.users)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.blurHash);
  }
}
