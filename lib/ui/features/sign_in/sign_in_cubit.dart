import 'dart:async';

import 'package:bebi_app/utils/analytics_utils.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'sign_in_state.dart';
part 'sign_in_cubit.freezed.dart';

@injectable
class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._firebaseAuth) : super(const SignInInitial());

  final FirebaseAuth _firebaseAuth;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await guard(
      () async {
        emit(const SignInLoading());
        await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        emit(const SignInSuccess());

        logLogin(
          loginMethod: 'email',
          parameters: {
            'email': email,
            'user_id': _firebaseAuth.currentUser!.uid,
          },
        );
      },
      onError: (error, _) {
        final errorMessage = switch (error) {
          FirebaseAuthException(:final String? message) =>
            message ?? l10n.signInError,
          _ => l10n.unexpectedError,
        };

        emit(SignInFailure(errorMessage));

        logEvent(
          name: 'sign_in_failed',
          parameters: {
            'email': email,
            'error_type': error is FirebaseAuthException
                ? error.code
                : 'unknown',
            'login_method': 'email',
          },
        );
      },
    );
  }
}
