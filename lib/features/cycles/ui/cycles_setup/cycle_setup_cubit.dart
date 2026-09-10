import 'dart:async';

import 'package:bebi_app/features/account/data/user_profile_repository.dart';
import 'package:bebi_app/features/account/domain/resolve_sharing_audience_usecase.dart';
import 'package:bebi_app/features/cycles/data/cycle_logs_repository.dart';
import 'package:bebi_app/features/cycles/domain/cycle_log.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:bebi_app/utils/mixins/analytics_mixin.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'cycle_setup_state.dart';

@injectable
class CycleSetupCubit extends Cubit<CycleSetupState>
    with GuardMixin, AnalyticsMixin {
  CycleSetupCubit(
    this._userProfileRepository,
    this._cycleLogsRepository,
    this._resolveSharingAudience,
    this._firebaseAuth,
  ) : super(const CycleSetupInitialState()) {
    logScreenViewed(screenName: 'cycle_setup_screen');
  }

  final UserProfileRepository _userProfileRepository;
  final CycleLogsRepository _cycleLogsRepository;
  final ResolveSharingAudienceUsecase _resolveSharingAudience;
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

        final audience = await _resolveSharingAudience.forSelf(
          shareWithPartner: shouldShareWithPartner,
        );

        await _userProfileRepository.createOrUpdate(
          userProfile!.copyWith(
            didSetUpCycles: true,
            hasCycle: true,
            isSharingCycleWithPartner: shouldShareWithPartner,
          ),
        );

        final cycleLogs = List.generate(periodDurationInDays, (index) {
          final flow = index < 2 ? FlowIntensity.medium : FlowIntensity.light;
          return CycleLog.period(
            date: periodStartDate.add(index.days),
            flow: flow,
            createdBy: _firebaseAuth.currentUser!.uid,
            ownedBy: audience.ownedBy,
            users: audience.users,
          );
        });

        await _cycleLogsRepository.createMany(cycleLogs);

        emit(const CycleSetupSuccessState());

        logDataLoaded(
          dataType: 'cycle_logs',
          parameters: {
            'period_duration_in_days': periodDurationInDays,
            'shared_with_partner': shouldShareWithPartner,
          },
        );
      },
      onError: (error, _) => emit(CycleSetupErrorState(error.toString())),
      onComplete: () => emit(const CycleSetupInitialState()),
    );
  }
}
