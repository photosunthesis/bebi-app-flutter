part of 'app_router.dart';

/// Defines the route names for the application.
///
/// These constants should be used with `GoRouter.goNamed` or similar methods
/// that use named routes. Actual routes are defined in the `AppRouter` class.
abstract class AppRoutes {
  static const home = 'home';
  static const signIn = 'sign-in';
  static const confirmEmail = 'confirm-email';
  static const profileSetup = 'profile-setup';
  static const relationshipOnboarding = 'relationship-onboarding';
  static const relationshipSetup = 'relationship-setup';
  static const stories = 'stories';
  static const calendar = 'calendar';
  static const createCalendarEvent = 'create-calendar-event';
  static const updateCalendarEvent = 'update-calendar-event';
  static const viewCalendarEvent = 'view-calendar-event';
  static const cycles = 'cycles';
  static const cycleCalendar = 'cycle-calendar';
  static const logMenstrualCycle = 'log-menstrual-cycle';
  static const logSymptoms = 'log-symptoms';
  static const logIntimacy = 'log-intimacy';
  static const cyclesSetup = 'cycles-setup';
  static const location = 'location';
  static const addPartner = 'add-partner';
  static const updatePassword = 'update-password';
}
