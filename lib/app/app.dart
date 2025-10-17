// ignore_for_file: prefer_const_constructors

import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/app/theme/app_theme.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/localizations/app_localizations.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Bebi App',
      theme: ref.read(themeProvider),
      routerConfig: ref.read(goRouterProvider),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en', 'US'),
      builder: _buildAppWrapper,
    );
  }

  Widget _buildAppWrapper(BuildContext context, Widget? child) {
    final theme = context.theme;

    final mainWidget = AnnotatedRegion(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: theme.colorScheme.surface.withAlpha(1),
        systemNavigationBarDividerColor: theme.colorScheme.surface.withAlpha(1),
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: MediaQuery.withNoTextScaling(child: child!),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 480;

        if (isDesktop) {
          // TODO: Desktop support - currently wraps mobile layout in bordered container
          // with max width as temporary solution until full desktop UI is implemented
          return ColoredBox(
            color: theme.colorScheme.surface,
            child: Center(
              child: Container(
                margin: EdgeInsets.all(UiConstants.padding),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.colorScheme.outline,
                    width: UiConstants.borderWidth,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: mainWidget,
                  ),
                ),
              ),
            ),
          );
        }

        return mainWidget;
      },
    );
  }
}
