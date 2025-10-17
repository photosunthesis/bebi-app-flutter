import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/config/utility_packages_provider.dart';
import 'package:bebi_app/localizations/app_localizations.dart';

mixin LocalizationsMixin {
  AppLocalizations get l10n {
    final context = globalContainer
        .read(goRouterProvider)
        .routerDelegate
        .navigatorKey
        .currentState!
        .context;

    return AppLocalizations.of(context)!;
  }
}
