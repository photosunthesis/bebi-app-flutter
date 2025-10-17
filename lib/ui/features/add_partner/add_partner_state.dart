import 'package:bebi_app/config/firebase_providers.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

mixin class AddPartnerState {
  Future<String> fetchUserCode(WidgetRef ref) async {
    final firebaseAuth = ref.read(firebaseAuthProvider);
    final userProfileRepository = ref.read(userProfileRepositoryProvider);

    final userProfile = await userProfileRepository.getByUserId(
      firebaseAuth.currentUser!.uid,
    );

    if (userProfile == null) {
      throw ArgumentError('User profile not found.');
    }

    return userProfile.code;
  }
}
