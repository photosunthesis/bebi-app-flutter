import 'package:bebi_app/constants/hive_constants.dart';
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
      Hive.openBox<CalendarEvent>(HiveBoxNames.calendarEvent);

  @preResolve
  Future<Box<CycleLog>> get cycleLogBox async =>
      Hive.openBox<CycleLog>(HiveBoxNames.cycleLog);

  @preResolve
  Future<Box<UserProfile>> get userProfileBox async =>
      Hive.openBox<UserProfile>(HiveBoxNames.userProfile);

  @preResolve
  Future<Box<UserPartnership>> get userPartnershipBox async =>
      Hive.openBox<UserPartnership>(HiveBoxNames.userPartnership);

  @preResolve
  Future<Box<String>> get aiSummaryAndInsightsBox async =>
      Hive.openBox<String>(HiveBoxNames.aiSummaryAndInsights);
}
