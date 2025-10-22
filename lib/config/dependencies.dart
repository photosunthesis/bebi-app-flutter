import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/models/story.dart';
import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'dependencies.config.dart';

@InjectableInit()
Future<void> configureDependencies() async => GetIt.I.init();

@module
abstract class Dependencies {
  @lazySingleton
  FirebaseAuth auth(GoRouter router) =>
      FirebaseAuth.instance
        ..authStateChanges().listen((user) {
          if (user == null) router.goNamed(AppRoutes.signIn);
        });

  @lazySingleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  @lazySingleton
  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  @lazySingleton
  FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;

  @lazySingleton
  FirebaseFunctions get functions =>
      FirebaseFunctions.instanceFor(region: 'asia-east1');

  @lazySingleton
  GenerativeModel get geminiModel => FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash-lite',
    safetySettings: [
      SafetySetting(
        HarmCategory.sexuallyExplicit,
        HarmBlockThreshold.none,
        null,
      ),
    ],
  );

  ImagePicker get imagePicker => ImagePicker();

  @preResolve
  Future<PackageInfo> get packageInfo async => PackageInfo.fromPlatform();

  @preResolve
  Future<Box<CalendarEvent>> get calendarEventBox async =>
      Hive.openBox<CalendarEvent>('calendar_events');

  @preResolve
  Future<Box<CycleLog>> get cycleLogBox async =>
      Hive.openBox<CycleLog>('cycle_logs');

  @preResolve
  Future<Box<UserProfile>> get userProfileBox async =>
      Hive.openBox<UserProfile>('user_profiles');

  @preResolve
  Future<Box<UserPartnership>> get userPartnershipBox async =>
      Hive.openBox<UserPartnership>('user_partnerships');

  @Named('ai_insights_box')
  @preResolve
  Future<Box<String>> get aiInsightsBox async =>
      Hive.openBox<String>('ai_insights');

  @preResolve
  Future<Box<Story>> get storyBox async => Hive.openBox<Story>('stories');

  @Named('story_image_url_box')
  @preResolve
  Future<Box<String>> get storyImageUrlBox async =>
      Hive.openBox<String>('story_image_urls');
}
