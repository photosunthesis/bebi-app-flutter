import 'dart:math';

import 'package:bebi_app/data/models/partnership.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/data/repositories/partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
    this._userProfileRepository,
    this._partnershipsRepository,
    this._analytics,
    this._firebaseAuth,
  ) : super(const HomeInitial());

  final UserProfileRepository _userProfileRepository;
  final PartnershipsRepository _partnershipsRepository;
  final FirebaseAnalytics _analytics;
  final FirebaseAuth _firebaseAuth;

  Future<void> initialize() async {
    await guard(
      () async {
        emit(const HomeLoading());

        final futures = await Future.wait([
          _checkIfUserHasProfile(),
          _checkIfUserHasPartner(),
        ]);

        if (state is HomeLoading) {
          emit(
            HomeLoaded(
              currentUser: futures[0] as UserProfile,
              partnership: futures[1] as Partnership,
            ),
          );
        }
      },
      onError: (error, _) {
        emit(const HomeError('An error occured while fetching data.'));

        if (!kDebugMode) {
          _analytics.logEvent(
            name: 'home_initialization_error',
            parameters: {'error': error.toString()},
          );
        }
      },
    );
  }

  Future<UserProfile?> _checkIfUserHasProfile() async {
    final userProfile = await _userProfileRepository.getByUserId(
      _firebaseAuth.currentUser!.uid,
    );

    if (userProfile == null) {
      emit(const HomeShouldSetUpProfile());
      if (!kDebugMode) {
        _analytics.logEvent(
          name: 'user_redirected_to_profile_setup',
          parameters: {'userId': _firebaseAuth.currentUser!.uid},
        );
      }
    }

    return userProfile;
  }

  Future<Partnership> _checkIfUserHasPartner() async {
    final userId = _firebaseAuth.currentUser!.uid;
    var partnership = await _partnershipsRepository.getByUserId(
      _firebaseAuth.currentUser!.uid,
    );

    if (partnership == null) {
      final userProfile = await _userProfileRepository.getByUserId(userId);
      partnership = await _partnershipsRepository.create(
        Partnership(
          id: '', // Firebase will generate this
          code: await _generatePartnershipCode(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          users: [
            PartnershipUser(
              id: userId,
              displayName: userProfile!.displayName,
              photoUrl: userProfile.photoUrl,
            ),
          ],
        ),
      );
    }

    return partnership;
  }

  Future<String> _generatePartnershipCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();

    // Safety limit to prevent infinite loops
    for (int attempts = 0; attempts < 100; attempts++) {
      final code = List.generate(
        6,
        (_) => chars[rand.nextInt(chars.length)],
      ).join();

      if (await _partnershipsRepository.getByCode(code) == null) {
        return code;
      }
    }

    throw Exception('Failed to generate unique code after 100 attempts');
  }
}
