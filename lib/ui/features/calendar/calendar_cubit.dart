import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/repositories/calendar_events_repository.dart';
import 'package:bebi_app/data/services/recurring_calendar_events_service.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'calendar_state.dart';
part 'calendar_cubit.freezed.dart';

@injectable
class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit(
    this._calendarEventsRepository,
    this._recurringCalendarEventsService,
    this._firebaseAuth,
  ) : super(CalendarState.initial());

  final CalendarEventsRepository _calendarEventsRepository;
  final RecurringCalendarEventsService _recurringCalendarEventsService;
  final FirebaseAuth _firebaseAuth;

  DateTime? _windowStart;
  DateTime? _windowEnd;

  static const _defaultTimeWindow = Duration(days: 90);

  Future<void> loadCalendarEvents({bool useCache = true}) async {
    await guard(
      () async {
        emit(state.copyWith(loading: true));

        final events = await _calendarEventsRepository.getByUserId(
          userId: _firebaseAuth.currentUser!.uid,
          useCache: useCache,
        );

        _windowStart = state.focusedDay.subtract(_defaultTimeWindow);
        _windowEnd = state.focusedDay.add(_defaultTimeWindow);

        final recurringEvents = _recurringCalendarEventsService
            .generateRecurringEventsInWindow(
              events,
              _windowStart!,
              _windowEnd!,
            );

        final allEvents = [...events, ...recurringEvents];

        emit(
          state.copyWith(
            events: allEvents,
            focusedDayEvents: allEvents
                .where((e) => e.date.isSameDay(state.focusedDay))
                .toList(),
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
      await _calendarEventsRepository.getByUserId(
        userId: _firebaseAuth.currentUser!.uid,
        useCache: false,
      );
    });
  }

  Future<void> setFocusedDay(DateTime date) async {
    emit(state.copyWith(focusedDay: date));

    final needsExpansion =
        (_windowStart == null && _windowEnd == null) ||
        date.isBefore(_windowStart!.add(30.days)) ||
        date.isAfter(_windowEnd!.subtract(30.days));

    if (needsExpansion) return await _expandTimeRange(date);

    emit(
      state.copyWith(
        focusedDayEvents: state.events
            .where((e) => e.date.isSameDay(date))
            .toList(),
      ),
    );
  }

  Future<void> _expandTimeRange(DateTime focusDate) async {
    var newStart = focusDate.subtract(_defaultTimeWindow);
    var newEnd = focusDate.add(_defaultTimeWindow);

    if (_windowStart != null) {
      newStart = _windowStart!.earlierDate(newStart);
    }

    if (_windowEnd != null) {
      newEnd = _windowEnd!.laterDate(newEnd);
    }

    await _loadMoreEvents(newStart, newEnd);
  }

  Future<void> _loadMoreEvents(DateTime rangeStart, DateTime rangeEnd) async {
    await guard(() async {
      emit(state.copyWith(loading: true));

      final newRecurringEvents = _recurringCalendarEventsService
          .generateRecurringEventsInWindow(state.events, rangeStart, rangeEnd);
      _windowStart = _windowStart?.earlierDate(rangeStart) ?? rangeStart;
      _windowEnd = _windowEnd?.laterDate(rangeEnd) ?? rangeEnd;

      final allEvents = [...state.events, ...newRecurringEvents];

      emit(
        state.copyWith(
          events: allEvents,
          focusedDayEvents: allEvents
              .where((e) => e.date.isSameDay(state.focusedDay))
              .toList(),
        ),
      );
    });
  }
}
