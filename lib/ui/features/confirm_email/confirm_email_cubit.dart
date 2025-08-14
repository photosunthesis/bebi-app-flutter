import 'dart:async';

import 'package:bebi_app/utils/analytics_utils.dart';
import 'package:bebi_app/utils/exceptions/simple_exception.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'confirm_email_cubit.freezed.dart';
part 'confirm_email_state.dart';

@injectable
class ConfirmEmailCubit extends Cubit<ConfirmEmailState> {
  ConfirmEmailCubit(this._firebaseAuth)
    : super(const ConfirmEmailState.loading());

  final FirebaseAuth _firebaseAuth;

  bool _canResendVerification = true;
  Timer? _resendTimer;

  Future<void> initialize() async {
    await guard(
      () async {
        emit(ConfirmEmailState.data(_firebaseAuth.currentUser!.email!));

        await sendVerificationEmail();

        Timer.periodic(5.seconds, (timer) async {
          await _firebaseAuth.currentUser?.reload();
          if (_firebaseAuth.currentUser?.emailVerified == true) {
            timer.cancel();
            emit(const ConfirmEmailState.success());
            logEvent(
              name: 'email_verified',
              parameters: {
                'user_id': _firebaseAuth.currentUser!.uid,
                'email': _firebaseAuth.currentUser!.email!,
                'timestamp': DateTime.now().toIso8601String(),
                'success': true,
              },
            );
          }
        });
      },
      onError: (error, stackTrace) {
        emit(ConfirmEmailState.error(error.toString()));
      },
    );
  }

  Future<void> sendVerificationEmail() async {
    await guard(
      () async {
        if (!_canResendVerification) {
          throw SimpleException(l10n.resendEmailError);
        }

        _canResendVerification = false;
        _resendTimer?.cancel();

        await _firebaseAuth.currentUser?.sendEmailVerification();

        emit(ConfirmEmailState.data(_firebaseAuth.currentUser!.email!));

        _resendTimer = Timer(3.minutes, () {
          _canResendVerification = true;
        });

        logEvent(
          name: 'verification_email_sent',
          parameters: {
            'user_id': _firebaseAuth.currentUser!.uid,
            'email': _firebaseAuth.currentUser!.email!,
            'timestamp': DateTime.now().toIso8601String(),
            'success': true,
          },
        );
      },
      logWhen: (error) => error is! SimpleException,
      onError: (error, stackTrace) {
        emit(ConfirmEmailState.error(error.toString()));
      },
    );
  }

  @override
  Future<void> close() async {
    _resendTimer?.cancel();
    return super.close();
  }
}
