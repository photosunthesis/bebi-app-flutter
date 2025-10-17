import 'dart:async';

import 'package:bebi_app/app/app.dart';
import 'package:bebi_app/config/dependencies.dart';
import 'package:bebi_app/config/firebase_options.dart';
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
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  runZoned(() async {
    WidgetsFlutterBinding.ensureInitialized();
    _configureFontLicenses();

    await Future.wait([
      _configureFirebase(),
      _configureHighRefreshScreen(),
      _configureHive(),
    ]);

    await configureDependencies();
    await _clearLocalStorageOnNewVersion();

    runApp(const App());
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

Future<void> _configureHive() async {
  await Hive.initFlutter();
  Hive
    ..registerAdapter(CalendarEventAdapter())
    ..registerAdapter(RepeatRuleAdapter())
    ..registerAdapter(CycleLogAdapter())
    ..registerAdapter(UserProfileAdapter())
    ..registerAdapter(UserPartnershipAdapter())
    ..registerAdapter(StoryAdapter());
}

Future<void> _clearLocalStorageOnNewVersion() async {
  final box = await Hive.openBox('settings');
  final previousVersion = box.get('version', defaultValue: '');
  final packageVersion = GetIt.I<PackageInfo>().version;
  if (previousVersion != packageVersion) {
    await GetIt.I<Box<CalendarEvent>>().clear();
    await GetIt.I<Box<CycleLog>>().clear();
    await GetIt.I<Box<UserProfile>>().clear();
    await GetIt.I<Box<UserPartnership>>().clear();
    await GetIt.I<Box<String>>().clear();
    await GetIt.I<Box<Story>>().clear();
    await box.put('version', packageVersion);
  }
}
