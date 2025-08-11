import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@module
abstract class HiveBoxes {
  @preResolve
  Future<Box<CalendarEvent>> get calendarEventBox async =>
      Hive.openBox<CalendarEvent>('calendar_events_box');

  @preResolve
  Future<Box<CycleLog>> get cycleLogBox async =>
      Hive.openBox<CycleLog>('cycle_logs_box');

  @preResolve
  Future<Box<UserProfile>> get userProfileBox async =>
      Hive.openBox<UserProfile>('user_profiles_box');

  @preResolve
  Future<Box<UserPartnership>> get userPartnershipBox async =>
      Hive.openBox<UserPartnership>('user_partnerships_box');

  @preResolve
  Future<Box<String>> get aiSummaryAndInsightsBox async =>
      Hive.openBox<String>('ai_summary_and_insights_box');
}
