import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final firebaseAuthProvider = Provider((_) => FirebaseAuth.instance);

final firebaseFirestoreProvider = Provider((_) => FirebaseFirestore.instance);

final firebaseAnalyticsProvider = Provider((_) => FirebaseAnalytics.instance);

final firebaseCrashlyticsProvider = Provider(
  (_) => FirebaseCrashlytics.instance,
);

final firebaseFunctionsProvider = Provider(
  (_) => FirebaseFunctions.instanceFor(region: 'asia-east1'),
);

final generativeModelProvider = Provider(
  (_) => FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash-lite',
    safetySettings: [
      SafetySetting(
        HarmCategory.sexuallyExplicit,
        HarmBlockThreshold.none,
        null,
      ),
    ],
  ),
);
