import 'dart:async';
import 'dart:io';

import 'package:bebi_app/app/app.dart';
import 'package:bebi_app/config/firebase_options.dart';
import 'package:bebi_app/config/firebase_services.dart';
import 'package:bebi_app/constants/hive_constants.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/hive_registrar.g.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  runZoned(() async {
    WidgetsFlutterBinding.ensureInitialized();
    _configureFontLicenses();

    await Future.wait([
      _configureFirebase(),
      _configureHighRefreshScreen(),
      _initializeHive(),
    ]);

    // Add more hive boxes as needed
    await Future.wait([
      Hive.openBox<CalendarEvent>(HiveBoxNames.calendarEvent),
      Hive.openBox<UserProfile>(HiveBoxNames.userProfile),
      Hive.openBox<UserPartnership>(HiveBoxNames.userPartnership),
      Hive.openBox<CycleLog>(HiveBoxNames.cycleLog),
      Hive.openBox<bool>(HiveBoxNames.userPreferences),
    ]);

    runApp(const App());
  });
}

Future<void> _configureFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kDebugMode) {
    FlutterError.onError = FirebaseServices.crashlytics.recordFlutterFatalError;
  }
}

void _configureFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final licenses = await Future.wait(<Future<String>>[
      rootBundle.loadString('assets/fonts/ibm_plex_mono/OFL.txt'),
      rootBundle.loadString('assets/fonts/ibm_plex_sans/OFL.txt'),
      rootBundle.loadString('assets/fonts/vidaloka/OFL.txt'),
    ]);
    yield LicenseEntryWithLineBreaks(<String>['IBMPlexMono'], licenses[0]);
    yield LicenseEntryWithLineBreaks(<String>['IBMPlexSans'], licenses[1]);
    yield LicenseEntryWithLineBreaks(<String>['Vidaloka'], licenses[2]);
  });
}

Future<void> _configureHighRefreshScreen() async {
  try {
    if (Platform.isAndroid) {
      await FlutterRefreshRateControl().requestHighRefreshRate();
    }
  } catch (e, s) {
    if (!kDebugMode) await FirebaseServices.crashlytics.recordError(e, s);
  }
}

Future<void> _initializeHive() async {
  await Hive.initFlutter();
  Hive.registerAdapters();
}
