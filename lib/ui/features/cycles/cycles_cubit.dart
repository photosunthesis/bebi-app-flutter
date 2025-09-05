import 'dart:async';

import 'package:bebi_app/data/models/async_value.dart';
import 'package:bebi_app/data/models/cycle_day_insights.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/data/repositories/cycle_logs_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/data/services/cycle_day_insights_service.dart';
import 'package:bebi_app/data/services/cycle_predictions_service.dart';
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
    with GuardMixin, AnalyticsMixin, LocalizationsMixin {
  CyclesCubit(
    this._cycleLogsRepository,
    this._cyclePredictionsService,
    this._cycleDayInsightsService,
    this._userProfileRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
  ) : super(CyclesState(focusedDate: DateTime.now()));

  final CycleLogsRepository _cycleLogsRepository;
  final CyclePredictionsService _cyclePredictionsService;
  final CycleDayInsightsService _cycleDayInsightsService;
  final UserProfileRepository _userProfileRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;

  Future<void> initialize({bool useCache = true}) async {
    await _loadProfiles(useCache);
    await _loadDataForActiveProfile(useCache: useCache);
  }

  Future<void> _loadProfiles(bool useCache) async {
    await guard(
      () async {
        emit(
          state.copyWith(
            userProfile: const AsyncLoading(),
            partnerProfile: const AsyncLoading(),
          ),
        );

        final currentUser = _firebaseAuth.currentUser!;
        final userProfile = await _userProfileRepository.getByUserId(
          currentUser.uid,
          useCache: useCache,
        );

        var finalUserProfile = userProfile;
        if (!userProfile!.didSetUpCycles) {
          finalUserProfile = userProfile.copyWith(
            hasCycle: false,
            didSetUpCycles: true,
          );
          await _userProfileRepository.createOrUpdate(finalUserProfile);
          setUserProperty(name: 'has_cycle', value: 'false');
        }

        final partnership = await _userPartnershipsRepository.getByUserId(
          currentUser.uid,
          useCache: useCache,
        );

        final partnerId = partnership?.users.firstWhere(
          (userId) => userId != currentUser.uid,
          orElse: () => '',
        );

        UserProfile? partnerProfile;
        if (partnerId != null && partnerId.isNotEmpty) {
          partnerProfile = await _userProfileRepository.getByUserId(
            partnerId,
            useCache: useCache,
          );
        }

        emit(
          state.copyWith(
            userProfile: AsyncData(finalUserProfile),
            partnerProfile: AsyncData(partnerProfile),
          ),
        );
      },
      onError: (error, _) => emit(
        state.copyWith(
          userProfile: AsyncError(error),
          partnerProfile: AsyncError(error),
        ),
      ),
    );
  }

  Future<void> setFocusedDate(DateTime date) async {
    await guard(
      () async {
        if (state.focusedDate.isSameDay(date)) return;

        emit(state.copyWith(insights: const AsyncLoading(), focusedDate: date));

        final cycleLogs = state.cycleLogs.map(
          orElse: () => <CycleLog>[],
          data: (value) => value,
        );

        final insights = _cycleDayInsightsService.getInsightsFromDateAndEvents(
          date,
          cycleLogs,
        );

        final aiSummary = await _cycleDayInsightsService.generateAiInsights(
          insights,
          isCurrentUser: state.isViewingCurrentUser,
          locale: l10n.localeName,
        );

        emit(
          state.copyWith(
            insights: AsyncData(insights),
            aiSummary: AsyncData(aiSummary),
          ),
        );
      },
      onError: (error, _) => emit(state.copyWith(insights: AsyncError(error))),
    );
  }

  Future<void> switchUserProfile() async {
    await guard(
      () async {
        final partnerProfile = state.partnerProfile.map(
          data: (d) => d,
          orElse: () => null,
        );

        if (partnerProfile?.isSharingCycleWithPartner != true) {
          throw UnsupportedError(l10n.partnerCycleSharingNotEnabledError);
        }

        emit(
          state.copyWith(
            cycleLogs: const AsyncLoading(),
            isViewingCurrentUser: !state.isViewingCurrentUser,
          ),
        );

        await _loadDataForActiveProfile(useCache: true);

        final userProfile = state.userProfile.map(
          data: (d) => d,
          orElse: () => null,
        );

        logEvent(
          name: 'user_profile_switched',
          parameters: {
            'user_id': userProfile!.userId,
            'partner_id': partnerProfile!.userId,
            'viewing': state.isViewingCurrentUser ? 'current_user' : 'partner',
          },
        );
      },
      logWhen: (error, _) => error is! UnsupportedError,
      onError: (error, _) => emit(state.copyWith(cycleLogs: AsyncError(error))),
    );
  }

  Future<void> _loadDataForActiveProfile({required bool useCache}) async {
    final cycleLogs = await _loadCycleData(useCache: useCache);
    if (cycleLogs != null) {
      final insights = await _loadInsights(cycleLogs: cycleLogs);
      if (insights != null) {
        await _loadAiSummary(insights: insights, useCache: useCache);
      }
    }
  }

  Future<List<CycleLog>?> _loadCycleData({required bool useCache}) async {
    return await guard(
      () async {
        emit(state.copyWith(cycleLogs: const AsyncLoading()));

        final activeProfileAsync = state.isViewingCurrentUser
            ? state.userProfile
            : state.partnerProfile;

        final activeProfile = activeProfileAsync.map(
          data: (d) => d,
          orElse: () => null,
        );

        if (activeProfile == null) {
          emit(state.copyWith(cycleLogs: const AsyncData([])));
          return [];
        }

        if (state.isViewingCurrentUser && (activeProfile.hasCycle != true)) {
          emit(state.copyWith(cycleLogs: const AsyncData([])));
          return [];
        }

        final cycleLogs = await _cycleLogsRepository.getCycleLogsByUserId(
          activeProfile.userId,
          useCache: useCache,
        );

        final predictions = _cyclePredictionsService.predictUpcomingCycles(
          cycleLogs,
          state.focusedDate,
        );

        final allLogs = [...cycleLogs, ...predictions];
        emit(state.copyWith(cycleLogs: AsyncData(allLogs)));
        return allLogs;
      },
      onError: (error, _) {
        emit(state.copyWith(cycleLogs: AsyncError(error)));
      },
    );
  }

  Future<CycleDayInsights?> _loadInsights({
    required List<CycleLog> cycleLogs,
  }) async {
    return await guard(
      () async {
        emit(state.copyWith(insights: const AsyncLoading()));
        final insights = _cycleDayInsightsService.getInsightsFromDateAndEvents(
          state.focusedDate,
          cycleLogs,
        );
        emit(state.copyWith(insights: AsyncData(insights)));
        return insights;
      },
      onError: (error, _) {
        emit(state.copyWith(insights: AsyncError(error)));
      },
    );
  }

  Future<void> _loadAiSummary({
    required CycleDayInsights? insights,
    required bool useCache,
  }) async {
    await guard(
      () async {
        emit(state.copyWith(aiSummary: const AsyncLoading()));
        final aiSummary = await _cycleDayInsightsService.generateAiInsights(
          insights!,
          isCurrentUser: state.isViewingCurrentUser,
          locale: l10n.localeName,
          useCache: useCache,
        );
        emit(state.copyWith(aiSummary: AsyncData(aiSummary)));
      },
      onError: (error, _) => emit(state.copyWith(aiSummary: AsyncError(error))),
    );
  }
}
