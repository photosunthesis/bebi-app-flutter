import 'dart:async';

import 'package:bebi_app/config/firebase_services.dart';
import 'package:bebi_app/data/repositories/calendar_events_repository.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_event_details_cubit.freezed.dart';
part 'calendar_event_details_state.dart';

class CalendarEventDetailsCubit extends Cubit<CalendarEventDetailsState> {
  CalendarEventDetailsCubit(
    this._calendarEventsRepository,
    this._firebaseAnalytics,
    this._firebaseAuth,
  ) : super(const CalendarEventDetailsState.data());

  final CalendarEventsRepository _calendarEventsRepository;
  final FirebaseAnalytics _firebaseAnalytics;
  final FirebaseAuth _firebaseAuth;

  Future<void> deleteCalendarEvent(
    String calendarEventId,
    bool deleteAllEvents,
  ) async {
    await guard(
      () async {
        emit(const CalendarEventDetailsState.loading());

        if (deleteAllEvents) {
          await _calendarEventsRepository.deleteById(calendarEventId);
        } else {
          // TODO Handle deleting of all recurring events until current one
        }

        emit(const CalendarEventDetailsState.deleteSuccess());

        unawaited(
          _firebaseAnalytics.logEvent(
            name: 'delete_calendar_event',
            parameters: <String, Object>{
              'event_id': calendarEventId,
              'user_id': _firebaseAuth.currentUser!.uid,
            },
          ),
        );
      },
      onError: (error, _) {
        emit(CalendarEventDetailsState.error(error.toString()));
      },
    );
  }
}
