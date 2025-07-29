import 'package:bebi_app/config/firebase_services.dart';
import 'package:bebi_app/ui/features/add_partner/add_partner_cubit.dart';
import 'package:bebi_app/ui/features/add_partner/add_partner_screen.dart';
import 'package:bebi_app/ui/features/calendar/calendar_cubit.dart';
import 'package:bebi_app/ui/features/calendar/calendar_screen.dart';
import 'package:bebi_app/ui/features/calendar_event_form/calendar_event_form_bottom_sheet.dart';
import 'package:bebi_app/ui/features/calendar_event_form/calendar_event_form_cubit.dart';
import 'package:bebi_app/ui/features/home/home_cubit.dart';
import 'package:bebi_app/ui/features/home/home_screen.dart';
import 'package:bebi_app/ui/features/profile_setup/profile_setup_cubit.dart';
import 'package:bebi_app/ui/features/profile_setup/profile_setup_screen.dart';
import 'package:bebi_app/ui/features/sign_in/sign_in_cubit.dart';
import 'package:bebi_app/ui/features/sign_in/sign_in_screen.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_scaffold.dart';
import 'package:bebi_app/ui/shared_widgets/modals/bottom_sheet_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'app_routes.dart';

abstract class AppRouter {
  static final GoRouter instance = GoRouter(
    routes: [
      GoRoute(
        path: '/sign-in',
        name: AppRoutes.signIn,
        builder: (context, state) => BlocProvider(
          create: (context) => SignInCubit(context.read(), context.read()),
          child: const SignInScreen(),
        ),
      ),
      GoRoute(
        path: '/profile-setup',
        name: AppRoutes.profileSetup,
        builder: (context, state) => BlocProvider(
          create: (context) =>
              ProfileSetupCubit(context.read(), context.read(), context.read()),
          child: const ProfileSetupScreen(),
        ),
      ),
      StatefulShellRoute(
        builder: (context, state, shell) => shell,
        navigatorContainerBuilder: (context, navigationShell, children) =>
            MainScaffold(navigationShell: navigationShell, children: children),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: AppRoutes.home,
                builder: (context, state) => BlocProvider(
                  create: (context) => HomeCubit(
                    context.read(),
                    context.read(),
                    context.read(),
                    context.read(),
                  ),
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
                builder: (context, state) => BlocProvider(
                  create: (context) => CalendarCubit(),
                  child: const CalendarScreen(),
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
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Stories Screen'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                // TODO
                path: '/account',
                name: AppRoutes.account,
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Account Screen'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                // TODO
                path: '/location',
                name: AppRoutes.location,
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Location Screen')),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/calendar/create-event',
        name: AppRoutes.createCalendarEvent,
        pageBuilder: (context, state) => BottomSheetPage(
          BlocProvider(
            create: (context) => CalendarEventFormCubit(
              context.read(),
              context.read(),
              context.read(),
              context.read(),
            ),
            child: CalendarEventFormBottomSheet(
              selectedDate: DateTime.tryParse(
                state.uri.queryParameters['selectedDate'] ?? '',
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/add-partner',
        name: AppRoutes.addPartner,
        builder: (context, state) => BlocProvider(
          create: (context) =>
              AddPartnerCubit(context.read(), context.read(), context.read()),
          child: const AddPartnerScreen(),
        ),
      ),
    ],
    observers: [
      if (!kDebugMode)
        FirebaseAnalyticsObserver(analytics: FirebaseServices.analytics),
    ],
    redirect: (context, state) {
      final signedIn = context.read<FirebaseAuth>().currentUser is User;
      final route = state.uri.toString();
      if (!signedIn && route != '/sign-in') return '/sign-in';
      if (signedIn && route == '/sign-in') return '/';
      return null;
    },
  );
}
