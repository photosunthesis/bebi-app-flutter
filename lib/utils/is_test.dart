import 'dart:io';

import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:web/web.dart';

bool get kIsTest => Platform.environment.containsKey('FLUTTER_TEST');

bool get kIsPwa =>
    kIsWeb && window.matchMedia('(display-mode: standalone)').matches;

bool get kIsWebiOS =>
    kIsWeb && window.navigator.userAgent.contains(RegExp(r'iPad|iPod|iPhone'));
