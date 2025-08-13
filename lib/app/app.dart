import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility_temp_fork/flutter_keyboard_visibility_temp_fork.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bebi App',
      theme: GetIt.I<ThemeData>(),
      routerConfig: GetIt.I<GoRouter>(),
      debugShowCheckedModeBanner: false,
      builder: (_, child) => AnnotatedRegion(
        value: SystemUiOverlayStyle(
          systemNavigationBarColor: AppColors.stone50.withAlpha(1),
          systemNavigationBarDividerColor: AppColors.stone50.withAlpha(1),
          systemNavigationBarIconBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: KeyboardDismissOnTap(
          dismissOnCapturedTaps: true,
          // TODO For accessibility, the app should allow text scaling. For now we
          // keep it like this, but this will be implemented in the future...
          // someday... maybe...
          child: MediaQuery.withNoTextScaling(child: child!),
        ),
      ),
    );
  }
}
