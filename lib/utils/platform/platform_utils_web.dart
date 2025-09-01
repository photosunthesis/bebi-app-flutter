import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:web/web.dart';

bool get kIsAndroid => defaultTargetPlatform == TargetPlatform.android;

bool get kIsTest => false; // TODO I don't know how to make this work on web 🤠

bool get kIsPwa => window.matchMedia('(display-mode: standalone)').matches;

bool get kIsWebiOS =>
    window.navigator.userAgent.contains(RegExp(r'iPad|iPod|iPhone'));
