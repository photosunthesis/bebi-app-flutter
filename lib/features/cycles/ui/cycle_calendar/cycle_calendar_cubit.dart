import 'package:bebi_app/features/cycles/data/cycle_logs_repository.dart';
import 'package:bebi_app/features/cycles/domain/cycle_log.dart';
import 'package:bebi_app/features/cycles/domain/predict_upcoming_cycles_usecase.dart';
import 'package:bebi_app/utils/mixins/analytics_mixin.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'cycle_calendar_state.dart';

@injectable
class CycleCalendarCubit extends Cubit<CycleCalendarState>
    with GuardMixin, AnalyticsMixin {
  CycleCalendarCubit(this._cycleLogsRepository, this._predictUpcomingCycles)
    : super(const CycleCalendarLoadedState([])) {
    logScreenViewed(screenName: 'cycle_calendar_screen');
  }

  final CycleLogsRepository _cycleLogsRepository;
  final PredictUpcomingCyclesUsecase _predictUpcomingCycles;

  Future<void> initialize(String userId) async {
    await guard(
      () async {
        final cycleLogs = await _cycleLogsRepository.getCycleLogsByUserId(
          userId,
        );

        final result = _predictUpcomingCycles(cycleLogs, DateTime.now());

        final sortedLogs = [...cycleLogs, ...result.predictions]
          ..sort((a, b) => b.date.compareTo(a.date));

        logDataLoaded(
          dataType: 'cycle_logs',
          parameters: {
            'log_count': cycleLogs.length,
            'predicted_count': result.predictions.length,
          },
        );

        emit(CycleCalendarLoadedState(sortedLogs));
      },
      onError: (error, _) {
        emit(CycleCalendarErrorState(error.toString()));
      },
    );
  }
}
