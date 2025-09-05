import 'dart:async';

import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/repositories/cycle_logs_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:bebi_app/utils/mixins/analytics_mixin.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'log_menstrual_flow_state.dart';

@injectable
class LogMenstrualFlowCubit extends Cubit<LogMenstrualFlowState>
    with GuardMixin, AnalyticsMixin {
  LogMenstrualFlowCubit(
    this._cycleLogsRepository,
    this._userProfileRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
  ) : super(const LogMenstrualFlowLoadedState());

  final CycleLogsRepository _cycleLogsRepository;
  final UserProfileRepository _userProfileRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;

  String? get _currentUserId => _firebaseAuth.currentUser?.uid;

  Future<void> logFlow({
    String? cycleLogId,
    required int averagePeriodDurationInDays,
    required DateTime date,
    required FlowIntensity flowIntensity,
    required bool logForPartner,
  }) async {
    await guard(
      () async {
        emit(const LogMenstrualFlowLoadingState());

        final userProfile = await _userProfileRepository.getByUserId(
          _currentUserId!,
        );

        final partnership = await _userPartnershipsRepository.getByUserId(
          _currentUserId!,
        );

        final partnerProfile = await _userProfileRepository.getByUserId(
          partnership!.users.firstWhere((user) => user != _currentUserId!),
        );

        final users = logForPartner || userProfile!.isSharingCycleWithPartner
            ? partnership.users
            : [_currentUserId!];

        final cycleLog = CycleLog.period(
          id: cycleLogId ?? '',
          date: date,
          flow: flowIntensity,
          createdBy: _currentUserId!,
          ownedBy: logForPartner ? partnerProfile!.userId : _currentUserId!,
          users: users,
        );

        final previousLogs = await _cycleLogsRepository.getByUserIdAndDateRange(
          userId: _currentUserId!,
          start: date.subtract(1.days),
          end: date.add(1.days),
        );

        if (previousLogs.isEmpty || cycleLogId != null) {
          // Auto-log the next few days of menstrual flow to reduce daily manual entries
          final cycleLogs = List.generate(
            averagePeriodDurationInDays,
            (i) => cycleLog.copyWith(date: date.add(i.days)),
          );

          await _cycleLogsRepository.createMany(cycleLogs);
        } else {
          await _cycleLogsRepository.createOrUpdate(cycleLog);
        }

        emit(const LogMenstrualFlowSuccessState());

        logEvent(
          name: 'menstrual_flow_logged',
          parameters: {
            'flow_intensity': flowIntensity.name,
            'log_for_partner': logForPartner,
            'is_update': cycleLogId != null,
            'is_sharing_with_partner': userProfile!.isSharingCycleWithPartner,
            'auto_generated_days': previousLogs.isEmpty && cycleLogId == null
                ? averagePeriodDurationInDays
                : 1,
          },
        );
      },
      onError: (error, _) {
        emit(LogMenstrualFlowErrorState(error.toString()));
      },
    );
  }

  Future<void> delete(String cycleLogId) async {
    await guard(
      () async {
        emit(const LogMenstrualFlowLoadingState());
        await _cycleLogsRepository.deleteById(cycleLogId);
        emit(const LogMenstrualFlowSuccessState());
        logEvent(name: 'menstrual_flow_deleted');
      },
      onError: (error, _) {
        emit(LogMenstrualFlowErrorState(error.toString()));
      },
    );
  }
}
