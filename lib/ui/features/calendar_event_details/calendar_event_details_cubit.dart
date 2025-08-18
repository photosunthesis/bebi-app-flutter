import 'dart:async';

import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/data/repositories/calendar_events_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/data/services/recurring_calendar_events_service.dart';
import 'package:bebi_app/utils/analytics_utils.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'calendar_event_details_state.dart';

@injectable
class CalendarEventDetailsCubit extends Cubit<CalendarEventDetailsState> {
  CalendarEventDetailsCubit(
    this._calendarEventsRepository,
    this._recurringCalendarEventsService,
    this._partnershipsRepository,
    this._profileRepository,
    this._firebaseAuth,
  ) : super(const CalendarEventDetailsLoadingState());

  final CalendarEventsRepository _calendarEventsRepository;
  final RecurringCalendarEventsService _recurringCalendarEventsService;
  final UserPartnershipsRepository _partnershipsRepository;
  final UserProfileRepository _profileRepository;
  final FirebaseAuth _firebaseAuth;

  Future<void> initialize() async {
    await guard(
      () async {
        final partnership = await _partnershipsRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
        );

        final profiles = await _profileRepository.getProfilesByIds(
          partnership!.users,
        );

        final userProfile = profiles.firstWhere(
          (e) => e.userId == _firebaseAuth.currentUser!.uid,
        );

        final partnerProfile = profiles.firstWhere(
          (e) => e.userId != _firebaseAuth.currentUser!.uid,
        );

        emit(CalendarEventDetailsLoadedState(userProfile, partnerProfile));
      },
      onError: (error, _) {
        emit(CalendarEventDetailsErrorState(error.toString()));
      },
    );
  }

  Future<void> deleteCalendarEvent(
    String calendarEventId, {
    required bool deleteAllEvents,
    required DateTime instanceDate,
  }) async {
    await guard(
      () async {
        emit(const CalendarEventDetailsLoadingState());

        final baseEvent = await _calendarEventsRepository.getById(
          calendarEventId,
        );

        if (deleteAllEvents) {
          await _handleDeleteAllEvents(baseEvent!, instanceDate);
        } else {
          await _handleDeleteSingleEvent(baseEvent!, instanceDate);
        }

        emit(const CalendarEventDetailsDeleteSuccessState());

        AnalyticsUtils.logEvent(
          name: 'calendar_event_deleted',
          parameters: {
            'user_id': _firebaseAuth.currentUser!.uid,
            'event_id': calendarEventId,
            'delete_type': deleteAllEvents ? 'all_events' : 'single_event',
            'is_recurring_event': baseEvent.isRecurring,
            'event_date': instanceDate.toIso8601String(),
          },
        );
      },
      onError: (error, _) {
        emit(CalendarEventDetailsErrorState(error.toString()));
      },
    );
  }

  Future<void> _handleDeleteAllEvents(
    CalendarEvent baseEvent,
    DateTime instanceDate,
  ) async {
    if (baseEvent.date.isSameDay(instanceDate)) {
      await _calendarEventsRepository.deleteById(baseEvent.id);
      _recurringCalendarEventsService.removeEventFromCache(
        baseEvent.id,
        instanceDate,
      );
    } else {
      final updatedBaseEvent = baseEvent.copyWith(
        repeatRule: baseEvent.repeatRule.copyWith(
          endDate: instanceDate.subtract(1.days),
        ),
      );

      await _calendarEventsRepository.createOrUpdate(updatedBaseEvent);
      _recurringCalendarEventsService.updateEventInCache(updatedBaseEvent);
    }
  }

  Future<void> _handleDeleteSingleEvent(
    CalendarEvent baseEvent,
    DateTime instanceDate,
  ) async {
    if (baseEvent.repeatRule.frequency == RepeatFrequency.doNotRepeat) {
      await _calendarEventsRepository.deleteById(baseEvent.id);
      _recurringCalendarEventsService.removeEventFromCache(
        baseEvent.id,
        instanceDate,
      );
      return;
    }

    if (baseEvent.date.isSameDay(instanceDate)) {
      await _updateToNextOccurrence(baseEvent);
    } else {
      await _excludeInstanceDate(baseEvent, instanceDate);
    }

    _recurringCalendarEventsService.updateEventInCache(baseEvent);
  }

  Future<void> _updateToNextOccurrence(CalendarEvent baseEvent) async {
    final nextOccurrence = _recurringCalendarEventsService.getNextOccurrence(
      baseEvent.date,
      baseEvent.repeatRule,
    );

    final updatedEvent = baseEvent.copyWith(
      date: nextOccurrence,
      startTime: _updateTimeToNewDate(baseEvent.startTime, nextOccurrence),
      endTime: baseEvent.endTime != null
          ? _updateTimeToNewDate(baseEvent.endTime!, nextOccurrence)
          : null,
    );

    await _calendarEventsRepository.createOrUpdate(updatedEvent);
  }

  DateTime _updateTimeToNewDate(DateTime time, DateTime newDate) {
    return DateTime(
      newDate.year,
      newDate.month,
      newDate.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _excludeInstanceDate(
    CalendarEvent baseEvent,
    DateTime instanceDate,
  ) async {
    final updatedExcludedDates = Set<DateTime>.from(
      baseEvent.repeatRule.excludedDates ?? [],
    )..add(instanceDate);

    final updatedEvent = baseEvent.copyWith(
      repeatRule: baseEvent.repeatRule.copyWith(
        excludedDates: updatedExcludedDates.toList(),
      ),
    );

    await _calendarEventsRepository.createOrUpdate(updatedEvent);
  }
}
