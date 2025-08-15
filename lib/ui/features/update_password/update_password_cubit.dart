import 'package:bebi_app/utils/analytics_utils.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'update_password_cubit.freezed.dart';
part 'update_password_state.dart';

@injectable
class UpdatePasswordCubit extends Cubit<UpdatePasswordState> {
  UpdatePasswordCubit(this._firebaseAuth)
    : super(const UpdatePasswordState.data());

  final FirebaseAuth _firebaseAuth;

  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async => guard(
    () async {
      emit(const UpdatePasswordState.loading());
      final user = _firebaseAuth.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      emit(const UpdatePasswordState.success());

      logEvent(
        name: 'update_password',
        parameters: {
          'user_id': _firebaseAuth.currentUser!.uid,
          'email': _firebaseAuth.currentUser!.email!,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    },
    onError: (error, _) {
      emit(
        UpdatePasswordState.error(
          error is FirebaseAuthException && error.code == 'wrong-password'
              ? l10n.incorrectCurrentPassword
              : error.toString(),
        ),
      );
    },
  );
}
