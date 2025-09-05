import 'dart:async';

import 'package:bebi_app/data/models/async_value.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/repositories/calendar_events_repository.dart';
import 'package:bebi_app/data/services/recurring_calendar_events_service.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:bebi_app/utils/mixins/analytics_mixin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'calendar_state.dart';

@injectable
class CalendarCubit extends Cubit<CalendarState> with AnalyticsMixin {
  CalendarCubit(
    this._calendarEventsRepository,
    this._recurringCalendarEventsService,
    this._firebaseAuth,
  ) : super(CalendarState(focusedDay: DateTime.now()));

  final CalendarEventsRepository _calendarEventsRepository;
  final RecurringCalendarEventsService _recurringCalendarEventsService;
  final FirebaseAuth _firebaseAuth;

  DateTime? _windowStart;
  DateTime? _windowEnd;

  static const _defaultTimeWindow = Duration(days: 90);

  Future<void> loadCalendarEvents({bool useCache = true}) async {
    emit(
      state.copyWith(
        events: const AsyncLoading(),
        baseEvents: const AsyncLoading(),
      ),
    );

    _windowStart = state.focusedDay.subtract(_defaultTimeWindow);
    _windowEnd = state.focusedDay.add(_defaultTimeWindow);

    // Clear the recurring events cache to ensure fresh generation
    _recurringCalendarEventsService.clearCache();

    final result = await AsyncValue.guard(() async {
      final baseEvents = await _calendarEventsRepository.getByUserId(
        userId: _firebaseAuth.currentUser!.uid,
        useCache: useCache,
      );

      final recurringEvents = _recurringCalendarEventsService
          .generateRecurringEventsInWindow(
            baseEvents,
            _windowStart!,
            _windowEnd!,
          );

      // Only include base events that are not recurring, since recurring events
      // are generated separately and include the original occurrence
      final nonRecurringBaseEvents = baseEvents
          .where((e) => !e.isRecurring)
          .toList();
      final allEvents = [...nonRecurringBaseEvents, ...recurringEvents];

      logEvent(
        name: 'calendar_events_loaded',
        parameters: {
          'total_events': allEvents.length,
          'focused_day_events': allEvents
              .where((e) => e.startDate.isSameDay(state.focusedDay))
              .length,
          'used_cache': useCache,
          'window_days': _defaultTimeWindow.inDays,
        },
      );

      return allEvents;
    });

    if (result is AsyncData<List<CalendarEvent>>) {
      final baseEvents = await _calendarEventsRepository.getByUserId(
        userId: _firebaseAuth.currentUser!.uid,
        useCache: useCache,
      );
      emit(state.copyWith(events: result, baseEvents: AsyncData(baseEvents)));
    } else {
      emit(state.copyWith(events: result, baseEvents: result));
    }
  }

  Future<void> fetchLatestEventsFromServer() async {
    await AsyncValue.guard(() async {
      await _calendarEventsRepository.getByUserId(
        userId: _firebaseAuth.currentUser!.uid,
        useCache: false,
      );
    });
  }

  Future<void> setFocusedDay(DateTime date) async {
    final needsExpansion =
        (_windowStart == null && _windowEnd == null) ||
        date.isBefore(_windowStart!.add(30.days)) ||
        date.isAfter(_windowEnd!.subtract(30.days));

    if (needsExpansion) return await _expandTimeRange(date);

    emit(state.copyWith(focusedDay: date));

    logEvent(
      name: 'calendar_date_selected',
      parameters: {
        'is_today': date.isSameDay(DateTime.now()),
        'days_from_today': date.difference(DateTime.now()).inDays,
        'is_future_date': date.isAfter(DateTime.now()),
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
    final baseEvents = state.baseEvents.asData() ?? [];

    emit(state.copyWith(events: const AsyncLoading()));

    final result = await AsyncValue.guard(() async {
      final recurringEvents = _recurringCalendarEventsService
          .generateRecurringEventsInWindow(baseEvents, rangeStart, rangeEnd);

      _windowStart = _windowStart?.earlierDate(rangeStart) ?? rangeStart;
      _windowEnd = _windowEnd?.laterDate(rangeEnd) ?? rangeEnd;

      // Only include base events that are not recurring
      final nonRecurringBaseEvents = baseEvents
          .where((e) => !e.isRecurring)
          .toList();
      return [...nonRecurringBaseEvents, ...recurringEvents];
    });

    emit(state.copyWith(events: result));
  }
}
