import 'package:bebi_app/localizations/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

AppLocalizations get l10n {
  final context =
      GetIt.I<GoRouter>().routerDelegate.navigatorKey.currentState!.context;
  return AppLocalizations.of(context)!;
}

extension LocalizationsUtils on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
