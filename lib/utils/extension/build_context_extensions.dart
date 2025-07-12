import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;

  TextTheme get primaryTextTheme => Theme.of(this).primaryTextTheme;

  ThemeData get theme => Theme.of(this);
}
