import 'package:bebi_app/constants/type_adapter_ids.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = TypeAdapterIds.userProfile;

  @override
  UserProfile read(BinaryReader reader) {
    final userId = reader.readString();
    final code = reader.readString();
    final birthDate = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final displayName = reader.readString();
    final profilePictureStorageNameExists = reader.readBool();
    final profilePictureStorageName = profilePictureStorageNameExists
        ? reader.readString()
        : null;
    final createdBy = reader.readString();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final didSetUpCycles = reader.readBool();
    final hasCycle = reader.readBool();
    final isSharingCycleWithPartner = reader.readBool();
    final fcmTokens = List<String>.from(reader.readList());

    return UserProfile(
      userId: userId,
      code: code,
      birthDate: birthDate,
      displayName: displayName,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      profilePictureStorageName: profilePictureStorageName,
      didSetUpCycles: didSetUpCycles,
      hasCycle: hasCycle,
      isSharingCycleWithPartner: isSharingCycleWithPartner,
      fcmTokens: fcmTokens,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeString(obj.userId);
    writer.writeString(obj.code);
    writer.writeInt(obj.birthDate.millisecondsSinceEpoch);
    writer.writeString(obj.displayName);
    writer.writeBool(obj.profilePictureStorageName != null);
    if (obj.profilePictureStorageName != null) {
      writer.writeString(obj.profilePictureStorageName!);
    }
    writer.writeString(obj.createdBy);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
    writer.writeBool(obj.didSetUpCycles);
    writer.writeBool(obj.hasCycle);
    writer.writeBool(obj.isSharingCycleWithPartner);
    writer.writeList(obj.fcmTokens);
  }
}
