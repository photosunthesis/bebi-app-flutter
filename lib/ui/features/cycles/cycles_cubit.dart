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
    with AnalyticsMixin, LocalizationsMixin, GuardMixin {
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

  UserProfile? _userProfile;
  UserProfile? _partnerProfile;

  Future<void> initialize({bool useCache = true}) async {
    await _loadProfiles(useCache);
    await _loadDataForActiveProfile(useCache: useCache);
  }

  Future<void> _loadProfiles(bool useCache) async {
    await guard(() async {
      final currentUser = _firebaseAuth.currentUser!;

      _userProfile = await _userProfileRepository.getByUserId(
        currentUser.uid,
        useCache: useCache,
      );

      if (!_userProfile!.didSetUpCycles) {
        _userProfile = _userProfile!.copyWith(
          hasCycle: false,
          didSetUpCycles: true,
        );

        await _userProfileRepository.createOrUpdate(_userProfile!);

        logUserAction(
          action: 'skipped_cycle_setup',
          parameters: {'user_has_cycle': _userProfile!.hasCycle},
        );
      }

      final partnership = await _userPartnershipsRepository.getByUserId(
        currentUser.uid,
        useCache: useCache,
      );

      final partnerId = partnership!.users.firstWhere(
        (userId) => userId != currentUser.uid,
        orElse: () => throw Exception(l10n.userProfileNotFoundError),
      );

      _partnerProfile = await _userProfileRepository.getByUserId(
        partnerId,
        useCache: useCache,
      );
    });
  }

  Future<void> setFocusedDate(DateTime date) async {
    if (state.focusedDate.isSameDay(date)) return;

    if (state.isViewingCurrentUser && _userProfile?.hasCycle != true) {
      return;
    }

    emit(state.copyWith(focusedDate: date));
    await _loadInsightsAndAiSummary(useCache: true);
  }

  Future<void> switchUserProfile() async {
    if (_partnerProfile?.isSharingCycleWithPartner != true) {
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
      final activeProfile = _getActiveProfile();

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
    });

    emit(state.copyWith(cycleLogs: cycleLogs));
  }

  Future<void> _loadInsightsAndAiSummary({required bool useCache}) async {
    final cycleLogs = state.cycleLogs.asData();
    if (cycleLogs == null || cycleLogs.isEmpty) {
      return;
    }

    emit(state.copyWith(insights: const AsyncLoading()));

    final insights = await AsyncValue.guard(
      () => _cycleDayInsightsService.getInsightsFromDateAndEvents(
        state.focusedDate,
        cycleLogs,
      ),
    );

    emit(state.copyWith(insights: insights));

    final insightsData = insights.asData();
    if (insightsData != null) {
      emit(state.copyWith(aiSummary: const AsyncLoading()));

      final aiSummary = await AsyncValue.guard(
        () => _cycleDayInsightsService.generateAiInsights(
          insightsData,
          isCurrentUser: state.isViewingCurrentUser,
          locale: l10n.localeName,
          useCache: useCache,
        ),
      );

      emit(state.copyWith(aiSummary: aiSummary));
    }
  }

  UserProfile? _getActiveProfile() {
    return state.isViewingCurrentUser ? _userProfile : _partnerProfile;
  }
}
