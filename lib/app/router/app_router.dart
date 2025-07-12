import 'package:bebi_app/config/firebase_services.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/ui/features/home/home_cubit.dart';
import 'package:bebi_app/ui/features/home/home_screen.dart';
import 'package:bebi_app/ui/features/profile_setup/profile_setup_cubit.dart';
import 'package:bebi_app/ui/features/profile_setup/profile_setup_screen.dart';
import 'package:bebi_app/ui/features/sign_in/sign_in_cubit.dart';
import 'package:bebi_app/ui/features/sign_in/sign_in_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

part 'app_routes.dart';

abstract class AppRouter {
  static final GoRouter instance = GoRouter(
    routes: [
      GoRoute(
        path: '/sign-in',
        name: AppRoutes.signIn,
        builder: (context, state) => BlocProvider(
          create: (context) => SignInCubit(
            context.read<FirebaseAuth>(),
            context.read<FirebaseAnalytics>(),
          ),
          child: const SignInScreen(),
        ),
      ),
      GoRoute(
        path: '/profile-setup',
        name: AppRoutes.profileSetup,
        builder: (context, state) => BlocProvider(
          create: (context) => ProfileSetupCubit(
            context.read<UserProfileRepository>(),
            context.read<FirebaseAuth>(),
            context.read<ImagePicker>(),
          ),
          child: const ProfileSetupScreen(),
        ),
      ),
      GoRoute(
        path: '/',
        name: AppRoutes.home,
        builder: (context, state) => BlocProvider(
          create: (context) => HomeCubit(
            context.read<UserProfileRepository>(),
            context.read<FirebaseAnalytics>(),
            context.read<FirebaseAuth>(),
          ),
          child: const HomeScreen(),
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
