import 'dart:async';

import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/repositories/cycle_logs_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/mixins/analytics_utils.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'log_symptoms_state.dart';

@injectable
class LogSymptomsCubit extends Cubit<LogSymptomsState>
    with GuardMixin, AnalyticsMixin, LocalizationsMixin {
  LogSymptomsCubit(
    this._cycleLogsRepository,
    this._userProfileRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
  ) : super(const LogSymptomsLoadedState());

  final CycleLogsRepository _cycleLogsRepository;
  final UserProfileRepository _userProfileRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;

  String get _currentUserId => _firebaseAuth.currentUser!.uid;

  Future<void> logSymptoms({
    String? cycleLogId,
    required DateTime date,
    required List<String> symptoms,
    required bool logForPartner,
  }) async {
    await guard(
      () async {
        emit(const LogSymptomsLoadingState());

        if (cycleLogId == null && symptoms.isEmpty) {
          throw Exception(l10n.selectSymptomRequired);
        }

        final userProfile = await _userProfileRepository.getByUserId(
          _currentUserId,
        );

        final partnership = await _userPartnershipsRepository.getByUserId(
          _currentUserId,
        );

        final partnerProfile = await _userProfileRepository.getByUserId(
          partnership!.users.firstWhere((user) => user != _currentUserId),
        );

        if (symptoms.isEmpty) {
          await _cycleLogsRepository.deleteById(cycleLogId!);
        } else {
          await _cycleLogsRepository.createOrUpdate(
            CycleLog.symptom(
              id: cycleLogId ?? '',
              date: date,
              symptoms: symptoms,
              createdBy: _currentUserId,
              ownedBy: logForPartner ? partnerProfile!.userId : _currentUserId,
              users: userProfile!.isSharingCycleWithPartner == true
                  ? partnership.users
                  : [_currentUserId],
            ),
          );
        }

        emit(const LogSymptomsSuccessState());

        logEvent(
          name: symptoms.isEmpty ? 'symptoms_deleted' : 'symptoms_logged',
          parameters: {
            'user_id': _currentUserId,
            'event_date': date.toIso8601String(),
            'symptoms_count': symptoms.length,
            'symptoms': symptoms.join(','),
            'log_for_partner': logForPartner,
            'is_update': cycleLogId != null,
            'is_deletion': symptoms.isEmpty,
          },
        );
      },
      onError: (error, _) {
        emit(LogSymptomsErrorState(error.toString()));
      },
      onComplete: () {
        emit(const LogSymptomsLoadedState());
      },
    );
  }
}
