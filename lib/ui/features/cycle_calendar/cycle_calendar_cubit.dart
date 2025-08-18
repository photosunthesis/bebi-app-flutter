import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/repositories/cycle_logs_repository.dart';
import 'package:bebi_app/data/services/cycle_predictions_service.dart';
import 'package:bebi_app/utils/mixins/analytics_utils.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'cycle_calendar_state.dart';

@injectable
class CycleCalendarCubit extends Cubit<CycleCalendarState>
    with GuardMixin, AnalyticsMixin {
  CycleCalendarCubit(this._cycleLogsRepository, this._cyclePredictionsService)
    : super(const CycleCalendarLoadedState([]));

  final CycleLogsRepository _cycleLogsRepository;
  final CyclePredictionsService _cyclePredictionsService;

  Future<void> initialize(String userId) async {
    await guard(
      () async {
        final cycleLogs = await _cycleLogsRepository.getCycleLogsByUserId(
          userId,
        );

        final predictions = _cyclePredictionsService.predictUpcomingCycles(
          cycleLogs,
          DateTime.now(),
        );

        final sortedLogs = [...cycleLogs, ...predictions]
          ..sort((a, b) => b.date.compareTo(a.date));

        logEvent(
          name: 'cycle_calendar_screen_opened',
          parameters: {'user_id': userId},
        );

        emit(CycleCalendarLoadedState(sortedLogs));
      },
      onError: (error, _) {
        emit(CycleCalendarErrorState(error.toString()));
      },
    );
  }
}
