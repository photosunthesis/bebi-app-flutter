import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/repositories/calendar_events_repository.dart';
import 'package:bebi_app/data/services/recurring_calendar_events_service.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_state.dart';
part 'calendar_cubit.freezed.dart';

class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit(
    this._calendarEventsRepository,
    this._recurringCalendarEventsService,
    this._firebaseAuth,
  ) : super(CalendarState.initial());

  final CalendarEventsRepository _calendarEventsRepository;
  final RecurringCalendarEventsService _recurringCalendarEventsService;
  final FirebaseAuth _firebaseAuth;

  static const _defaultTimeWindow = Duration(days: 90);

  Future<void> initialize({bool useCache = true}) async {
    await guard(
      () async {
        emit(state.copyWith(loading: true));

        final events = await _calendarEventsRepository.getByUserId(
          userId: _firebaseAuth.currentUser!.uid,
          useCache: useCache,
        );

        final windowStart = state.focusedDay.subtract(_defaultTimeWindow);
        final windowEnd = state.focusedDay.add(_defaultTimeWindow);
        final recurringEvents = _recurringCalendarEventsService
            .generateRecurringEventsInWindow(events, windowStart, windowEnd);

        emit(
          state.copyWith(
            events: events,
            recurringEvents: recurringEvents,
            focusedDayEvents: _recurringCalendarEventsService
                .getFocusedDayEvents(state.focusedDay, events, recurringEvents),
            windowStart: windowStart,
            windowEnd: windowEnd,
          ),
        );
      },
      onError: (error, _) {
        emit(state.copyWith(error: error.toString()));
      },
      onComplete: () {
        emit(state.copyWith(loading: false, error: null));
      },
    );
  }

  Future<void> fetchLatestEventsFromServer() async {
    await guard(() async {
      await _calendarEventsRepository.loadEventsFromServer(
        _firebaseAuth.currentUser?.uid,
      );
    });
  }

  Future<void> setFocusedDay(DateTime date) async {
    emit(state.copyWith(focusedDay: date));

    final needsExpansion =
        (state.windowStart == null && state.windowEnd == null) ||
        date.isBefore(state.windowStart!.add(const Duration(days: 30))) ||
        date.isAfter(state.windowEnd!.subtract(const Duration(days: 30)));

    if (needsExpansion) await _expandTimeRange(date);

    emit(
      state.copyWith(
        focusedDayEvents: _recurringCalendarEventsService.getFocusedDayEvents(
          date,
          state.events,
          state.recurringEvents,
        ),
      ),
    );
  }

  Future<void> loadMoreEvents({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    await guard(() async {
      emit(state.copyWith(loading: true));

      final newRecurringEvents = _recurringCalendarEventsService
          .generateRecurringEventsInWindow(state.events, rangeStart, rangeEnd);
      final mergedRecurringEvents = _recurringCalendarEventsService
          .mergeRecurringEvents(state.recurringEvents, newRecurringEvents);
      final newStartWindow =
          state.windowStart?.earlierDate(rangeStart) ?? rangeStart;
      final newEndWindow = state.windowEnd?.laterDate(rangeEnd) ?? rangeEnd;

      emit(
        state.copyWith(
          recurringEvents: mergedRecurringEvents,
          focusedDayEvents: _recurringCalendarEventsService.getFocusedDayEvents(
            state.focusedDay,
            state.events,
            mergedRecurringEvents,
          ),
          windowStart: newStartWindow,
          windowEnd: newEndWindow,
        ),
      );
    });
  }

  Future<void> _expandTimeRange(DateTime focusDate) async {
    var newStart = focusDate.subtract(_defaultTimeWindow);
    var newEnd = focusDate.add(_defaultTimeWindow);

    if (state.windowStart != null) {
      newStart = state.windowStart!.earlierDate(newStart);
    }

    if (state.windowEnd != null) {
      newEnd = state.windowEnd!.laterDate(newEnd);
    }

    await loadMoreEvents(rangeStart: newStart, rangeEnd: newEnd);
  }
}
