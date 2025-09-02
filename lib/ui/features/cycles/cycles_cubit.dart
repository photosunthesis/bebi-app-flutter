import 'dart:async';

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

  static const _userProfileSwitchedEvent = 'user_profile_switched';
  static const _hasCycleProperty = 'has_cycle';

  Future<void> refreshData() async {
    emit(state.copyWith(isLoading: true, isInsightLoading: true));
    await initialize(loadDataFromCache: false);
  }

  Future<void> initialize({bool loadDataFromCache = true}) async {
    await guard(
      () async {
        emit(state.copyWith(isLoading: true));

        final currentUser = _firebaseAuth.currentUser!;

        final userProfile = await _userProfileRepository.getByUserId(
          currentUser.uid,
          useCache: loadDataFromCache,
        );

        var finalUserProfile = userProfile;

        if (!userProfile!.didSetUpCycles) {
          finalUserProfile = userProfile.copyWith(
            hasCycle: false,
            didSetUpCycles: true,
          );
          await _userProfileRepository.createOrUpdate(finalUserProfile);
          setUserProperty(name: _hasCycleProperty, value: 'false');
        }

        final partnership = await _userPartnershipsRepository.getByUserId(
          currentUser.uid,
          useCache: loadDataFromCache,
        );

        final partnerId = partnership?.users.firstWhere(
          (userId) => userId != currentUser.uid,
          orElse: () => '',
        );

        UserProfile? partnerProfile;

        if (partnerId != null && partnerId.isNotEmpty) {
          partnerProfile = await _userProfileRepository.getByUserId(
            partnerId,
            useCache: loadDataFromCache,
          );
        }

        emit(
          state.copyWith(
            userProfile: finalUserProfile,
            partnerProfile: partnerProfile,
          ),
        );

        await _loadDataForActiveProfile(useCache: loadDataFromCache);
      },
      onError: (error, _) =>
          emit(state.copyWith(error: error.toString(), isLoading: false)),
      onComplete: () =>
          emit(state.copyWith(isLoading: false, isInsightLoading: false)),
    );
  }

  Future<void> setFocusedDate(DateTime date) async {
    await guard(
      () async {
        if (state.focusedDate.isSameDay(date)) return;

        emit(state.copyWith(isInsightLoading: true, focusedDate: date));

        final insights = _cycleDayInsightsService.getInsightsFromDateAndEvents(
          date,
          state.cycleLogs,
        );

        final aiSummary = await _cycleDayInsightsService.generateAiInsights(
          insights,
          isCurrentUser: state.isViewingCurrentUser,
          locale: l10n.localeName,
        );

        emit(
          state.copyWith(focusedDateInsights: insights, aiSummary: aiSummary),
        );
      },
      onError: (error, _) => emit(state.copyWith(error: error.toString())),
      onComplete: () => emit(state.copyWith(isInsightLoading: false)),
    );
  }

  Future<void> switchUserProfile() async {
    await guard(
      () async {
        if (state.partnerProfile?.isSharingCycleWithPartner != true) {
          throw Exception('Partner has not enabled cycle sharing.');
        }

        emit(
          state.copyWith(
            isLoading: true,
            isViewingCurrentUser: !state.isViewingCurrentUser,
          ),
        );

        await _loadDataForActiveProfile(useCache: true);

        logEvent(
          name: _userProfileSwitchedEvent,
          parameters: {
            'user_id': state.userProfile!.userId,
            'partner_id': state.partnerProfile!.userId,
            'viewing': state.isViewingCurrentUser ? 'current_user' : 'partner',
          },
        );
      },
      onError: (error, _) =>
          emit(state.copyWith(error: error.toString(), isLoading: false)),
      onComplete: () =>
          emit(state.copyWith(isLoading: false, isInsightLoading: false)),
    );
  }

  Future<void> _loadDataForActiveProfile({required bool useCache}) async {
    final activeProfile = state.isViewingCurrentUser
        ? state.userProfile
        : state.partnerProfile;

    if (activeProfile?.hasCycle != true) {
      emit(state.copyWith(cycleLogs: []));
      return;
    }

    final cycleLogs = await _cycleLogsRepository.getCycleLogsByUserId(
      activeProfile!.userId,
      useCache: useCache,
    );

    final predictions = _cyclePredictionsService.predictUpcomingCycles(
      cycleLogs,
      state.focusedDate,
    );

    final allLogs = [...cycleLogs, ...predictions];

    final insights = _cycleDayInsightsService.getInsightsFromDateAndEvents(
      state.focusedDate,
      allLogs,
    );

    final aiSummary = await _cycleDayInsightsService.generateAiInsights(
      insights,
      isCurrentUser: state.isViewingCurrentUser,
      locale: l10n.localeName,
      useCache: useCache,
    );

    emit(
      state.copyWith(
        cycleLogs: allLogs,
        focusedDateInsights: insights,
        aiSummary: aiSummary,
      ),
    );
  }
}
