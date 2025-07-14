import 'dart:async';

import 'package:bebi_app/app/app.dart';
import 'package:bebi_app/config/firebase_options.dart';
import 'package:bebi_app/config/firebase_services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runZoned(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await _configureFirebase();
    _configureNavigationColors();
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

/// This workaround is mainly for Android: it ensures the navigation bar is transparent
/// and the status bar icons are dark. Without this, content may be covered by the navigation bar.
void _configureNavigationColors() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );
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
