import 'dart:async';

import 'package:bebi_app/app/app.dart';
import 'package:bebi_app/config/firebase_options.dart';
import 'package:bebi_app/config/hive_providers.dart';
import 'package:bebi_app/config/utility_packages_provider.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/models/hive_adapters/calendar_event_adapter.dart';
import 'package:bebi_app/data/models/hive_adapters/cycle_log_adapter.dart';
import 'package:bebi_app/data/models/hive_adapters/repeat_rule_adapter.dart';
import 'package:bebi_app/data/models/hive_adapters/story_adapter.dart';
import 'package:bebi_app/data/models/hive_adapters/user_partnership_adapter.dart';
import 'package:bebi_app/data/models/hive_adapters/user_profile_adapter.dart';
import 'package:bebi_app/data/models/story.dart';
import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/utils/platform/platform_utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  runZoned(() async {
    WidgetsFlutterBinding.ensureInitialized();
    _configureFontLicenses();

    await _configureFirebase();
    await _configureHighRefreshScreen();

    final packageInfo = await PackageInfo.fromPlatform();
    final boxes = await _configureHive();

    final hiveBoxOverrides = [
      calendarBoxProvider.overrideWithValue(boxes[0] as Box<CalendarEvent>),
      cycleLogBoxProvider.overrideWithValue(boxes[1] as Box<CycleLog>),
      userProfileBoxProvider.overrideWithValue(boxes[2] as Box<UserProfile>),
      userPartnershipBoxProvider.overrideWithValue(
        boxes[3] as Box<UserPartnership>,
      ),
      aiInsightsBoxProvider.overrideWithValue(boxes[4] as Box<String>),
      storyBoxProvider.overrideWithValue(boxes[5] as Box<Story>),
      storyImageUrlBoxProvider.overrideWithValue(boxes[6] as Box<String>),
    ];

    await _clearLocalStorageOnNewVersion(boxes, packageInfo);

    runApp(
      UncontrolledProviderScope(
        container: globalContainer,
        child: ProviderScope(
          overrides: [
            ...hiveBoxOverrides,
            packageInfoProvider.overrideWithValue(packageInfo),
          ],
          child: const App(),
        ),
      ),
    );
  });
}

Future<void> _configureFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

void _configureFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final licenses = await Future.wait([
      rootBundle.loadString('assets/fonts/ibm_plex_sans/OFL.txt'),
      rootBundle.loadString('assets/fonts/vidaloka/OFL.txt'),
    ]);
    yield LicenseEntryWithLineBreaks(['IBMPlexSans'], licenses[0]);
    yield LicenseEntryWithLineBreaks(['Vidaloka'], licenses[1]);
  });
}

Future<void> _configureHighRefreshScreen() async {
  try {
    if (kIsAndroid) {
      await FlutterRefreshRateControl().requestHighRefreshRate();
    }
  } catch (_) {
    // No worries if this fails
  }
}

Future<List<Box>> _configureHive() async {
  await Hive.initFlutter();
  Hive
    ..registerAdapter(CalendarEventAdapter())
    ..registerAdapter(RepeatRuleAdapter())
    ..registerAdapter(CycleLogAdapter())
    ..registerAdapter(UserProfileAdapter())
    ..registerAdapter(UserPartnershipAdapter())
    ..registerAdapter(StoryAdapter());

  final boxes = await Future.wait<Box>([
    Hive.openBox<CalendarEvent>('calendar_events'),
    Hive.openBox<CycleLog>('cycle_logs'),
    Hive.openBox<UserProfile>('user_profiles'),
    Hive.openBox<UserPartnership>('user_partnerships'),
    Hive.openBox<String>('ai_insights_box'),
    Hive.openBox<Story>('stories'),
    Hive.openBox<String>('story_image_url_box'),
  ]);

  return boxes;
}

Future<void> _clearLocalStorageOnNewVersion(
  List<Box> boxes,
  PackageInfo packageInfo,
) async {
  final settingsBox = await Hive.openBox('settings');
  final previousVersion = settingsBox.get('version', defaultValue: '');
  final packageVersion = packageInfo.version;

  if (previousVersion != packageVersion) {
    for (final box in boxes) {
      await box.clear();
    }

    await settingsBox.put('version', packageVersion);
  }
}
