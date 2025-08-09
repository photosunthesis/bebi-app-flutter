import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/ui/features/add_partner/add_partner_cubit.dart';
import 'package:bebi_app/ui/features/add_partner/add_partner_screen.dart';
import 'package:bebi_app/ui/features/calendar/calendar_cubit.dart';
import 'package:bebi_app/ui/features/calendar/calendar_screen.dart';
import 'package:bebi_app/ui/features/calendar_event_details/calendar_event_details_cubit.dart';
import 'package:bebi_app/ui/features/calendar_event_details/calendar_event_details_screen.dart';
import 'package:bebi_app/ui/features/calendar_event_form/calendar_event_form_cubit.dart';
import 'package:bebi_app/ui/features/calendar_event_form/calendar_event_form_screen.dart';
import 'package:bebi_app/ui/features/cycles/cycles_cubit.dart';
import 'package:bebi_app/ui/features/cycles/cycles_screen.dart';
import 'package:bebi_app/ui/features/cycles_setup/cycle_setup_cubit.dart';
import 'package:bebi_app/ui/features/cycles_setup/cycles_setup_screen.dart';
import 'package:bebi_app/ui/features/home/home_cubit.dart';
import 'package:bebi_app/ui/features/home/home_screen.dart';
import 'package:bebi_app/ui/features/profile_setup/profile_setup_cubit.dart';
import 'package:bebi_app/ui/features/profile_setup/profile_setup_screen.dart';
import 'package:bebi_app/ui/features/sign_in/sign_in_cubit.dart';
import 'package:bebi_app/ui/features/sign_in/sign_in_screen.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_scaffold.dart';
import 'package:bebi_app/ui/shared_widgets/modals/bottom_sheet_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

export 'package:go_router/go_router.dart' show GoRouterHelper;

part 'app_routes.dart';

@module
abstract class AppRouter {
  @singleton
  GoRouter get instance => GoRouter(
    routes: [
      GoRoute(
        path: '/sign-in',
        name: AppRoutes.signIn,
        builder: (_, _) => BlocProvider(
          create: (_) => GetIt.I<SignInCubit>(),
          child: const SignInScreen(),
        ),
      ),
      GoRoute(
        path: '/profile-setup',
        name: AppRoutes.profileSetup,
        builder: (_, _) => BlocProvider(
          create: (_) => GetIt.I<ProfileSetupCubit>(),
          child: const ProfileSetupScreen(),
        ),
      ),
      StatefulShellRoute(
        builder: (context, state, shell) => shell,
        navigatorContainerBuilder: (context, navigationShell, children) =>
            MainScaffold(navigationShell: navigationShell, children: children),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: AppRoutes.home,
                builder: (_, _) => BlocProvider(
                  create: (_) => GetIt.I<HomeCubit>(),
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                name: AppRoutes.calendar,
                builder: (_, state) => BlocProvider(
                  create: (_) => GetIt.I<CalendarCubit>(),
                  child: CalendarScreen(
                    shouldRefresh:
                        state.uri.queryParameters['refresh'] == 'true',
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                // TODO
                path: '/stories',
                name: AppRoutes.stories,
                builder: (_, _) =>
                    const Scaffold(body: Center(child: Text('Stories Screen'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cycles',
                name: AppRoutes.cycles,
                builder: (_, state) => BlocProvider(
                  create: (_) => GetIt.I<CyclesCubit>(),
                  child: CyclesScreen(
                    shouldReinitialize:
                        state.uri.queryParameters['reinitialize'] == 'true',
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                // TODO
                path: '/location',
                name: AppRoutes.location,
                builder: (_, _) => const Scaffold(
                  body: Center(child: Text('Location Screen')),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/calendar/create',
        name: AppRoutes.createCalendarEvent,
        pageBuilder: (_, state) => BottomSheetPage(
          BlocProvider(
            create: (_) => GetIt.I<CalendarEventFormCubit>(),
            child: CalendarEventFormScreen(
              selectedDate: DateTime.tryParse(
                state.uri.queryParameters['selectedDate'] ?? '',
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/calendar/:id',
        name: AppRoutes.viewCalendarEvent,
        builder: (_, state) => BlocProvider(
          create: (_) => GetIt.I<CalendarEventDetailsCubit>(),
          child: CalendarEventDetailsScreen(
            calendarEvent: state.extra as CalendarEvent,
          ),
        ),
      ),
      GoRoute(
        path: '/calendar/:id/edit',
        name: AppRoutes.updateCalendarEvent,
        pageBuilder: (_, state) => BottomSheetPage(
          BlocProvider(
            create: (_) => GetIt.I<CalendarEventFormCubit>(),
            child: CalendarEventFormScreen(
              calendarEvent: state.extra as CalendarEvent,
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/cycles/setup',
        name: AppRoutes.cyclesSetup,
        builder: (_, _) => BlocProvider(
          create: (_) => GetIt.I<CycleSetupCubit>(),
          child: const CyclesSetupScreen(),
        ),
      ),
      GoRoute(
        path: '/add-partner',
        name: AppRoutes.addPartner,
        builder: (_, _) => BlocProvider(
          create: (_) => GetIt.I<AddPartnerCubit>(),
          child: const AddPartnerScreen(),
        ),
      ),
    ],
    observers: <NavigatorObserver>[
      if (!kDebugMode) FirebaseAnalyticsObserver(analytics: GetIt.I()),
    ],
    redirect: (context, state) {
      final signedIn = GetIt.I<FirebaseAuth>().currentUser is User;
      final route = state.uri.toString();
      if (!signedIn && route != '/sign-in') return '/sign-in';
      if (signedIn && route == '/sign-in') return '/';
      return null;
    },
  );
}
