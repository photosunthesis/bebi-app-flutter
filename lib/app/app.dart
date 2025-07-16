import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/app/theme/app_theme.dart';
import 'package:bebi_app/config/firebase_services.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility_temp_fork/flutter_keyboard_visibility_temp_fork.dart';
import 'package:image_picker/image_picker.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // Firebase
        RepositoryProvider.value(value: FirebaseServices.auth),
        RepositoryProvider.value(value: FirebaseServices.firestore),
        RepositoryProvider.value(value: FirebaseServices.analytics),
        RepositoryProvider.value(value: FirebaseServices.storage),

        // Other services
        RepositoryProvider.value(value: ImagePicker()),

        // Repositories
        RepositoryProvider(
          create: (context) =>
              UserProfileRepository(context.read(), context.read()),
        ),
        RepositoryProvider(
          create: (context) => UserPartnershipsRepository(context.read()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Bebi App',
        theme: AppTheme.instance,
        routerConfig: AppRouter.instance,
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            KeyboardDismissOnTap(dismissOnCapturedTaps: true, child: child!),
      ),
    );
  }
}
