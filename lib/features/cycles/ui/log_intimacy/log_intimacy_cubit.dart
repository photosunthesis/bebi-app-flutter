import 'dart:async';

import 'package:bebi_app/features/account/domain/resolve_sharing_audience_usecase.dart';
import 'package:bebi_app/features/cycles/data/cycle_logs_repository.dart';
import 'package:bebi_app/features/cycles/domain/cycle_log.dart';
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
    this._resolveSharingAudience,
    this._firebaseAuth,
  ) : super(const LogIntimmacyLoadedState()) {
    logScreenViewed(screenName: 'log_intimacy_screen');
  }

  final CycleLogsRepository _cycleLogsRepository;
  final ResolveSharingAudienceUsecase _resolveSharingAudience;
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

        final audience = await _resolveSharingAudience.forLog(
          logForPartner: logForPartner,
        );

        await _cycleLogsRepository.createOrUpdate(
          CycleLog.intimacy(
            id: cycleLogId ?? '',
            date: date,
            intimacyType: intimacyType,
            createdBy: _currentUserId,
            ownedBy: audience.ownedBy,
            users: audience.users,
          ),
        );

        emit(const LogIntimacySuccessState());

        logUserAction(
          action: 'intimacy_logged',
          parameters: {
            'intimacy_type': intimacyType.name,
            'log_for_partner': logForPartner,
            'is_update': cycleLogId != null,
            'is_sharing_with_partner': audience.isSharingCycleWithPartner,
          },
        );
      },
      onError: (error, _) {
        emit(LogIntimacyErrorState(error.toString()));
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
    );
  }
}
