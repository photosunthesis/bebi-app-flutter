import 'dart:async';

import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/mixins/analytics_mixin.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'add_partner_state.dart';

@injectable
class AddPartnerCubit extends Cubit<AddPartnerState>
    with GuardMixin, AnalyticsMixin, LocalizationsMixin {
  AddPartnerCubit(
    this._userPartnershipsRepository,
    this._userProfileRepository,
    this._firebaseAuth,
  ) : super(const AddPartnerLoadingState()) {
    logScreenViewed(screenName: 'add_partner_screen');
  }

  final UserPartnershipsRepository _userPartnershipsRepository;
  final UserProfileRepository _userProfileRepository;
  final FirebaseAuth _firebaseAuth;

  Future<void> initialize() async {
    await guard(
      () async {
        emit(const AddPartnerLoadingState());

        final userProfile = await _userProfileRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
        );

        emit(AddPartnerLoadedState(userProfile!.code));
      },
      onError: (e, _) {
        emit(AddPartnerErrorState(e.toString()));
      },
    );
  }

  Future<void> submit({String? partnerCode}) async {
    await guard(
      () async {
        emit(const AddPartnerLoadingState());

        final existingPartnership = await _userPartnershipsRepository
            .getByUserId(_firebaseAuth.currentUser!.uid);

        if (partnerCode?.isEmpty ?? true) {
          // Check if someone has already used current user's code to pair
          if (existingPartnership == null) {
            throw ArgumentError(l10n.partnerNotFoundForIntimateActivities);
          }

          logUserAction(
            action: 'partner_added',
            parameters: {'connection_method': 'existing_partnership'},
          );

          return emit(const AddPartnerSuccessState());
        }

        final partnerProfile = await _userProfileRepository.getByUserCode(
          partnerCode!,
        );

        if (partnerProfile == null) {
          throw ArgumentError(l10n.partnerCodeNotFound);
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

        emit(const AddPartnerSuccessState());

        logUserAction(
          action: 'partner_added',
          parameters: {
            'connection_method': 'partner_code',
            'has_existing_partnership': existingPartnership != null,
          },
        );
      },
      logWhen: (e, _) => e is! ArgumentError,
      onError: (e, _) {
        emit(AddPartnerErrorState(e.toString()));
      },
    );
  }
}
