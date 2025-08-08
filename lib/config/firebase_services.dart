import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

@module
abstract class FirebaseServices {
  @lazySingleton
  FirebaseAuth get auth => FirebaseAuth.instance;

  @lazySingleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  @lazySingleton
  FirebaseStorage get storage => FirebaseStorage.instance;

  @lazySingleton
  FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;

  @lazySingleton
  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

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
}
