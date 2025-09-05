import 'package:bebi_app/utils/mixins/analytics_mixin.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'update_password_state.dart';

@injectable
class UpdatePasswordCubit extends Cubit<UpdatePasswordState>
    with GuardMixin, AnalyticsMixin, LocalizationsMixin {
  UpdatePasswordCubit(this._firebaseAuth)
    : super(const UpdatePasswordLoadedState());

  final FirebaseAuth _firebaseAuth;

  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async => guard(
    () async {
      emit(const UpdatePasswordLoadingState());
      final user = _firebaseAuth.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      emit(const UpdatePasswordSuccessState());

      logEvent(name: 'password_updated');
    },
    onError: (error, _) {
      emit(
        UpdatePasswordErrorState(
          error is FirebaseAuthException && error.code == 'wrong-password'
              ? l10n.incorrectCurrentPassword
              : error.toString(),
        ),
      );
    },
  );
}
