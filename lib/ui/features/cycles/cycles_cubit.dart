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
    emit(
      state.copyWith(
        focusedDate: state.focusedDate,
        showCurrentUserCycleData: state.showCurrentUserCycleData,
        isLoading: true,
      ),
    );

    await initialize(loadDataFromCache: false);
  }

  Future<void> initialize({bool loadDataFromCache = true}) async {
    if (state.isLoading) return;
    await guard(
      () async {
        emit(state.copyWith(isLoading: true));

        final userProfileFromRepo = await _userProfileRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
          useCache: loadDataFromCache,
        );

        if (userProfileFromRepo == null) {
          throw Exception(
            l10n.userProfileNotFoundError(_firebaseAuth.currentUser!.uid),
          );
        }

        var userProfile = userProfileFromRepo;

        if (!userProfile.didSetUpCycles) {
          userProfile = userProfile.copyWith(
            hasCycle: false,
            didSetUpCycles: true,
          );
          await _userProfileRepository.createOrUpdate(userProfile);
          setUserProperty(name: _hasCycleProperty, value: 'false');
        }

        emit(state.copyWith(userProfile: userProfile));

        final partnership = await _userPartnershipsRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
          useCache: loadDataFromCache,
        );

        final partnerId = partnership!.users.firstWhere(
          (userId) => userId != _firebaseAuth.currentUser!.uid,
        );

        final partnerProfile = await _userProfileRepository.getByUserId(
          partnerId,
          useCache: loadDataFromCache,
        );

        emit(state.copyWith(partnerProfile: partnerProfile));

        if (!userProfile.hasCycle) return;

        await _loadCycleData(
          userProfile: userProfile,
          partnerProfile: partnerProfile!,
          showCurrentUserCycleData: state.showCurrentUserCycleData,
          useCache: loadDataFromCache,
        );
      },
      onError: (error, _) =>
          emit(state.copyWith(error: error.toString(), isLoading: false)),
      onComplete: () => emit(
        state.copyWith(isLoading: false, error: null, isInsightLoading: false),
      ),
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

        emit(state.copyWith(focusedDateInsights: insights, aiSummary: null));

        final aiSummary = await _cycleDayInsightsService.generateAiInsights(
          insights,
          isCurrentUser: state.showCurrentUserCycleData,
          locale: l10n.localeName,
        );

        emit(state.copyWith(aiSummary: aiSummary));
      },
      onError: (error, _) => emit(state.copyWith(error: error.toString())),
      onComplete: () => emit(
        state.copyWith(isLoading: false, error: null, isInsightLoading: false),
      ),
    );
  }

  Future<void> switchUserProfile() async {
    await guard(
      () async {
        if (state.partnerProfile?.isSharingCycleWithPartner != true) {
          throw SimpleException(l10n.partnerCycleSharingNotEnabledError);
        }

        final newShowCurrentUser = !state.showCurrentUserCycleData;

        emit(state.copyWith(isLoading: true));

        final targetProfile = newShowCurrentUser
            ? state.userProfile
            : state.partnerProfile;

        if (targetProfile?.hasCycle != true) {
          emit(
            state.copyWith(
              cycleLogs: [],
              showCurrentUserCycleData: newShowCurrentUser,
              aiSummary: null,
              focusedDateInsights: null,
            ),
          );

          logEvent(
            name: _userProfileSwitchedEvent,
            parameters: {
              'user_id': _firebaseAuth.currentUser!.uid,
              if (state.partnerProfile != null)
                'partner_id': state.partnerProfile!.userId,
            },
          );
          return;
        }

        await _loadCycleData(
          userProfile: state.userProfile!,
          partnerProfile: state.partnerProfile!,
          showCurrentUserCycleData: newShowCurrentUser,
          useCache: true,
        );

        logEvent(
          name: _userProfileSwitchedEvent,
          parameters: {
            'user_id': _firebaseAuth.currentUser!.uid,
            if (state.partnerProfile != null)
              'partner_id': state.partnerProfile!.userId,
          },
        );
      },
      onError: (error, _) =>
          emit(state.copyWith(error: error.toString(), isLoading: false)),
      onComplete: () => emit(
        state.copyWith(isLoading: false, error: null, isInsightLoading: false),
      ),
    );
  }

  Future<void> _loadCycleData({
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

    final predictions = _cyclePredictionsService.predictUpcomingCycles(
      cycleLogs,
      state.focusedDate,
    );

    final allLogs = [...cycleLogs, ...predictions];

    final insights = _cycleDayInsightsService.getInsightsFromDateAndEvents(
      state.focusedDate,
      allLogs,
    );

    emit(
      state.copyWith(
        cycleLogs: allLogs,
        showCurrentUserCycleData: showCurrentUserCycleData,
        focusedDateInsights: insights,
        isLoading: false,
      ),
    );

    final aiSummary = await _cycleDayInsightsService.generateAiInsights(
      insights,
      isCurrentUser: showCurrentUserCycleData,
      locale: l10n.localeName,
    );

    emit(state.copyWith(aiSummary: aiSummary, isInsightLoading: false));
  }
}
