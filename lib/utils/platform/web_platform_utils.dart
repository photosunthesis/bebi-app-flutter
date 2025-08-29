// ignore: depend_on_referenced_packages
import 'package:web/web.dart';

bool get isPwa => window.matchMedia('(display-mode: standalone)').matches;

bool get isWebiOS =>
    window.navigator.userAgent.contains(RegExp(r'iPad|iPod|iPhone'));
