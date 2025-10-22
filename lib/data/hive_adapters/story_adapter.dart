import 'package:bebi_app/constants/type_adapter_ids.dart';
import 'package:bebi_app/data/models/story.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class StoryAdapter extends TypeAdapter<Story> {
  @override
  final int typeId = TypeAdapterIds.story;

  @override
  Story read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    final storageObjectName = reader.readString();
    final createdBy = reader.readString();
    final users = List<String>.from(reader.read() as List);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final blurHash = reader.readString();
    return Story(
      id: id,
      title: title,
      storageObjectName: storageObjectName,
      createdBy: createdBy,
      users: users,
      createdAt: createdAt,
      blurHash: blurHash,
    );
  }

  @override
  void write(BinaryWriter writer, Story obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.storageObjectName);
    writer.writeString(obj.createdBy);
    writer.write(obj.users);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeString(obj.blurHash);
  }
}
