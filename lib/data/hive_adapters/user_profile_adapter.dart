import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 4;

  @override
  UserProfile read(BinaryReader reader) {
    final userId = reader.readString();
    final code = reader.readString();
    final birthDate = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final displayName = reader.readString();
    final photoUrl = reader.readBool() ? reader.readString() : null;
    final createdBy = reader.readString();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final didSetUpCycles = reader.readBool();
    final hasCycle = reader.readBool();
    final isSharingCycleWithPartner = reader.readBool();

    return UserProfile(
      userId: userId,
      code: code,
      birthDate: birthDate,
      displayName: displayName,
      photoUrl: photoUrl,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      didSetUpCycles: didSetUpCycles,
      hasCycle: hasCycle,
      isSharingCycleWithPartner: isSharingCycleWithPartner,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeString(obj.userId);
    writer.writeString(obj.code);
    writer.writeInt(obj.birthDate.millisecondsSinceEpoch);
    writer.writeString(obj.displayName);
    writer.writeBool(obj.photoUrl != null);
    if (obj.photoUrl != null) writer.writeString(obj.photoUrl!);
    writer.writeString(obj.createdBy);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
    writer.writeBool(obj.didSetUpCycles);
    writer.writeBool(obj.hasCycle);
    writer.writeBool(obj.isSharingCycleWithPartner);
  }
}
