import 'dart:async';

import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/analytics_utils.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'add_partner_cubit.freezed.dart';
part 'add_partner_state.dart';

@injectable
class AddPartnerCubit extends Cubit<AddPartnerState> {
  AddPartnerCubit(
    this._userPartnershipsRepository,
    this._userProfileRepository,
    this._firebaseAuth,
  ) : super(const AddPartnerState(currentUserCode: ''));

  final UserPartnershipsRepository _userPartnershipsRepository;
  final UserProfileRepository _userProfileRepository;
  final FirebaseAuth _firebaseAuth;

  Future<void> initialize() async {
    await guard(
      () async {
        emit(state.copyWith(loading: true));
        final userProfile = await _userProfileRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
        );
        emit(state.copyWith(currentUserCode: userProfile!.code));

        logEvent(
          name: 'add_partner_screen_opened',
          parameters: {
            'user_id': _firebaseAuth.currentUser!.uid,
            'user_code': userProfile.code,
          },
        );
      },
      onError: (e, _) {
        emit(state.copyWith(error: e.toString()));
      },
      onComplete: () {
        emit(state.copyWith(loading: false));
      },
    );
  }

  Future<void> submit({String? partnerCode}) async {
    await guard(
      () async {
        emit(state.copyWith(loading: true));

        if (partnerCode?.isEmpty ?? true) {
          // Check if someone has already used current user's code to pair
          final existingPartnership = await _userPartnershipsRepository
              .getByUserId(_firebaseAuth.currentUser!.uid);

          if (existingPartnership == null) {
            throw ArgumentError(
              'You don\'t have a partner yet. Please enter their code or share yours with them.',
            );
          }

          return emit(state.copyWith(success: true));
        }

        final partnerProfile = await _userProfileRepository.getByUserCode(
          partnerCode!,
        );

        if (partnerProfile == null) {
          logEvent(
            name: 'partner_code_invalid',
            parameters: {
              'user_id': _firebaseAuth.currentUser!.uid,
              'attempted_code': partnerCode,
            },
          );
          throw ArgumentError('Partner code not found.');
        }

        await _userPartnershipsRepository.create(
          UserPartnership(
            id: '', // Firebase will generate this
            users: <String>[
              partnerProfile.userId,
              _firebaseAuth.currentUser!.uid,
            ],
            createdBy: _firebaseAuth.currentUser!.uid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        emit(state.copyWith(success: true));

        logEvent(
          name: 'partner_added_successfully',
          parameters: {
            'user_id': _firebaseAuth.currentUser!.uid,
            'partner_id': partnerProfile.userId,
            'connection_method': 'partner_code',
          },
        );

        setUserProperty(name: 'has_partner', value: 'true');
        setUserProperty(name: 'partner_id', value: partnerProfile.userId);
      },
      onError: (e, _) {
        emit(state.copyWith(error: e.toString()));
      },
      onComplete: () {
        emit(state.copyWith(loading: false, error: null));
      },
    );
  }
}
