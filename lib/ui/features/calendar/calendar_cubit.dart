import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/repositories/calendar_events_repository.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_state.dart';
part 'calendar_cubit.freezed.dart';

class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit(this._calendarEventsRepository, this._firebaseAuth)
    : super(CalendarState.initial());

  final CalendarEventsRepository _calendarEventsRepository;
  final FirebaseAuth _firebaseAuth;

  Future<void> initialize({bool useCache = true}) async {
    await guard(
      () async {
        emit(state.copyWith(loading: true));

        final events = await _calendarEventsRepository.getByUserId(
          userId: _firebaseAuth.currentUser!.uid,
          startDate: DateTime(
            state.focusedDay.year,
            state.focusedDay.month,
            1, // first day of the month
          ),
          endDate: DateTime(
            state.focusedDay.year,
            state.focusedDay.month + 1,
            0, // last day of the month
          ),
          useCache: useCache,
        );

        emit(
          state.copyWith(
            focusedMonthEvents: events,
            focusedDayEvents: _sortEvents(
              events.where((e) => e.date.isSameDay(state.focusedDay)).toList(),
            ),
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

  Future<void> setFocusedDay(DateTime date) async {
    final shouldFetchNewMonth = !state.focusedDay.isSameMonth(date);

    emit(state.copyWith(focusedDay: date));

    if (shouldFetchNewMonth) return initialize(useCache: true);

    emit(
      state.copyWith(
        focusedDayEvents: _sortEvents(
          state.focusedMonthEvents
              .where((e) => e.date.isSameDay(date))
              .toList(),
        ),
      ),
    );
  }

  List<CalendarEvent> _sortEvents(List<CalendarEvent> events) {
    events.sort((a, b) {
      // Sort cycle events first
      if (a.isCycleEvent && !b.isCycleEvent) return -1;
      if (!a.isCycleEvent && b.isCycleEvent) return 1;

      // Sort all-day events first
      if (a.allDay && !b.allDay) return -1;
      if (!a.allDay && b.allDay) return 1;

      // Sort by start time
      return a.startTime.compareTo(b.startTime);
    });

    return events;
  }
}
