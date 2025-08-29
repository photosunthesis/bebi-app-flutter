import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class RepeatRuleAdapter extends TypeAdapter<RepeatRule> {
  @override
  final int typeId = 2;

  @override
  RepeatRule read(BinaryReader reader) {
    final frequencyIndex = reader.readInt();
    final occurrences = reader.readInt();
    final excludedDatesLength = reader.readInt();
    final excludedDates = excludedDatesLength == -1
        ? null
        : List.generate(
            excludedDatesLength,
            (_) => DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
          );

    return RepeatRule(
      frequency: RepeatFrequency.values[frequencyIndex],
      occurrences: occurrences == -1 ? null : occurrences,
      excludedDates: excludedDates,
    );
  }

  @override
  void write(BinaryWriter writer, RepeatRule obj) {
    writer.writeInt(obj.frequency.index);
    writer.writeInt(obj.occurrences ?? -1);

    if (obj.excludedDates == null) {
      writer.writeInt(-1);
    } else {
      writer.writeInt(obj.excludedDates!.length);
      for (final date in obj.excludedDates!) {
        writer.writeInt(date.millisecondsSinceEpoch);
      }
    }
  }
}
