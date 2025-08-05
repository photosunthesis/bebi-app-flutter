import 'package:bebi_app/config/firebase_services.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/repositories/cycle_logs_repository.dart';
import 'package:bebi_app/data/repositories/user_preferences_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/data/services/cycle_predictions_service.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cycles_cubit.freezed.dart';
part 'cycles_state.dart';

class CyclesCubit extends Cubit<CyclesState> {
  CyclesCubit(
    this._cycleLogsRepository,
    this._cyclePredictionsService,
    this._userProfileRepository,
    this._userPreferencesRepository,
    this._firebaseAuth,
  ) : super(CyclesState.initial());

  final CycleLogsRepository _cycleLogsRepository;
  final CyclePredictionsService _cyclePredictionsService;
  final UserProfileRepository _userProfileRepository;
  final UserPreferencesRepository _userPreferencesRepository;
  final FirebaseAuth _firebaseAuth;

  Future<void> initialize({bool loadDataFromCache = true}) async {
    await guard(
      () async {
        emit(state.copyWith(loading: true));

        final shouldSetupCycles = !_userPreferencesRepository
            .isCycleSetupCompleted();

        if (shouldSetupCycles) {
          return emit(state.copyWith(shouldSetupCycles: true));
        }

        final cycleLogs = await _cycleLogsRepository.getCycleLogsByUserId(
          _firebaseAuth.currentUser!.uid,
          useCache: loadDataFromCache,
        );

        final predictions = _cyclePredictionsService.predictUpcomingCycles(
          cycleLogs,
        );

        emit(state.copyWith(cycleLogs: [...cycleLogs, ...predictions]));
      },
      onError: (error, _) {
        emit(state.copyWith(error: error.toString()));
      },
      onComplete: () {
        emit(state.copyWith(loading: false));
      },
    );
  }

  Future<void> disableUserCycleTracking() async {
    await guard(
      () async {
        final userProfile = await _userProfileRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
        );

        await Future.wait([
          _userProfileRepository.createOrUpdate(
            userProfile!.copyWith(hasCycle: false),
          ),
          _userPreferencesRepository.saveCycleSetupCompletion(
            isCompleted: true,
          ),
        ]);

        emit(state.copyWith(shouldSetupCycles: false));
      },
      onError: (error, _) {
        emit(state.copyWith(error: error.toString()));
      },
    );
  }
}
