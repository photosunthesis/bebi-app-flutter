import 'dart:async';
import 'dart:io';

import 'package:bebi_app/app/app.dart';
import 'package:bebi_app/app/error_app.dart';
import 'package:bebi_app/config/dependencies.dart';
import 'package:bebi_app/config/firebase_options.dart';
import 'package:bebi_app/data/hive_adapters/calendar_event_adapter.dart';
import 'package:bebi_app/data/hive_adapters/cycle_log_adapter.dart';
import 'package:bebi_app/data/hive_adapters/repeat_rule_adapter.dart';
import 'package:bebi_app/data/hive_adapters/user_partnership_adapter.dart';
import 'package:bebi_app/data/hive_adapters/user_profile_adapter.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _attemptInitialization();
}

void _attemptInitialization({int attempt = 1, int maxAttempts = 3}) {
  _initializeApp(
    attempt: attempt,
    onSuccess: () async => _initializeSentry(const App()),
    onError: (error, stackTrace) async {
      final shouldRetry = attempt < maxAttempts;

      runApp(
        ErrorApp(
          error: error,
          attemptNumber: attempt,
          maxAttempts: maxAttempts,
          canRetry: shouldRetry,
          onRetry: shouldRetry
              ? () => _attemptInitialization(
                  attempt: attempt + 1,
                  maxAttempts: maxAttempts,
                )
              : null,
        ),
      );
    },
  );
}

Future<void> _initializeApp({
  required int attempt,
  required Future<void> Function() onSuccess,
  required Function(Object error, StackTrace stackTrace) onError,
}) async {
  try {
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

    await onSuccess();
  } catch (error, stackTrace) {
    onError(error, stackTrace);
  }
}

Future<void> _initializeSentry(Widget appWidget) async {
  final sentryDsn = await _getSentryDsn();

  if (sentryDsn.isNotEmpty || !kDebugMode) {
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.sendDefaultPii = true;
      options.enableLogs = true;
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
      options.replay.sessionSampleRate = 0.1;
      options.replay.onErrorSampleRate = 1.0;
    }, appRunner: () => runApp(SentryWidget(child: appWidget)));
  } else {
    runApp(appWidget);
  }
}

Future<String> _getSentryDsn() async {
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    await remoteConfig.setDefaults({'sentry_dsn': ''});
    await remoteConfig.fetchAndActivate();

    return remoteConfig.getString('sentry_dsn');
  } catch (e) {
    return '';
  }
}

Future<void> _configureFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
  } catch (_) {
    // If this fails... oh well :D
  }
}

Future<void> _configureHive() async {
  await Hive.initFlutter();
  Hive
    ..registerAdapter(CalendarEventAdapter())
    ..registerAdapter(RepeatRuleAdapter())
    ..registerAdapter(CycleLogAdapter())
    ..registerAdapter(UserProfileAdapter())
    ..registerAdapter(UserPartnershipAdapter());
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
    await box.put('version', packageVersion);
  }
}
