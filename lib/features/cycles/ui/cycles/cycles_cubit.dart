import 'dart:async';

import 'package:bebi_app/core/ui/async_value.dart';
import 'package:bebi_app/features/account/data/user_profile_repository.dart';
import 'package:bebi_app/features/account/domain/entities/couple_context.dart';
import 'package:bebi_app/features/account/domain/usecases/resolve_couple_context_usecase.dart';
import 'package:bebi_app/features/cycles/data/ai_insights_repository.dart';
import 'package:bebi_app/features/cycles/data/cycle_logs_repository.dart';
import 'package:bebi_app/features/cycles/domain/entities/cycle_day_insights.dart';
import 'package:bebi_app/features/cycles/domain/entities/cycle_log.dart';
import 'package:bebi_app/features/cycles/domain/entities/prediction_confidence.dart';
import 'package:bebi_app/features/cycles/domain/no_period_data_exception.dart';
import 'package:bebi_app/features/cycles/domain/usecases/derive_cycle_day_insights_usecase.dart';
import 'package:bebi_app/features/cycles/domain/usecases/predict_upcoming_cycles_usecase.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/mixins/analytics_mixin.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'cycles_state.dart';

@injectable
class CyclesCubit extends Cubit<CyclesState>
    with AnalyticsMixin, LocalizationsMixin, GuardMixin {
  CyclesCubit(
    this._cycleLogsRepository,
    this._predictUpcomingCycles,
    this._deriveCycleDayInsights,
    this._aiInsightsRepository,
    this._resolveCoupleContext,
    this._userProfileRepository,
    this._firebaseAuth,
  ) : super(CyclesState(focusedDate: DateTime.now())) {
    logScreenViewed(screenName: 'cycles_screen');
  }

  final CycleLogsRepository _cycleLogsRepository;
  final PredictUpcomingCyclesUsecase _predictUpcomingCycles;
  final DeriveCycleDayInsightsUsecase _deriveCycleDayInsights;
  final AiInsightsRepository _aiInsightsRepository;
  final ResolveCoupleContextUsecase _resolveCoupleContext;
  final UserProfileRepository _userProfileRepository;
  final FirebaseAuth _firebaseAuth;

  CoupleContext? _coupleContext;

  Future<void> initialize({bool useCache = true}) async {
    await _loadProfiles(useCache);
    await _loadDataForActiveProfile(useCache: useCache);
  }

  Future<void> _loadProfiles(bool useCache) async {
    await guard(() async {
      await _markCycleSetupSkipped(useCache);
      _coupleContext = await _resolveCoupleContext(useCache: useCache);
    });
  }

  /// Opening cycles without ever running setup counts as declining it, and that
  /// decision lives on the account profile.
  Future<void> _markCycleSetupSkipped(bool useCache) async {
    final userProfile = await _userProfileRepository.getByUserId(
      _firebaseAuth.currentUser!.uid,
      useCache: useCache,
    );

    if (userProfile!.didSetUpCycles) return;

    final updatedProfile = userProfile.copyWith(
      hasCycle: false,
      didSetUpCycles: true,
    );

    await _userProfileRepository.createOrUpdate(updatedProfile);

    logUserAction(
      action: 'skipped_cycle_setup',
      parameters: {'user_has_cycle': updatedProfile.hasCycle},
    );
  }

  Future<void> setFocusedDate(DateTime date) async {
    if (state.focusedDate.isSameDay(date)) return;

    if (state.isViewingCurrentUser && _coupleContext?.me.hasCycle != true) {
      return;
    }

    emit(state.copyWith(focusedDate: date));
    await _loadInsightsAndAiSummary(useCache: true);
  }

  Future<void> switchUserProfile() async {
    if (_coupleContext?.partner?.isSharingCycleWithPartner != true) {
      emit(
        state.copyWith(
          cycleLogs: AsyncError(
            UnsupportedError(l10n.partnerCycleSharingNotEnabledError),
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(isViewingCurrentUser: !state.isViewingCurrentUser));

    await _loadDataForActiveProfile(useCache: true);

    logUserAction(
      action: 'switched_cycle_profile_view',
      parameters: {
        'viewing': state.isViewingCurrentUser ? 'current_user' : 'partner',
      },
    );
  }

  Future<void> _loadDataForActiveProfile({required bool useCache}) async {
    await _loadCycleLogs(useCache: useCache);
    await _loadInsightsAndAiSummary(useCache: useCache);

    logDataLoaded(
      dataType: 'cycle_logs',
      parameters: {
        'cycle_log_owner': state.isViewingCurrentUser
            ? 'current_user'
            : 'partner',
        'cycle_logs_count': state.cycleLogs.asData()?.length ?? 0,
      },
    );
  }

  Future<void> _loadCycleLogs({required bool useCache}) async {
    emit(state.copyWith(cycleLogs: const AsyncLoading()));

    final cycleLogs = await AsyncValue.guard(() async {
      final activeMember = _getActiveMember();

      if (activeMember == null ||
          (state.isViewingCurrentUser && activeMember.hasCycle != true)) {
        return <CycleLog>[];
      }

      final cycleLogs = await _cycleLogsRepository.getCycleLogsByUserId(
        activeMember.userId,
        useCache: useCache,
      );

      try {
        final result = _predictUpcomingCycles(cycleLogs, state.focusedDate);

        emit(
          state.copyWith(predictionConfidence: AsyncData(result.confidence)),
        );

        return [...cycleLogs, ...result.predictions];
      } on NoPeriodDataException {
        throw ArgumentError(l10n.noPeriodDataError);
      }
    });

    emit(state.copyWith(cycleLogs: cycleLogs));
  }

  Future<void> _loadInsightsAndAiSummary({required bool useCache}) async {
    final cycleLogs = state.cycleLogs.asData();
    if (cycleLogs == null || cycleLogs.isEmpty) {
      return;
    }

    emit(state.copyWith(insights: const AsyncLoading()));

    final insights = await AsyncValue.guard(() {
      try {
        return _deriveCycleDayInsights(state.focusedDate, cycleLogs);
      } on NoPeriodDataException {
        throw ArgumentError(l10n.noPeriodDataError);
      }
    });

    emit(state.copyWith(insights: insights));

    final insightsData = insights.asData();
    if (insightsData != null) {
      emit(state.copyWith(aiSummary: const AsyncLoading()));

      final aiSummary = await AsyncValue.guard(
        () => _aiInsightsRepository.generate(
          insightsData,
          isCurrentUser: state.isViewingCurrentUser,
          locale: l10n.localeName,
          confidence: state.predictionConfidence.asData(),
          useCache: useCache,
        ),
      );

      emit(state.copyWith(aiSummary: aiSummary));
    }
  }

  CoupleMember? _getActiveMember() {
    return state.isViewingCurrentUser
        ? _coupleContext?.me
        : _coupleContext?.partner;
  }
}
