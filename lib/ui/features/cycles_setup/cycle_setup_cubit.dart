import 'dart:async';

import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/repositories/cycle_logs_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/analytics_utils.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'cycle_setup_state.dart';

@injectable
class CycleSetupCubit extends Cubit<CycleSetupState> {
  CycleSetupCubit(
    this._userProfileRepository,
    this._cycleLogsRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
  ) : super(const CycleSetupInitialState());

  final UserProfileRepository _userProfileRepository;
  final CycleLogsRepository _cycleLogsRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;

  Future<void> setUpCycleTracking({
    required DateTime periodStartDate,
    required int periodDurationInDays,
    required bool shouldShareWithPartner,
  }) async {
    await guard(
      () async {
        emit(const CycleSetupLoadingState());

        final userProfile = await _userProfileRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
        );

        final partnership = await _userPartnershipsRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
        );

        await _userProfileRepository.createOrUpdate(
          userProfile!.copyWith(
            didSetUpCycles: true,
            hasCycle: true,
            isSharingCycleWithPartner: shouldShareWithPartner,
          ),
        );

        final cycleLogs = List.generate(periodDurationInDays, (index) {
          return CycleLog.period(
            id: '',
            date: periodStartDate.add(index.days),
            flow: FlowIntensity.light,
            createdBy: _firebaseAuth.currentUser!.uid,
            ownedBy: _firebaseAuth.currentUser!.uid,
            users: shouldShareWithPartner
                ? partnership!.users
                : [_firebaseAuth.currentUser!.uid],
            isPrediction: false,
          );
        });

        await _cycleLogsRepository.createMany(cycleLogs);

        emit(const CycleSetupSuccessState());

        logEvent(
          name: 'cycle_setup_completed',
          parameters: {
            'user_id': _firebaseAuth.currentUser!.uid,
            'period_duration_days': periodDurationInDays,
            'sharing_with_partner': shouldShareWithPartner,
          },
        );
      },
      onError: (error, _) => emit(CycleSetupErrorState(error.toString())),
      onComplete: () => emit(const CycleSetupInitialState()),
    );
  }
}
