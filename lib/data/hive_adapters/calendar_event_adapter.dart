import 'package:bebi_app/data/hive_adapters/repeat_rule_adapter.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class CalendarEventAdapter extends TypeAdapter<CalendarEvent> {
  @override
  final int typeId = 0;

  @override
  CalendarEvent read(BinaryReader reader) {
    final id = reader.readString();
    final recurringEventId = reader.readBool() ? reader.readString() : null;
    final title = reader.readString();
    final notes = reader.readBool() ? reader.readString() : null;
    final date = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final startTime = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final endTime = reader.readBool()
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;
    final allDay = reader.readBool();
    final repeatRule = RepeatRuleAdapter().read(reader);
    final eventColor = EventColor.values[reader.readInt()];
    final usersLength = reader.readInt();
    final users = List.generate(usersLength, (_) => reader.readString());
    final createdBy = reader.readString();
    final updatedBy = reader.readString();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());

    return CalendarEvent(
      id: id,
      recurringEventId: recurringEventId,
      title: title,
      notes: notes,
      date: date,
      startTime: startTime,
      endTime: endTime,
      allDay: allDay,
      repeatRule: repeatRule,
      eventColor: eventColor,
      users: users,
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  void write(BinaryWriter writer, CalendarEvent obj) {
    writer.writeString(obj.id);
    writer.writeBool(obj.recurringEventId != null);
    if (obj.recurringEventId != null) {
      writer.writeString(obj.recurringEventId!);
    }
    writer.writeString(obj.title);
    writer.writeBool(obj.notes != null);
    if (obj.notes != null) {
      writer.writeString(obj.notes!);
    }
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeInt(obj.startTime.millisecondsSinceEpoch);
    writer.writeBool(obj.endTime != null);
    if (obj.endTime != null) {
      writer.writeInt(obj.endTime!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.allDay);
    RepeatRuleAdapter().write(writer, obj.repeatRule);
    writer.writeInt(obj.eventColor.index);
    writer.writeInt(obj.users.length);
    for (final user in obj.users) {
      writer.writeString(user);
    }
    writer.writeString(obj.createdBy);
    writer.writeString(obj.updatedBy);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}
