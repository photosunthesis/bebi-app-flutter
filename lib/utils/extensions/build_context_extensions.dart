import 'package:bebi_app/localizations/app_localizations.dart';
import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;

  TextTheme get primaryTextTheme => Theme.of(this).primaryTextTheme;

  ThemeData get theme => Theme.of(this);

  double get screenHeight => MediaQuery.of(this).size.height;

  double get screenWidth => MediaQuery.of(this).size.width;

  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
