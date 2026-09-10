import 'dart:async';

import 'package:bebi_app/features/account/domain/usecases/resolve_sharing_audience_usecase.dart';
import 'package:bebi_app/features/cycles/data/cycle_logs_repository.dart';
import 'package:bebi_app/features/cycles/domain/entities/cycle_log.dart';
import 'package:bebi_app/utils/mixins/analytics_mixin.dart';
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
    this._resolveSharingAudience,
    this._firebaseAuth,
  ) : super(const LogSymptomsLoadedState()) {
    logScreenViewed(screenName: 'log_symptoms_screen');
  }

  final CycleLogsRepository _cycleLogsRepository;
  final ResolveSharingAudienceUsecase _resolveSharingAudience;
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

        final audience = await _resolveSharingAudience.forLog(
          logForPartner: logForPartner,
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
              ownedBy: audience.ownedBy,
              users: audience.users,
            ),
          );
        }

        emit(const LogSymptomsSuccessState());

        logUserAction(
          action: symptoms.isEmpty ? 'symptoms_deleted' : 'symptoms_logged',
          parameters: {
            'symptoms_count': symptoms.length,
            'log_for_partner': logForPartner,
            'is_update': cycleLogId != null,
            'is_deletion': symptoms.isEmpty,
            'is_sharing_with_partner': audience.isSharingCycleWithPartner,
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
