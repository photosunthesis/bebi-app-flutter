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

@Injectable()
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
        if (!useCache) emit(state.copyWith(loading: true));

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
            focusedDayEvents: _filterFocusedDayEvents(allEvents),
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
      await _calendarEventsRepository.loadEventsFromServer();
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
      state.copyWith(focusedDayEvents: _filterFocusedDayEvents(state.events)),
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

      emit(
        state.copyWith(
          events: [...state.events, ...newRecurringEvents],
          focusedDayEvents: _filterFocusedDayEvents([
            ...state.events,
            ...newRecurringEvents,
          ]),
        ),
      );
    });
  }

  List<CalendarEvent> _filterFocusedDayEvents(List<CalendarEvent> events) {
    return events
        .where((e) => e.date.isSameDay(state.focusedDay))
        .fold<Map<String, CalendarEvent>>({}, (map, event) {
          final key = '${event.id}_${event.date}';
          if (!map.containsKey(key)) map[key] = event;
          return map;
        })
        .values
        .toList();
  }
}
