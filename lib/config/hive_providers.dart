import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/models/story.dart';
import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final calendarBoxProvider = Provider<Box<CalendarEvent>>(
  (_) => throw UnimplementedError('Override this in main.dart'),
);

final cycleLogBoxProvider = Provider<Box<CycleLog>>(
  (_) => throw UnimplementedError('Override this in main.dart'),
);

final userProfileBoxProvider = Provider<Box<UserProfile>>(
  (_) => throw UnimplementedError('Override this in main.dart'),
);

final userPartnershipBoxProvider = Provider<Box<UserPartnership>>(
  (_) => throw UnimplementedError('Override this in main.dart'),
);

final aiInsightsBoxProvider = Provider<Box<String>>(
  (_) => throw UnimplementedError('Override this in main.dart'),
);

final storyBoxProvider = Provider<Box<Story>>(
  (_) => throw UnimplementedError('Override this in main.dart'),
);

final storyImageUrlBoxProvider = Provider<Box<String>>(
  (_) => throw UnimplementedError('Override this in main.dart'),
);
