import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';

export 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;
export 'package:firebase_analytics/firebase_analytics.dart'
    show FirebaseAnalytics, FirebaseAnalyticsObserver;
export 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, User;
export 'package:firebase_crashlytics/firebase_crashlytics.dart'
    show FirebaseCrashlytics;
export 'package:firebase_storage/firebase_storage.dart' show FirebaseStorage;

abstract class FirebaseServices {
  static final auth = FirebaseAuth.instance;
  static final firestore = FirebaseFirestore.instance;
  static final storage = FirebaseStorage.instance;
  static final crashlytics = FirebaseCrashlytics.instance;
  static final analytics = FirebaseAnalytics.instance;
}
