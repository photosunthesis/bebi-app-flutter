import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility_temp_fork/flutter_keyboard_visibility_temp_fork.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bebi App',
      theme: AppTheme.instance,
      routerConfig: AppRouter.instance,
      debugShowCheckedModeBanner: false,
      builder: (_, child) => AnnotatedRegion(
        value: SystemUiOverlayStyle(
          systemNavigationBarColor: AppColors.stone50.withAlpha(1),
          systemNavigationBarDividerColor: AppColors.stone50.withAlpha(1),
          systemNavigationBarIconBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: KeyboardDismissOnTap(dismissOnCapturedTaps: true, child: child!),
      ),
    );
  }
}
