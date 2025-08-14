import 'dart:async';

import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/repositories/calendar_events_repository.dart';
import 'package:bebi_app/data/services/recurring_calendar_events_service.dart';
import 'package:bebi_app/utils/analytics_utils.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'calendar_cubit.freezed.dart';
part 'calendar_state.dart';

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

        final focusedDayEvents = allEvents
            .where((e) => e.date.isSameDay(state.focusedDay))
            .toList();

        emit(
          state.copyWith(events: allEvents, focusedDayEvents: focusedDayEvents),
        );

        logEvent(
          name: 'calendar_events_loaded',
          parameters: {
            'user_id': _firebaseAuth.currentUser!.uid,
            'total_events': allEvents.length,
            'focused_day_events': focusedDayEvents.length,
            'used_cache': useCache,
            'window_days': _defaultTimeWindow.inDays,
          },
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

    final dayEvents = state.events
        .where((e) => e.date.isSameDay(date))
        .toList();

    emit(state.copyWith(focusedDayEvents: dayEvents));

    logEvent(
      name: 'calendar_date_selected',
      parameters: {
        'user_id': _firebaseAuth.currentUser!.uid,
        'selected_date': date.toIso8601String(),
        'events_count': dayEvents.length,
        'is_today': date.isSameDay(DateTime.now()),
        'days_from_today': date.difference(DateTime.now()).inDays,
      },
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
