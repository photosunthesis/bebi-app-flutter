import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/event_color.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';

enum CycleEventType { period, fertile }

class CycleEvent extends CalendarEvent {
  const CycleEvent({
    required super.id,
    required super.title,
    required super.date,
    required super.startTime,
    required super.endTime,
    required super.createdAt,
    required super.updatedAt,
    required super.users,
    required CycleEventType cycleEventType,
    required bool isPrediction,
  }) : super(
         allDay: true,
         repeatRule: const RepeatRule(frequency: RepeatFrequency.doNotRepeat),
         eventColor: EventColors.red,
         isCycleEvent: true,
         createdBy: '',
         notes:
             '${cycleEventType == CycleEventType.period ? 'Period' : 'Fertile'}|##|${isPrediction ? 'prediction' : 'actual'}',
       );

  CycleEventType get cycleEventType => notes!.split('|##|')[0] == 'Period'
      ? CycleEventType.period
      : CycleEventType.fertile;

  bool get isPrediction => notes!.split('|##|')[1] == 'prediction';
}
