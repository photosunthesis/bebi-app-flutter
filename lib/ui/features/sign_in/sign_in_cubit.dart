import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._firebaseAuth, this._firebaseAnalytics)
    : super(const SignInInitial());

  final FirebaseAuth _firebaseAuth;
  final FirebaseAnalytics _firebaseAnalytics;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await guard(
      () async {
        emit(const SignInLoading());
        await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        emit(const SignInSuccess());
        if (!kDebugMode) {
          _firebaseAnalytics.logLogin(
            loginMethod: 'email',
            parameters: {'email': email},
          );
        }
      },
      onError: (error, _) {
        final errorMessage = switch (error) {
          FirebaseAuthException(:final message) =>
            message ?? 'There was an issue with the sign-in process.',
          _ => 'An unexpected error occurred. Please try again later.',
        };

        emit(SignInFailure(errorMessage));

        if (!kDebugMode) {
          _firebaseAnalytics.logEvent(
            name: 'sign_in_error',
            parameters: {'error': error.toString()},
          );
        }
      },
    );
  }
}
