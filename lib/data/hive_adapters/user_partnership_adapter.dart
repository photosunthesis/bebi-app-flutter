import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class UserPartnershipAdapter extends TypeAdapter<UserPartnership> {
  @override
  final int typeId = 3;

  @override
  UserPartnership read(BinaryReader reader) {
    final id = reader.readString();
    final usersLength = reader.readInt();
    final users = List.generate(usersLength, (_) => reader.readString());
    final createdBy = reader.readString();
    final createdAtMillis = reader.readInt();
    final updatedAtMillis = reader.readInt();

    return UserPartnership(
      id: id,
      users: users,
      createdBy: createdBy,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        createdAtMillis,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        updatedAtMillis,
        isUtc: true,
      ),
    );
  }

  @override
  void write(BinaryWriter writer, UserPartnership obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.users.length);
    for (final user in obj.users) {
      writer.writeString(user);
    }
    writer.writeString(obj.createdBy);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}
