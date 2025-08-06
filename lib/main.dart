import 'dart:async';
import 'dart:io';

import 'package:bebi_app/app/app.dart';
import 'package:bebi_app/config/firebase_options.dart';
import 'package:bebi_app/config/injectable.dart';
import 'package:bebi_app/hive_registrar.g.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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

    // Configure dependencies after Firebase and Hive are initialized
    await configureDependencies();

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
    if (!kDebugMode) await FirebaseCrashlytics.instance.recordError(e, s);
  }
}

Future<void> _initializeHive() async {
  await Hive.initFlutter();
  Hive.registerAdapters();
}
