import 'dart:async';

import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/repositories/cycle_logs_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/analytics_utils.dart';
import 'package:bebi_app/utils/exceptions/simple_exception.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'log_intimacy_cubit.freezed.dart';
part 'log_intimacy_state.dart';

@injectable
class LogIntimacyCubit extends Cubit<LogIntimacyState> {
  LogIntimacyCubit(
    this._cycleLogsRepository,
    this._userProfileRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
  ) : super(const LogIntimacyState.data());

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
        emit(const LogIntimacyState.loading());

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

        emit(const LogIntimacyState.success());

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
      logWhen: (error) => error is! SimpleException,
      onError: (error, _) {
        emit(LogIntimacyState.error(error.toString()));
      },
      onComplete: () {
        emit(const LogIntimacyState.data());
      },
    );
  }

  Future<void> delete(String cycleLogId) async {
    await guard(
      () async {
        emit(const LogIntimacyState.loading());

        await _cycleLogsRepository.deleteById(cycleLogId);

        emit(const LogIntimacyState.success());
      },
      onError: (error, _) {
        emit(LogIntimacyState.error(error.toString()));
      },
      onComplete: () {
        emit(const LogIntimacyState.data());
      },
    );
  }
}
