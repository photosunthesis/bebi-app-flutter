part of 'app_router.dart';

/// Defines the route names for the application.
///
/// These constants should be used with `GoRouter.goNamed` or similar methods
/// that use named routes. Actual routes are defined in the `AppRouter` class.
abstract class AppRoutes {
  static const home = 'home';
  static const signIn = 'sign-in';
  static const profileSetup = 'profile-setup';
}
