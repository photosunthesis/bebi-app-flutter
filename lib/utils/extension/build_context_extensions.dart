import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension BuildContextExtensions on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;

  TextTheme get primaryTextTheme => Theme.of(this).primaryTextTheme;

  ThemeData get theme => Theme.of(this);

  String? get previousRoute {
    final matches = GoRouter.of(this)
        .routerDelegate
        .currentConfiguration
        .matches
        .map((e) => e.matchedLocation)
        .toList();
    if (matches.length == 1) return null;
    if (matches.length < 2) return matches.first;
    return matches[matches.length - 2];
  }
}
