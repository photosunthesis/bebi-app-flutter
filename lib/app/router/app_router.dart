import 'package:bebi_app/config/firebase_providers.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/ui/features/add_partner/add_partner_screen.dart';
import 'package:bebi_app/ui/features/calendar/calendar_screen.dart';
import 'package:bebi_app/ui/features/calendar_event_details/calendar_event_details_screen.dart';
import 'package:bebi_app/ui/features/calendar_event_form/calendar_event_form_screen.dart';
import 'package:bebi_app/ui/features/confirm_email/confirm_email_screen.dart';
import 'package:bebi_app/ui/features/cycle_calendar/cycle_calendar_screen.dart';
import 'package:bebi_app/ui/features/cycles/cycles_screen.dart';
import 'package:bebi_app/ui/features/cycles_setup/cycles_setup_screen.dart';
import 'package:bebi_app/ui/features/home/home_screen.dart';
import 'package:bebi_app/ui/features/log_intimacy/log_intimacy_screen.dart';
import 'package:bebi_app/ui/features/log_menstrual_flow/log_menstrual_flow_screen.dart';
import 'package:bebi_app/ui/features/log_symptoms/log_symptoms_screen.dart';
import 'package:bebi_app/ui/features/profile_setup/profile_setup_screen.dart';
import 'package:bebi_app/ui/features/sign_in/sign_in_screen.dart';
import 'package:bebi_app/ui/features/stories/stories_screen.dart';
import 'package:bebi_app/ui/features/update_password/update_password_screen.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_scaffold.dart';
import 'package:bebi_app/ui/shared_widgets/modals/bottom_sheet_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
export 'package:go_router/go_router.dart';

part 'app_routes.dart';

final goRouterProvider = Provider((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/sign-in',
        name: AppRoutes.signIn,
        builder: (_, _) => const SignInScreen(),
      ),
      GoRoute(
        path: '/confirm-email',
        name: AppRoutes.confirmEmail,
        builder: (_, _) => const ConfirmEmailScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: AppRoutes.profileSetup,
        builder: (_, _) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/update-password',
        name: AppRoutes.updatePassword,
        builder: (_, _) => const UpdatePasswordScreen(),
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
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                name: AppRoutes.calendar,
                builder: (_, state) => CalendarScreen(routeState: state),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stories',
                name: AppRoutes.stories,
                builder: (_, _) => const StoriesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cycles',
                name: AppRoutes.cycles,
                builder: (_, _) => const CyclesScreen(),
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
        path: '/cycles/calendar',
        name: AppRoutes.cycleCalendar,
        pageBuilder: (_, state) => BottomSheetPage(
          child: CycleCalendarScreen(
            userId: state.uri.queryParameters['userId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/cycles/log-menstrual-cycle',
        name: AppRoutes.logMenstrualCycle,
        pageBuilder: (_, state) => BottomSheetPage(
          child: LogMenstrualFlowScreen(
            averagePeriodDurationInDays: int.parse(
              state.uri.queryParameters['averagePeriodDurationInDays']!,
            ),
            cycleLogId: state.uri.queryParameters['cycleLogId'],
            logForPartner: state.uri.queryParameters['logForPartner'] == 'true',
            date: DateTime.parse(state.uri.queryParameters['date']!),
            flowIntensity: state.uri.queryParameters['flowIntensity'] != null
                ? FlowIntensity.values.firstWhere(
                    (e) => e.name == state.uri.queryParameters['flowIntensity'],
                  )
                : null,
          ),
        ),
      ),
      GoRoute(
        path: '/cycles/log-symptoms',
        name: AppRoutes.logSymptoms,
        pageBuilder: (_, state) => BottomSheetPage(
          child: LogSymptomsScreen(
            cycleLogId: state.uri.queryParameters['cycleLogId'],
            date: DateTime.parse(state.uri.queryParameters['date']!),
            logForPartner: state.uri.queryParameters['logForPartner'] == 'true',
            symptoms: state.uri.queryParameters['symptoms']?.split(',') ?? [],
          ),
        ),
      ),
      GoRoute(
        path: '/cycles/log-intimacy',
        name: AppRoutes.logIntimacy,
        pageBuilder: (_, state) => BottomSheetPage(
          child: LogIntimacyScreen(
            cycleLogId: state.uri.queryParameters['cycleLogId'],
            date: DateTime.parse(state.uri.queryParameters['date']!),
            logForPartner: state.uri.queryParameters['logForPartner'] == 'true',
          ),
        ),
      ),
      GoRoute(
        path: '/calendar/create',
        name: AppRoutes.createCalendarEvent,
        builder: (_, state) => CalendarEventFormScreen(
          selectedDate: DateTime.tryParse(
            state.uri.queryParameters['selectedDate'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/calendar/:id',
        name: AppRoutes.viewCalendarEvent,
        builder: (_, state) => CalendarEventDetailsScreen(
          calendarEvent: state.extra as CalendarEvent,
        ),
      ),
      GoRoute(
        path: '/calendar/:id/edit',
        name: AppRoutes.updateCalendarEvent,
        pageBuilder: (_, state) => BottomSheetPage(
          child: CalendarEventFormScreen(
            calendarEvent: state.extra as CalendarEvent,
          ),
        ),
      ),
      GoRoute(
        path: '/cycles/setup',
        name: AppRoutes.cyclesSetup,
        builder: (_, _) => const CyclesSetupScreen(),
      ),
      GoRoute(
        path: '/add-partner',
        name: AppRoutes.addPartner,
        builder: (_, _) => const AddPartnerScreen(),
      ),
    ],
    observers: [if (kDebugMode) _DebugNavigatorObserver()],
    redirect: (context, state) {
      final signedIn = ref.read(firebaseAuthProvider).currentUser != null;
      final route = state.uri.toString();
      if (!signedIn && route != '/sign-in') return '/sign-in';
      if (signedIn && route == '/sign-in') return '/';
      return null;
    },
  );
});

class _DebugNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Route pushed: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Route popped: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint(
      'Route replaced: ${oldRoute?.settings.name} -> ${newRoute?.settings.name}',
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Route removed: ${route.settings.name}');
  }
}
