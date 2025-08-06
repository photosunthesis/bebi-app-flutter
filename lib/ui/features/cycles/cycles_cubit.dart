import 'package:bebi_app/data/models/cycle_day_insights.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/repositories/cycle_logs_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/data/services/cycle_day_insights_service.dart';
import 'package:bebi_app/data/services/cycle_predictions_service.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/guard.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'cycles_cubit.freezed.dart';
part 'cycles_state.dart';

@Injectable()
class CyclesCubit extends Cubit<CyclesState> {
  CyclesCubit(
    this._cycleLogsRepository,
    this._cyclePredictionsService,
    this._cycleDayInsightsService,
    this._userProfileRepository,
    this._firebaseAuth,
  ) : super(CyclesState.initial());

  final CycleLogsRepository _cycleLogsRepository;
  final CyclePredictionsService _cyclePredictionsService;
  final CycleDayInsightsService _cycleDayInsightsService;
  final UserProfileRepository _userProfileRepository;
  final FirebaseAuth _firebaseAuth;

  Future<void> initialize({bool loadDataFromCache = true}) async {
    await guard(
      () async {
        emit(state.copyWith(loading: true, loadingCycleDayInsights: true));

        final userProfile = await _userProfileRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
        );

        if (!userProfile!.didSetUpCycles) {
          if (state.shouldSetupCycles) return;
          emit(state.copyWith(shouldSetupCycles: true));
          return;
        }

        final cycleLogs = await _cycleLogsRepository.getCycleLogsByUserId(
          _firebaseAuth.currentUser!.uid,
          useCache: loadDataFromCache,
        );

        final predictions = _cyclePredictionsService.predictUpcomingCycles(
          cycleLogs,
        );

        final allCycleLogs = [...cycleLogs, ...predictions];

        emit(state.copyWith(cycleLogs: allCycleLogs, loading: false));

        final cycleDayInsights = await _cycleDayInsightsService
            .getInsightsFromDateAndEvents(DateTime.now(), allCycleLogs);

        emit(
          state.copyWith(
            focusedCycleDayInsights: cycleDayInsights,
            loadingCycleDayInsights: false,
          ),
        );
      },
      onError: (error, _) {
        emit(state.copyWith(error: error.toString()));
      },
      onComplete: () {
        emit(state.copyWith(loading: false, loadingCycleDayInsights: false));
      },
    );
  }

  Future<void> setFocusedDate(DateTime date) async {
    await guard(
      () async {
        emit(state.copyWith(loadingCycleDayInsights: true, focusedDate: date));

        final updatedCycleDayInsights = await _cycleDayInsightsService
            .getInsightsFromDateAndEvents(date, state.cycleLogs);

        emit(state.copyWith(focusedCycleDayInsights: updatedCycleDayInsights));
      },
      onError: (error, _) {
        emit(state.copyWith(error: error.toString()));
      },
      onComplete: () {
        emit(state.copyWith(loadingCycleDayInsights: false));
      },
    );
  }

  Future<void> disableUserCycleTracking() async {
    await guard(
      () async {
        final userProfile = await _userProfileRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
        );

        await _userProfileRepository.createOrUpdate(
          userProfile!.copyWith(hasCycle: false, didSetUpCycles: false),
        );

        emit(state.copyWith(shouldSetupCycles: false));
      },
      onError: (error, _) {
        emit(state.copyWith(error: error.toString()));
      },
    );
  }
}
