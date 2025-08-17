import 'dart:async';
import 'dart:io';

import 'package:bebi_app/app/app.dart';
import 'package:bebi_app/config/dependencies.dart';
import 'package:bebi_app/config/firebase_options.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/hive_registrar.g.dart';
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

    // Configure dependencies after Firebase and Hive are initialized
    await configureDependencies();

    // Clear local storage on new version after initializing everything
    await _clearLocalStorageOnNewVersion();

    runApp(const App());
  });
}

Future<void> _configureFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }
}

void _configureFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final licenses = await Future.wait([
      rootBundle.loadString('assets/fonts/ibm_plex_mono/OFL.txt'),
      rootBundle.loadString('assets/fonts/ibm_plex_sans/OFL.txt'),
      rootBundle.loadString('assets/fonts/vidaloka/OFL.txt'),
    ]);
    yield LicenseEntryWithLineBreaks(['IBMPlexMono'], licenses[0]);
    yield LicenseEntryWithLineBreaks(['IBMPlexSans'], licenses[1]);
    yield LicenseEntryWithLineBreaks(['Vidaloka'], licenses[2]);
  });
}

Future<void> _configureHighRefreshScreen() async {
  try {
    if (Platform.isAndroid) {
      await FlutterRefreshRateControl().requestHighRefreshRate();
    }
  } catch (e, s) {
    if (!kDebugMode) await FirebaseCrashlytics.instance.recordError(e, s);
  }
}

Future<void> _configureHive() async {
  await Hive.initFlutter();
  Hive.registerAdapters();
}

Future<void> _clearLocalStorageOnNewVersion() async {
  final box = await Hive.openBox('settings');
  final previousVersion = box.get('version', defaultValue: '');
  final packageVersion = GetIt.I<PackageInfo>().version;
  if (previousVersion != packageVersion) {
    await Future.wait([
      box.put('version', packageVersion),
      GetIt.I<Box<CalendarEvent>>().clear(),
      GetIt.I<Box<CycleLog>>().clear(),
      GetIt.I<Box<UserProfile>>().clear(),
      GetIt.I<Box<UserPartnership>>().clear(),
      GetIt.I<Box<String>>().clear(),
    ]);
  }
}
