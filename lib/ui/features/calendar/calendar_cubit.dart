import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/repositories/calendar_events_repository.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit(this._calendarEventsRepository, this._firebaseAuth)
    : super(CalendarState.initial());

  final CalendarEventsRepository _calendarEventsRepository;
  final FirebaseAuth _firebaseAuth;

  Future<void> initialize() async {
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
        );
        emit(
          state.copyWith(
            focusedMonthEvents: events,
            focusedDayEvents: events
                .where((e) => e.date.isSameDay(state.focusedDay))
                .toList(),
          ),
        );
      },
      onError: (error, _) {
        emit(state.copyWith(error: error.toString(), didErrorChange: true));
      },
      onComplete: () {
        emit(
          state.copyWith(
            loading: false,
            error: null,
            didErrorChange: state.error != null,
          ),
        );
      },
    );
  }

  Future<void> setFocusedDay(DateTime date) async {
    final shouldInitialize = state.focusedDay.isSameMonth(date);
    emit(state.copyWith(focusedDay: date));
    if (shouldInitialize) return initialize();
    emit(
      state.copyWith(
        focusedDayEvents: state.focusedMonthEvents
            .where((e) => e.date.isSameDay(date))
            .toList(),
      ),
    );
  }
}
