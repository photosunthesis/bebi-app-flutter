// ignore: depend_on_referenced_packages
import 'package:web/web.dart' as web;

bool get kIsTest => false; // TODO I don't know how to make this work on web 🤠

bool get kIsPwa => web.window.matchMedia('(display-mode: standalone)').matches;

bool get kIsWebiOS =>
    web.window.navigator.userAgent.contains(RegExp(r'iPad|iPod|iPhone'));
