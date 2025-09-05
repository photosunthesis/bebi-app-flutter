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
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'cycles_state.dart';

@injectable
class CyclesCubit extends Cubit<CyclesState>
    with AnalyticsMixin, LocalizationsMixin {
  CyclesCubit(
    this._cycleLogsRepository,
    this._cyclePredictionsService,
    this._cycleDayInsightsService,
    this._userProfileRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
  ) : super(CyclesState(focusedDate: DateTime.now())) {
    logScreenViewed(screenName: 'cycles_screen');
  }

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
    emit(
      state.copyWith(
        userProfile: const AsyncLoading(),
        partnerProfile: const AsyncLoading(),
      ),
    );

    final userProfile = await AsyncValue.guard(() async {
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
        logUserAction(
          action: 'skipped_cycle_setup',
          parameters: {'user_has_cycle': finalUserProfile.hasCycle},
        );
      }
    });

    emit(state.copyWith(userProfile: userProfile));

    final partnerProfile = await AsyncValue.guard(() async {
      final currentUser = _firebaseAuth.currentUser!;
      final partnership = await _userPartnershipsRepository.getByUserId(
        currentUser.uid,
        useCache: useCache,
      );

      final partnerId = partnership!.users.firstWhere(
        (userId) => userId != currentUser.uid,
        orElse: () => throw Exception(l10n.userProfileNotFoundError),
      );

      return await _userProfileRepository.getByUserId(
        partnerId,
        useCache: useCache,
      );
    });

    emit(state.copyWith(partnerProfile: partnerProfile));
  }

  Future<void> setFocusedDate(DateTime date) async {
    if (state.focusedDate.isSameDay(date)) return;

    emit(state.copyWith(insights: const AsyncLoading(), focusedDate: date));

    final cycleLogs = state.cycleLogs.map(
      orElse: () => <CycleLog>[],
      data: (value) => value,
    );

    final insightsAsyncValue = AsyncValue.guard(
      () => _cycleDayInsightsService.getInsightsFromDateAndEvents(
        date,
        cycleLogs,
      ),
    );

    final aiSummaryAsyncValue = AsyncValue.guard(
      () async => _cycleDayInsightsService.generateAiInsights(
        state.insights.asData()!,
        isCurrentUser: state.isViewingCurrentUser,
        locale: l10n.localeName,
      ),
    );

    emit(
      state.copyWith(
        insights: await insightsAsyncValue,
        aiSummary: await aiSummaryAsyncValue,
      ),
    );
  }

  Future<void> switchUserProfile() async {
    if (state.partnerProfile.asData()?.isSharingCycleWithPartner != true) {
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
    emit(state.copyWith(cycleLogs: const AsyncLoading()));

    emit(
      state.copyWith(
        cycleLogs: await AsyncValue.guard(() async {
          final activeProfile =
              (state.isViewingCurrentUser
                      ? state.userProfile
                      : state.partnerProfile)
                  .asData();

          if (activeProfile == null ||
              (state.isViewingCurrentUser && activeProfile.hasCycle != true)) {
            return <CycleLog>[];
          }

          final cycleLogs = await _cycleLogsRepository.getCycleLogsByUserId(
            activeProfile.userId,
            useCache: useCache,
          );

          final predictions = _cyclePredictionsService.predictUpcomingCycles(
            cycleLogs,
            state.focusedDate,
          );

          return [...cycleLogs, ...predictions];
        }),
      ),
    );

    if (state.cycleLogs is AsyncData<List<CycleLog>> &&
        state.cycleLogs.asData()!.isNotEmpty) {
      emit(
        state.copyWith(
          insights: await AsyncValue.guard(
            () async => _cycleDayInsightsService.getInsightsFromDateAndEvents(
              state.focusedDate,
              state.cycleLogs.asData()!,
            ),
          ),
        ),
      );
    }

    if (state.insights is AsyncData<CycleDayInsights?> &&
        state.insights.asData() != null) {
      emit(state.copyWith(aiSummary: const AsyncLoading()));

      emit(
        state.copyWith(
          aiSummary: await AsyncValue.guard(
            () async => _cycleDayInsightsService.generateAiInsights(
              state.insights.asData()!,
              isCurrentUser: state.isViewingCurrentUser,
              locale: l10n.localeName,
              useCache: useCache,
            ),
          ),
        ),
      );
    }

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
}
