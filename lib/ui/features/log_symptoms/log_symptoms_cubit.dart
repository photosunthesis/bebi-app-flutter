import 'dart:async';

import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/repositories/cycle_logs_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'log_symptoms_cubit.freezed.dart';
part 'log_symptoms_state.dart';

@injectable
class LogSymptomsCubit extends Cubit<LogSymptomsState> {
  LogSymptomsCubit(
    this._cycleLogsRepository,
    this._userProfileRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
    this._firebaseAnalytics,
  ) : super(const LogSymptomsState.data());

  final CycleLogsRepository _cycleLogsRepository;
  final UserProfileRepository _userProfileRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;
  final FirebaseAnalytics _firebaseAnalytics;

  String? get _currentUserId => _firebaseAuth.currentUser?.uid;

  Future<void> logSymptoms({
    required DateTime date,
    required List<String> symptoms,
    required bool logForPartner,
  }) async {
    await guard(
      () async {
        emit(const LogSymptomsState.loading());

        final userProfile = await _userProfileRepository.getByUserId(
          _currentUserId!,
        );

        final partnership = await _userPartnershipsRepository.getByUserId(
          _currentUserId!,
        );

        final partnerProfile = await _userProfileRepository.getByUserId(
          partnership!.users.firstWhere((user) => user != _currentUserId!),
        );

        await _cycleLogsRepository.createOrUpdate(
          CycleLog.symptom(
            date: date,
            symptoms: symptoms,
            createdBy: _currentUserId!,
            ownedBy: logForPartner ? partnerProfile!.userId : _currentUserId!,
            users: userProfile!.isSharingCycleWithPartner == true
                ? partnership.users
                : [_currentUserId!],
          ),
        );

        emit(const LogSymptomsState.success());

        unawaited(
          _firebaseAnalytics.logEvent(
            name: 'log_symptoms',
            parameters: {
              'user_id': _currentUserId!,
              'date': date.toEEEEMMMMdyyyyhhmma(),
            },
          ),
        );
      },
      onError: (error, _) {
        emit(LogSymptomsState.error(error.toString()));
      },
      onComplete: () {
        emit(const LogSymptomsState.data());
      },
    );
  }
}
