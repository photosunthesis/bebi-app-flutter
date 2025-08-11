import 'dart:async';

import 'package:bebi_app/data/models/cycle_day_insights.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/data/repositories/cycle_logs_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/data/services/cycle_day_insights_service.dart';
import 'package:bebi_app/data/services/cycle_predictions_service.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'cycles_cubit.freezed.dart';
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
    this._firebaseAnalytics,
  ) : super(CyclesState.initial());

  final CycleLogsRepository _cycleLogsRepository;
  final CyclePredictionsService _cyclePredictionsService;
  final CycleDayInsightsService _cycleDayInsightsService;
  final UserProfileRepository _userProfileRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;
  final FirebaseAnalytics _firebaseAnalytics;

  static const _cycleInsightsGeneratedEvent = 'cycle_insights_generated';
  static const _userProfileSwitchedEvent = 'user_profile_switched';
  static const _hasCycleProperty = 'has_cycle';

  String get _currentUserId => _firebaseAuth.currentUser!.uid;

  Future<void> initialize({bool loadDataFromCache = true}) async {
    await guard(
      () async {
        emit(state.copyWith(loading: true, loadingAiSummary: true));

        final userProfile = await _fetchUserProfile(_currentUserId);
        if (!userProfile.didSetUpCycles) await _disableUserCycleTracking();

        final partnerProfile = await _fetchPartnerProfile();

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

        if (state.userProfile?.hasCycle != true) return;

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
        _logCycleInsightsGenerated(date);
      },
      onError: (error, _) => emit(state.copyWith(error: error.toString())),
      onComplete: () => emit(state.copyWith(loadingAiSummary: false)),
    );
  }

  Future<void> switchUserProfile() async {
    await guard(
      () async {
        if (state.partnerProfile?.isSharingCycleWithPartner != true) return;

        emit(
          state.copyWith(
            showCurrentUserCycleData: !state.showCurrentUserCycleData,
            loading: true,
            loadingAiSummary: true,
          ),
        );

        await _loadCycleData(useCache: true);

        _logUserProfileSwitched();
      },
      onError: (error, _) => emit(state.copyWith(error: error.toString())),
      onComplete: () => emit(
        state.copyWith(error: null, loading: false, loadingAiSummary: false),
      ),
    );
  }

  Future<void> _loadCycleData({required bool useCache}) async {
    final cycleLogs = await _cycleLogsRepository.getCycleLogsByUserId(
      _currentUserId,
      useCache: useCache,
    );

    final predictions = _cyclePredictionsService.predictUpcomingCycles(
      cycleLogs,
      state.focusedDate,
    );

    final allCycleLogs = [...cycleLogs, ...predictions];
    emit(state.copyWith(cycleLogs: allCycleLogs, loading: false));

    await _generateAndUpdateInsights(DateTime.now());
    _logCycleInsightsGenerated(state.focusedDate);
  }

  Future<void> _generateAndUpdateInsights(DateTime date) async {
    final cycleDayInsights = _cycleDayInsightsService
        .getInsightsFromDateAndEvents(date, state.cycleLogs);

    if (cycleDayInsights == null) return;

    emit(state.copyWith(focusedCycleDayInsights: cycleDayInsights));

    final aiInsights = await _cycleDayInsightsService.generateAiInsights(
      cycleDayInsights,
      isCurrentUser: state.showCurrentUserCycleData,
    );

    emit(state.copyWith(aiSummary: aiInsights));
  }

  Future<UserProfile> _fetchUserProfile(String userId) async {
    final userProfile = await _userProfileRepository.getByUserId(userId);
    if (userProfile == null) {
      throw Exception('User profile not found for user: $userId');
    }
    return userProfile;
  }

  Future<UserProfile> _fetchPartnerProfile() async {
    final partnership = await _userPartnershipsRepository.getByUserId(
      _currentUserId,
    );
    if (partnership == null) {
      throw Exception('Partnership not found for user: $_currentUserId');
    }

    final partnerId = partnership.users.firstWhere(
      (userId) => userId != _currentUserId,
    );

    return await _fetchUserProfile(partnerId);
  }

  Future<void> _disableUserCycleTracking() async {
    final userProfile = await _fetchUserProfile(_currentUserId);

    final updatedUser = userProfile.copyWith(
      hasCycle: false,
      didSetUpCycles: true,
    );

    await _userProfileRepository.createOrUpdate(updatedUser);
    emit(state.copyWith(userProfile: updatedUser));

    unawaited(
      _firebaseAnalytics.setUserProperty(
        name: _hasCycleProperty,
        value: 'false',
      ),
    );
  }

  void _logCycleInsightsGenerated(DateTime focusedDate) {
    unawaited(
      _firebaseAnalytics.logEvent(
        name: _cycleInsightsGeneratedEvent,
        parameters: _buildAnalyticsParameters(
          additionalParams: {
            'focused_date': focusedDate.toEEEEMMMMdyyyyhhmma(),
          },
        ),
      ),
    );
  }

  void _logUserProfileSwitched() {
    unawaited(
      _firebaseAnalytics.logEvent(
        name: _userProfileSwitchedEvent,
        parameters: _buildAnalyticsParameters(),
      ),
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
