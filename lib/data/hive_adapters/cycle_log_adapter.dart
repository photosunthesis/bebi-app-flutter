import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class CycleLogAdapter extends TypeAdapter<CycleLog> {
  @override
  final int typeId = 1;

  @override
  CycleLog read(BinaryReader reader) {
    final id = reader.readString();
    final dateMillis = reader.readInt();
    final typeIndex = reader.readInt();
    final flowIndex = reader.readInt();
    final symptomsLength = reader.readInt();
    final symptoms = symptomsLength == -1
        ? null
        : List.generate(symptomsLength, (_) => reader.readString());
    final intimacyTypeIndex = reader.readInt();
    final ownedBy = reader.readString();
    final createdBy = reader.readString();
    final createdAtMillis = reader.readInt();
    final updatedAtMillis = reader.readInt();
    final usersLength = reader.readInt();
    final users = List.generate(usersLength, (_) => reader.readString());
    final isPrediction = reader.readBool();

    return CycleLog(
      id: id,
      date: DateTime.fromMillisecondsSinceEpoch(dateMillis, isUtc: true),
      type: LogType.values[typeIndex],
      flow: flowIndex == -1 ? null : FlowIntensity.values[flowIndex],
      symptoms: symptoms,
      intimacyType: intimacyTypeIndex == -1
          ? null
          : IntimacyType.values[intimacyTypeIndex],
      ownedBy: ownedBy,
      createdBy: createdBy,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        createdAtMillis,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        updatedAtMillis,
        isUtc: true,
      ),
      users: users,
      isPrediction: isPrediction,
    );
  }

  @override
  void write(BinaryWriter writer, CycleLog obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.date.toUtc().millisecondsSinceEpoch);
    writer.writeInt(obj.type.index);
    writer.writeInt(obj.flow?.index ?? -1);

    if (obj.symptoms == null) {
      writer.writeInt(-1);
    } else {
      writer.writeInt(obj.symptoms!.length);
      for (final symptom in obj.symptoms!) {
        writer.writeString(symptom);
      }
    }

    writer.writeInt(obj.intimacyType?.index ?? -1);
    writer.writeString(obj.ownedBy);
    writer.writeString(obj.createdBy);
    writer.writeInt(obj.createdAt.toUtc().millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.toUtc().millisecondsSinceEpoch);
    writer.writeInt(obj.users.length);
    for (final user in obj.users) {
      writer.writeString(user);
    }
    writer.writeBool(obj.isPrediction);
  }
}
