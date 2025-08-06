import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/repositories/cycle_logs_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_preferences_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'cycle_setup_cubit.freezed.dart';
part 'cycle_setup_state.dart';

@Injectable()
class CycleSetupCubit extends Cubit<CycleSetupState> {
  CycleSetupCubit(
    this._userProfileRepository,
    this._cycleLogsRepository,
    this._userPartnershipsRepository,
    this._userPreferencesRepository,
    this._firebaseAuth,
  ) : super(const CycleSetupState.initial());

  final UserProfileRepository _userProfileRepository;
  final CycleLogsRepository _cycleLogsRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final UserPreferencesRepository _userPreferencesRepository;
  final FirebaseAuth _firebaseAuth;

  Future<void> setUpCycleTracking({
    required DateTime periodStartDate,
    required int periodDurationInDays,
    required bool shouldShareWithPartner,
  }) async {
    await guard(
      () async {
        emit(const CycleSetupState.loading());

        final userProfile = await _userProfileRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
        );

        final partnership = await _userPartnershipsRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
        );

        await _userProfileRepository.createOrUpdate(
          userProfile!.copyWith(
            hasCycle: true,
            isSharingCycleWithPartner: shouldShareWithPartner,
          ),
        );

        await _userPreferencesRepository.saveCycleSetupCompletion(
          isCompleted: true,
        );

        final cycleLogs = List.generate(periodDurationInDays, (index) {
          return CycleLog.period(
            id: '',
            date: periodStartDate.add(index.days),
            flow: FlowIntensity.light,
            createdBy: _firebaseAuth.currentUser!.uid,
            users: shouldShareWithPartner
                ? partnership!.users
                : [_firebaseAuth.currentUser!.uid],
            isPrediction: false,
          );
        });

        await _cycleLogsRepository.createMany(cycleLogs);

        emit(const CycleSetupState.success());
      },
      onError: (error, _) {
        emit(CycleSetupState.error(error.toString()));
      },
    );
  }
}
