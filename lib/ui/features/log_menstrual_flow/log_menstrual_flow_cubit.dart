import 'dart:async';

import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/repositories/cycle_logs_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'log_menstrual_flow_cubit.freezed.dart';
part 'log_menstrual_flow_state.dart';

@injectable
class LogMenstrualFlowCubit extends Cubit<LogMenstrualFlowState> {
  LogMenstrualFlowCubit(
    this._cycleLogsRepository,
    this._userProfileRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
    this._firebaseAnalytics,
  ) : super(const LogMenstrualFlowState.data());

  final CycleLogsRepository _cycleLogsRepository;
  final UserProfileRepository _userProfileRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;
  final FirebaseAnalytics _firebaseAnalytics;

  String? get _currentUserId => _firebaseAuth.currentUser?.uid;

  Future<void> logFlow({
    required DateTime date,
    required FlowIntensity flowIntensity,
    required bool logForPartner,
  }) async {
    await guard(
      () async {
        emit(const LogMenstrualFlowState.loading());

        final userProfile = await _userProfileRepository.getByUserId(
          _currentUserId!,
        );

        final partnership = await _userPartnershipsRepository.getByUserId(
          _currentUserId!,
        );

        final partnerProfile = await _userProfileRepository.getByUserId(
          partnership!.users.firstWhere((user) => user != _currentUserId!),
        );

        final cycleLog = CycleLog.period(
          date: date,
          flow: flowIntensity,
          createdBy: _currentUserId!,
          ownedBy: logForPartner ? partnerProfile!.userId : _currentUserId!,
          users: userProfile!.isSharingCycleWithPartner == true
              ? partnership.users
              : [_currentUserId!],
          isPrediction: false,
        );

        final previousLogs = await _cycleLogsRepository.getByUserIdAndDateRange(
          userId: _currentUserId!,
          start: date.subtract(1.days),
          end: date.add(1.days),
        );

        if (previousLogs.isEmpty) {
          // Auto-log the next few days of menstrual flow to reduce daily manual entries
          final cycleLogs = List.generate(
            5, // TODO Make this dynamic
            (i) => cycleLog.copyWith(date: date.add(i.days)),
          );

          await _cycleLogsRepository.createMany(cycleLogs);
        } else {
          await _cycleLogsRepository.createOrUpdate(cycleLog);
        }

        emit(const LogMenstrualFlowState.success());

        unawaited(
          _firebaseAnalytics.logEvent(
            name: 'log_menstrual_cycle',
            parameters: {
              'user_id': _currentUserId!,
              'date': date.toEEEEMMMMdyyyyhhmma(),
              'flow_intensity': flowIntensity.name,
            },
          ),
        );
      },
      onError: (error, _) {
        emit(LogMenstrualFlowState.error(error.toString()));
      },
      onComplete: () {
        emit(const LogMenstrualFlowState.data());
      },
    );
  }
}
