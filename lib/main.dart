import 'dart:async';

import 'package:bebi_app/app/app.dart';
import 'package:bebi_app/config/firebase_options.dart';
import 'package:bebi_app/config/firebase_services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  runZoned(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();
    await _configureFirebase();
    await _configureHighRefreshScreen();
    _configureFontLicenses();
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
    await FlutterRefreshRateControl().requestHighRefreshRate();
  } catch (e, s) {
    if (!kDebugMode) FirebaseServices.crashlytics.recordError(e, s);
  }
}
