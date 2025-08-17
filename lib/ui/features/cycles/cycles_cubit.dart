import 'dart:async';

import 'package:bebi_app/data/models/cycle_day_insights.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/data/repositories/cycle_logs_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/data/services/cycle_day_insights_service.dart';
import 'package:bebi_app/data/services/cycle_predictions_service.dart';
import 'package:bebi_app/utils/analytics_utils.dart';
import 'package:bebi_app/utils/exceptions/simple_exception.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'cycles_state.dart';

@injectable
class CyclesCubit extends Cubit<CyclesState> {
  CyclesCubit(
    this._cycleLogsRepository,
    this._cyclePredictionsService,
    this._cycleDayInsightsService,
    this._userProfileRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
  ) : super(CyclesState.initial());

  final CycleLogsRepository _cycleLogsRepository;
  final CyclePredictionsService _cyclePredictionsService;
  final CycleDayInsightsService _cycleDayInsightsService;
  final UserProfileRepository _userProfileRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;

  static const _cycleInsightsGeneratedEvent = 'cycle_insights_generated';
  static const _userProfileSwitchedEvent = 'user_profile_switched';
  static const _hasCycleProperty = 'has_cycle';

  String get _currentUserId => _firebaseAuth.currentUser!.uid;

  void refreshData() {
    emit(CyclesState.initial());
    initialize(loadDataFromCache: false);
  }

  Future<void> initialize({bool loadDataFromCache = true}) async {
    await guard(
      () async {
        emit(state.copyWith(loading: true, loadingAiSummary: true));

        final userProfile = await _fetchUserProfile(
          _currentUserId,
          useCache: loadDataFromCache,
        );

        if (!userProfile.didSetUpCycles) {
          await _disableUserCycleTracking(loadDataFromCache);
        }

        final partnerProfile = await _fetchPartnerProfile(loadDataFromCache);

        // If user profile was updated by _disableUserCycleTracking, use the state's profile.
        // Otherwise, use the newly fetched profile.
        final effectiveUserProfile =
            state.userProfile != null && state.userProfile != userProfile
            ? state.userProfile!
            : userProfile;

        emit(
          state.copyWith(
            userProfile: effectiveUserProfile,
            partnerProfile: partnerProfile,
          ),
        );

        if (!effectiveUserProfile.hasCycle) return;

        await _loadCycleData(useCache: loadDataFromCache);
      },
      onError: (error, _) => emit(state.copyWith(error: error.toString())),
      onComplete: () =>
          emit(state.copyWith(loading: false, loadingAiSummary: false)),
    );
  }

  Future<void> setFocusedDate(DateTime date) async {
    await guard(
      () async {
        emit(state.copyWith(loadingAiSummary: true, focusedDate: date));
        await _generateAndUpdateInsights(date);
      },
      onError: (error, _) => emit(state.copyWith(error: error.toString())),
      onComplete: () => emit(state.copyWith(loadingAiSummary: false)),
    );
  }

  Future<void> switchUserProfile() async {
    await guard(
      () async {
        if (state.partnerProfile?.isSharingCycleWithPartner != true) {
          throw const SimpleException(
            'Looks like your partner hasn\'t enabled cycle sharing yet. You can ask them to turn it on in their profile settings.',
          );
        }

        emit(
          state.copyWith(
            loading: true,
            loadingAiSummary: true,
            showCurrentUserCycleData: !state.showCurrentUserCycleData,
          ),
        );

        await _loadCycleData();

        _logUserProfileSwitched();
      },
      onError: (error, _) => emit(state.copyWith(error: error.toString())),
      onComplete: () => emit(
        state.copyWith(error: null, loading: false, loadingAiSummary: false),
      ),
      logWhen: (error) => error is! SimpleException,
    );
  }

  void trackInsightViewed() {
    logEvent(
      name: 'cycle_insight_viewed',
      parameters: _buildAnalyticsParameters(
        additionalParams: {
          'focused_date': state.focusedDate.toIso8601String(),
          'cycle_phase':
              state.focusedCycleDayInsights?.cyclePhase.name ?? 'unknown',
          'day_of_cycle': state.focusedCycleDayInsights?.dayOfCycle ?? 0,
          'has_ai_summary': state.aiSummary != null,
          'viewing_partner_data': !state.showCurrentUserCycleData,
        },
      ),
    );
  }

  Future<void> _loadCycleData({bool useCache = true}) async {
    final cycleLogs = await _cycleLogsRepository.getCycleLogsByUserId(
      state.showCurrentUserCycleData
          ? _currentUserId
          : state.partnerProfile!.userId,
      useCache: useCache,
    );

    final predictions = _cyclePredictionsService.predictUpcomingCycles(
      cycleLogs,
      state.focusedDate,
    );

    emit(state.copyWith(cycleLogs: [...cycleLogs, ...predictions]));

    await _generateAndUpdateInsights(state.focusedDate);
  }

  Future<void> _generateAndUpdateInsights(DateTime date) async {
    final cycleDayInsights = _cycleDayInsightsService
        .getInsightsFromDateAndEvents(date, state.cycleLogs);

    if (cycleDayInsights == null) return;

    emit(state.copyWith(focusedCycleDayInsights: cycleDayInsights));

    final aiInsights = await _cycleDayInsightsService.generateAiInsights(
      cycleDayInsights,
      isCurrentUser: state.showCurrentUserCycleData,
      locale: l10n.localeName,
    );

    emit(state.copyWith(aiSummary: aiInsights));

    _logCycleInsightsGenerated(state.focusedDate);
  }

  Future<UserProfile> _fetchUserProfile(
    String userId, {
    bool useCache = true,
  }) async {
    final userProfile = await _userProfileRepository.getByUserId(
      userId,
      useCache: useCache,
    );
    if (userProfile == null) {
      throw Exception('User profile not found for user: $userId');
    }
    return userProfile;
  }

  Future<UserProfile> _fetchPartnerProfile(bool useCache) async {
    final partnership = await _userPartnershipsRepository.getByUserId(
      _currentUserId,
      useCache: useCache,
    );

    if (partnership == null) {
      throw Exception('Partnership not found for user: $_currentUserId');
    }

    final partnerId = partnership.users.firstWhere(
      (userId) => userId != _currentUserId,
    );

    return await _fetchUserProfile(partnerId, useCache: useCache);
  }

  Future<void> _disableUserCycleTracking(bool useCache) async {
    final userProfile = await _fetchUserProfile(
      _currentUserId,
      useCache: useCache,
    );

    final updatedUser = userProfile.copyWith(
      hasCycle: false,
      didSetUpCycles: true,
    );

    await _userProfileRepository.createOrUpdate(updatedUser);
    emit(state.copyWith(userProfile: updatedUser));

    setUserProperty(name: _hasCycleProperty, value: 'false');
  }

  void _logCycleInsightsGenerated(DateTime focusedDate) {
    logEvent(
      name: _cycleInsightsGeneratedEvent,
      parameters: _buildAnalyticsParameters(
        additionalParams: {'focused_date': focusedDate.toEEEEMMMMdyyyyhhmma()},
      ),
    );
  }

  void _logUserProfileSwitched() {
    logEvent(
      name: _userProfileSwitchedEvent,
      parameters: _buildAnalyticsParameters(),
    );
  }

  Map<String, Object> _buildAnalyticsParameters({
    Map<String, Object>? additionalParams,
  }) {
    final baseParams = <String, Object>{
      'user_id': _currentUserId,
      if (state.partnerProfile != null)
        'partner_id': state.partnerProfile!.userId,
    };

    if (additionalParams != null) {
      baseParams.addAll(additionalParams);
    }

    return baseParams;
  }
}
