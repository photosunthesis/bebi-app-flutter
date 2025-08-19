import 'dart:async';

import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/repositories/cycle_logs_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/mixins/analytics_mixin.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'log_intimacy_state.dart';

@injectable
class LogIntimacyCubit extends Cubit<LogIntimacyState>
    with GuardMixin, AnalyticsMixin {
  LogIntimacyCubit(
    this._cycleLogsRepository,
    this._userProfileRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
  ) : super(const LogIntimmacyLoadedState());

  final CycleLogsRepository _cycleLogsRepository;
  final UserProfileRepository _userProfileRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;

  String get _currentUserId => _firebaseAuth.currentUser!.uid;

  Future<void> logIntimacy({
    String? cycleLogId,
    required DateTime date,
    required IntimacyType intimacyType,
    required bool logForPartner,
  }) async {
    await guard(
      () async {
        emit(const LogIntimacyLoadingState());

        final userProfile = await _userProfileRepository.getByUserId(
          _currentUserId,
        );

        final partnership = await _userPartnershipsRepository.getByUserId(
          _currentUserId,
        );

        final partnerProfile = await _userProfileRepository.getByUserId(
          partnership!.users.firstWhere((user) => user != _currentUserId),
        );

        await _cycleLogsRepository.createOrUpdate(
          CycleLog.intimacy(
            id: cycleLogId ?? '',
            date: date,
            intimacyType: intimacyType,
            createdBy: _currentUserId,
            ownedBy: logForPartner ? partnerProfile!.userId : _currentUserId,
            users: userProfile!.isSharingCycleWithPartner == true
                ? partnership.users
                : [_currentUserId],
          ),
        );

        emit(const LogIntimacySuccessState());

        logEvent(
          name: 'intimacy_logged',
          parameters: {
            'user_id': _currentUserId,
            'event_date': date.toIso8601String(),
            'intimacy_type': intimacyType.name,
            'log_for_partner': logForPartner,
            'is_update': cycleLogId != null,
          },
        );
      },
      onError: (error, _) {
        emit(LogIntimacyErrorState(error.toString()));
      },
      onComplete: () {
        emit(const LogIntimmacyLoadedState());
      },
    );
  }

  Future<void> delete(String cycleLogId) async {
    await guard(
      () async {
        emit(const LogIntimacyLoadingState());

        await _cycleLogsRepository.deleteById(cycleLogId);

        emit(const LogIntimacySuccessState());
      },
      onError: (error, _) {
        emit(LogIntimacyErrorState(error.toString()));
      },
      onComplete: () {
        emit(const LogIntimmacyLoadedState());
      },
    );
  }
}
