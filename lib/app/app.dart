import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/app/theme/app_theme.dart';
import 'package:bebi_app/config/firebase_services.dart';
import 'package:bebi_app/constants/hive_constants.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/data/repositories/calendar_events_repository.dart';
import 'package:bebi_app/data/repositories/cycle_logs_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_preferences_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/data/services/cycle_predictions_service.dart';
import 'package:bebi_app/data/services/recurring_calendar_events_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility_temp_fork/flutter_keyboard_visibility_temp_fork.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
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
        RepositoryProvider(create: (_) => ImagePicker()),

        // Hive boxes (local storage)
        RepositoryProvider(
          create: (_) => Hive.box<CalendarEvent>(HiveBoxNames.calendarEvent),
        ),
        RepositoryProvider(
          create: (_) => Hive.box<UserProfile>(HiveBoxNames.userProfile),
        ),
        RepositoryProvider(
          create: (_) =>
              Hive.box<UserPartnership>(HiveBoxNames.userPartnership),
        ),
        RepositoryProvider(
          create: (_) => Hive.box<CycleLog>(HiveBoxNames.cycleLog),
        ),
        RepositoryProvider(
          create: (_) => Hive.box<bool>(HiveBoxNames.userPreferences),
        ),

        // Services
        RepositoryProvider(create: (_) => RecurringCalendarEventsService()),
        RepositoryProvider(create: (_) => const CyclePredictionsService()),

        // Repositories
        RepositoryProvider(
          create: (context) => UserProfileRepository(
            context.read(),
            context.read(),
            context.read(),
          ),
        ),
        RepositoryProvider(
          create: (context) =>
              UserPartnershipsRepository(context.read(), context.read()),
        ),
        RepositoryProvider(
          lazy: false,
          create: (context) =>
              CalendarEventsRepository(context.read(), context.read())
                ..loadEventsFromServer(
                  context.read<FirebaseAuth>().currentUser?.uid,
                ),
        ),
        RepositoryProvider(
          lazy: false,
          create: (context) =>
              CycleLogsRepository(context.read(), context.read())
                ..loadCycleLogsFromServer(
                  context.read<FirebaseAuth>().currentUser?.uid,
                ),
        ),
        RepositoryProvider(
          create: (context) => UserPreferencesRepository(context.read()),
        ),
      ],
      child: MaterialApp.router(
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
          child: KeyboardDismissOnTap(
            dismissOnCapturedTaps: true,
            child: child!,
          ),
        ),
      ),
    );
  }
}
