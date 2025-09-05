import 'dart:async';

import 'package:bebi_app/utils/mixins/analytics_mixin.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'sign_in_state.dart';

@injectable
class SignInCubit extends Cubit<SignInState>
    with GuardMixin, AnalyticsMixin, LocalizationsMixin {
  SignInCubit(this._firebaseAuth) : super(const SignInLoadedState()) {
    logScreenViewed(screenName: 'sign_in_screen');
  }

  final FirebaseAuth _firebaseAuth;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await guard(
      () async {
        emit(const SignInLoadingState());
        await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        emit(const SignInSuccessState());

        logLogin(loginMethod: 'email');
      },
      logWhen: (error, _) => error is! FirebaseAuthException,
      onError: (error, _) {
        final errorMessage = switch (error) {
          FirebaseAuthException() when error.code == 'wrong-password' =>
            l10n.wrongPasswordError,
          FirebaseAuthException() when error.code == 'invalid-email' =>
            l10n.invalidEmailError,
          FirebaseAuthException() when error.code == 'user-not-found' =>
            l10n.userNotFoundError,
          _ => l10n.signInError,
        };
        emit(SignInErrorState(errorMessage));
      },
    );
  }
}
