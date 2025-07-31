import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_state.dart';
part 'home_cubit.freezed.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
    this._userProfileRepository,
    this._userPartnershipsRepository,
    this._analytics,
    this._firebaseAuth,
  ) : super(const HomeInitial());

  final UserProfileRepository _userProfileRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAnalytics _analytics;
  final FirebaseAuth _firebaseAuth;

  Future<void> initialize() async {
    await guard(
      () async {
        emit(const HomeLoading());

        final userProfile = await _userProfileRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
        );

        if (userProfile == null) {
          emit(const HomeShouldSetUpProfile());
          if (!kDebugMode) {
            _analytics.logEvent(
              name: 'user_redirected_to_profile_setup',
              parameters: <String, Object>{'userId': _firebaseAuth.currentUser!.uid},
            );
          }
          return;
        }

        final userPartnership = await _userPartnershipsRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
        );

        if (userPartnership == null) {
          emit(const HomeShouldAddPartner());
          return;
        }

        emit(HomeLoaded(currentUser: userProfile));
      },
      onError: (error, _) {
        emit(HomeError(error.toString()));
      },
    );
  }
}
