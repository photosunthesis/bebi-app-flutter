import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._userProfileRepository, this._analytics, this._firebaseAuth)
    : super(const HomeInitial());

  final UserProfileRepository _userProfileRepository;
  final FirebaseAnalytics _analytics;
  final FirebaseAuth _firebaseAuth;

  void initialize() {
    emit(const HomeLoading());
    _checkIfUserHasProfile();
  }

  Future<void> _checkIfUserHasProfile() async {
    final user = _firebaseAuth.currentUser!;
    final userHasNoProfile =
        await _userProfileRepository.getByUserId(user.uid) == null;

    if (userHasNoProfile) emit(const HomeShouldSetUpProfile());

    if (!kDebugMode) {
      _analytics.logEvent(
        name: 'user_redirected_to_profile_setup',
        parameters: {'userId': user.uid},
      );
    }
  }
}
