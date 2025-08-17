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
  ) : super(CyclesLoadedState());

  final CycleLogsRepository _cycleLogsRepository;
  final CyclePredictionsService _cyclePredictionsService;
  final CycleDayInsightsService _cycleDayInsightsService;
  final UserProfileRepository _userProfileRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;

  static const _userProfileSwitchedEvent = 'user_profile_switched';
  static const _hasCycleProperty = 'has_cycle';

  String get _currentUserId => _firebaseAuth.currentUser!.uid;

  void refreshData() {
    initialize(loadDataFromCache: false);
  }

  Future<void> initialize({bool loadDataFromCache = true}) async {
    if (state is CyclesLoadingState) return;
    await guard(() async {
      final previousDataState = state is CyclesLoadedState
          ? state as CyclesLoadedState
          : null;

      emit(const CyclesLoadingState());

      var userProfile = await _fetchUserProfile(
        _currentUserId,
        useCache: loadDataFromCache,
      );

      if (!userProfile.didSetUpCycles) {
        userProfile = await _disableUserCycleTracking(loadDataFromCache);
      }

      final partnerProfile = await _fetchPartnerProfile(loadDataFromCache);

      if (!userProfile.hasCycle) {
        emit(
          CyclesLoadedState(
            focusedDate: previousDataState?.focusedDate,
            userProfile: userProfile,
            partnerProfile: partnerProfile,
            showCurrentUserCycleData:
                previousDataState?.showCurrentUserCycleData ?? true,
          ),
        );
        return;
      }

      final loadedState = await _getLoadedStateWithCycleData(
        previousState: previousDataState,
        userProfile: userProfile,
        partnerProfile: partnerProfile,
        showCurrentUserCycleData:
            previousDataState?.showCurrentUserCycleData ?? true,
        useCache: loadDataFromCache,
      );
      emit(loadedState);
    }, onError: (error, _) => emit(CyclesErrorState(error.toString())));
  }

  Future<void> setFocusedDate(DateTime date) async {
    await guard(() async {
      var currentState = state;
      if (currentState is CyclesLoadingState) {
        currentState = await stream.firstWhere(
          (element) => element is! CyclesLoadingState,
        );
      }

      if (currentState is! CyclesLoadedState) return;
      final loadedState = currentState;

      if (loadedState.focusedDate.isSameDay(date)) return;

      final insights = _cycleDayInsightsService.getInsightsFromDateAndEvents(
        date,
        loadedState.cycleLogs,
      );

      final aiSummary = await _cycleDayInsightsService.generateAiInsights(
        insights,
        isCurrentUser: loadedState.showCurrentUserCycleData,
        locale: l10n.localeName,
      );

      emit(
        CyclesLoadedState(
          focusedDate: date,
          cycleLogs: loadedState.cycleLogs,
          showCurrentUserCycleData: loadedState.showCurrentUserCycleData,
          aiSummary: aiSummary,
          focusedDateInsights: insights,
          userProfile: loadedState.userProfile,
          partnerProfile: loadedState.partnerProfile,
        ),
      );
    }, onError: (error, _) => emit(CyclesErrorState(error.toString())));
  }

  Future<void> switchUserProfile() async {
    if (state is CyclesLoadingState) return;
    await guard(
      () async {
        if (state is! CyclesLoadedState) return;
        final loadedState = state as CyclesLoadedState;

        if (loadedState.partnerProfile?.isSharingCycleWithPartner != true) {
          throw SimpleException(l10n.partnerCycleSharingNotEnabledError);
        }

        emit(const CyclesLoadingState());

        final newShowCurrentUserCycleData =
            !loadedState.showCurrentUserCycleData;

        final newLoadedState = await _getLoadedStateWithCycleData(
          previousState: loadedState,
          userProfile: loadedState.userProfile!,
          partnerProfile: loadedState.partnerProfile!,
          showCurrentUserCycleData: newShowCurrentUserCycleData,
          useCache: true,
        );

        emit(newLoadedState);

        logEvent(
          name: _userProfileSwitchedEvent,
          parameters: {
            'user_id': _currentUserId,
            if (newLoadedState.partnerProfile != null)
              'partner_id': newLoadedState.partnerProfile!.userId,
          },
        );
      },
      onError: (error, _) => emit(CyclesErrorState(error.toString())),
      logWhen: (error) => error is! SimpleException,
    );
  }

  void trackInsightViewed() {
    if (state is! CyclesLoadedState) return;
    final loadedState = state as CyclesLoadedState;

    logEvent(
      name: 'cycle_insight_viewed',
      parameters: {
        'user_id': _currentUserId,
        if (loadedState.partnerProfile != null)
          'partner_id': loadedState.partnerProfile!.userId,
        'focused_date': loadedState.focusedDate.toIso8601String(),
        'cycle_phase':
            loadedState.focusedDateInsights?.cyclePhase.name ?? 'unknown',
        'day_of_cycle': loadedState.focusedDateInsights?.dayOfCycle ?? 0,
        'has_ai_summary': loadedState.aiSummary != null,
        'viewing_partner_data': !loadedState.showCurrentUserCycleData,
      },
    );
  }

  Future<CyclesLoadedState> _getLoadedStateWithCycleData({
    required CyclesLoadedState? previousState,
    required UserProfile userProfile,
    required UserProfile partnerProfile,
    required bool showCurrentUserCycleData,
    required bool useCache,
  }) async {
    final userId = showCurrentUserCycleData
        ? userProfile.userId
        : partnerProfile.userId;
    final cycleLogs = await _cycleLogsRepository.getCycleLogsByUserId(
      userId,
      useCache: useCache,
    );

    final focusedDate = previousState?.focusedDate ?? DateTime.now();

    final predictions = _cyclePredictionsService.predictUpcomingCycles(
      cycleLogs,
      focusedDate,
    );

    final allLogs = [...cycleLogs, ...predictions];

    final insights = _cycleDayInsightsService.getInsightsFromDateAndEvents(
      focusedDate,
      allLogs,
    );

    final aiSummary = await _cycleDayInsightsService.generateAiInsights(
      insights,
      isCurrentUser: showCurrentUserCycleData,
      locale: l10n.localeName,
    );

    return CyclesLoadedState(
      focusedDate: focusedDate,
      cycleLogs: allLogs,
      showCurrentUserCycleData: showCurrentUserCycleData,
      aiSummary: aiSummary,
      focusedDateInsights: insights,
      userProfile: userProfile,
      partnerProfile: partnerProfile,
    );
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
      throw Exception(l10n.userProfileNotFoundError(userId));
    }
    return userProfile;
  }

  Future<UserProfile> _fetchPartnerProfile(bool useCache) async {
    final partnership = await _userPartnershipsRepository.getByUserId(
      _currentUserId,
      useCache: useCache,
    );

    if (partnership == null) {
      throw Exception(l10n.partnershipNotFoundError(_currentUserId));
    }

    final partnerId = partnership.users.firstWhere(
      (userId) => userId != _currentUserId,
    );

    return await _fetchUserProfile(partnerId, useCache: useCache);
  }

  Future<UserProfile> _disableUserCycleTracking(bool useCache) async {
    final userProfile = await _fetchUserProfile(
      _currentUserId,
      useCache: useCache,
    );

    final updatedUser = userProfile.copyWith(
      hasCycle: false,
      didSetUpCycles: true,
    );

    await _userProfileRepository.createOrUpdate(updatedUser);

    setUserProperty(name: _hasCycleProperty, value: 'false');
    return updatedUser;
  }
}
