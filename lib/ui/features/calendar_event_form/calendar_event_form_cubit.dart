import 'dart:async';

import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/data/models/save_changes_dialog_options.dart';
import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:bebi_app/data/repositories/calendar_events_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:bebi_app/utils/mixins/analytics_mixin.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'calendar_event_form_state.dart';

@injectable
class CalendarEventFormCubit extends Cubit<CalendarEventFormState>
    with GuardMixin, AnalyticsMixin {
  CalendarEventFormCubit(
    this._calendarEventsRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
  ) : super(
        CalendarEventFormState(
          title: '',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(10.minutes),
          allDay: false,
          eventColor: EventColor.black,
          repeatRule: const RepeatRule(frequency: RepeatFrequency.doNotRepeat),
          notes: '',
          currentUserId: '',
        ),
      );

  final CalendarEventsRepository _calendarEventsRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;

  void initialize(CalendarEvent? calendarEvent, DateTime? selectedDate) {
    final currentUserId = _firebaseAuth.currentUser!.uid;
    final now = DateTime.now();
    final defaultStart = selectedDate ?? now;

    emit(
      state.copyWith(
        title: calendarEvent?.title ?? '',
        startDate: calendarEvent?.startDate ?? defaultStart,
        endDate: calendarEvent?.endDate ?? defaultStart.add(10.minutes),
        allDay: calendarEvent?.allDay ?? false,
        eventColor: calendarEvent?.eventColor ?? EventColor.black,
        repeatRule:
            calendarEvent?.repeatRule ??
            const RepeatRule(frequency: RepeatFrequency.doNotRepeat),
        notes: calendarEvent?.notes ?? '',
        currentUserId: currentUserId,
        originalEvent: calendarEvent,
        isInitialized: true,
        // ignore: avoid_redundant_argument_values
        error: null,
        saveSuccessful: false,
      ),
    );

    logEvent(
      name: 'calendar_event_form_opened',
      parameters: {
        'is_editing': calendarEvent != null,
        'is_recurring_event': calendarEvent?.isRecurring ?? false,
      },
    );
  }

  void updateTitle(String title) {
    emit(state.copyWith(title: title));
  }

  void updateStartDate(DateTime startDate) {
    emit(state.copyWith(startDate: startDate));
  }

  void updateEndDate(DateTime endDate) {
    emit(state.copyWith(endDate: endDate));
  }

  void updateAllDay(bool allDay) {
    emit(state.copyWith(allDay: allDay));
  }

  void updateEventColor(EventColor eventColor) {
    emit(state.copyWith(eventColor: eventColor));
  }

  void updateRepeatRule(RepeatRule repeatRule) {
    emit(state.copyWith(repeatRule: repeatRule));
  }

  void updateNotes(String notes) {
    emit(state.copyWith(notes: notes));
  }

  Future<void> save({
    SaveChangesDialogOptions? saveOption,
    DateTime? instanceDate,
  }) async {
    await guard(
      () async {
        // ignore: avoid_redundant_argument_values
        emit(state.copyWith(isLoading: true, error: null));

        final isExistingEvent = state.originalEvent?.id.isNotEmpty ?? false;
        final isRecurringEvent = state.originalEvent?.isRecurring ?? false;
        final partnership = await _userPartnershipsRepository.getByUserId(
          state.currentUserId,
        );

        if (isExistingEvent && isRecurringEvent && instanceDate != null) {
          assert(
            saveOption != null,
            'saveOption must not be null when handling recurring events',
          );
          await _handleRecurringSave(
            baseEvent: state.originalEvent!,
            saveOption: saveOption!,
            instanceDate: instanceDate,
            partnership: partnership!,
          );
        } else {
          await _handleRegularSave(partnership: partnership!);
        }

        logEvent(
          name: isExistingEvent
              ? 'calendar_event_updated'
              : 'calendar_event_created',
          parameters: {
            'event_type': state.allDay ? 'all_day' : 'timed',
            'has_repeat':
                state.repeatRule.frequency != RepeatFrequency.doNotRepeat,
            'repeat_frequency': state.repeatRule.frequency.name,
            'has_notes': state.notes.isNotEmpty,
            'event_color': state.eventColor.name,
          },
        );

        emit(state.copyWith(isLoading: false, saveSuccessful: true));
      },
      onError: (error, _) {
        emit(state.copyWith(isLoading: false, error: error.toString()));
      },
    );
  }

  Future<void> _handleRegularSave({
    required UserPartnership partnership,
  }) async {
    await _calendarEventsRepository.createOrUpdate(
      CalendarEvent(
        id: state.originalEvent?.id ?? '',
        title: state.title,
        startDate: state.startDate,
        endDate: state.allDay ? null : state.endDate,
        allDay: state.allDay,
        notes: state.notes.isEmpty ? null : state.notes,
        repeatRule: state.repeatRule,
        eventColor: state.eventColor,
        createdBy: state.originalEvent?.createdBy ?? state.currentUserId,
        updatedBy: state.currentUserId,
        users: partnership.users,
        createdAt: state.originalEvent?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _handleRecurringSave({
    required CalendarEvent baseEvent,
    required SaveChangesDialogOptions saveOption,
    required DateTime instanceDate,
    required UserPartnership partnership,
  }) async {
    await switch (saveOption) {
      SaveChangesDialogOptions.onlyThisEvent => _handleSaveOnlyThisEvent(
        baseEvent: baseEvent,
        instanceDate: instanceDate,
        partnership: partnership,
      ),
      SaveChangesDialogOptions.allFutureEvents => _handleSaveAllFutureEvents(
        baseEvent: baseEvent,
        instanceDate: instanceDate,
        partnership: partnership,
      ),
      SaveChangesDialogOptions.cancel => null,
    };
  }

  Future<void> _handleSaveOnlyThisEvent({
    required CalendarEvent baseEvent,
    required DateTime instanceDate,
    required UserPartnership partnership,
  }) async {
    if (baseEvent.startDate.isSameDay(instanceDate)) {
      final nextOccurrenceDate = _getNextOccurrence(baseEvent);
      if (nextOccurrenceDate != null) {
        final updatedBaseEvent = baseEvent.copyWith(
          startDate: _updateTimeToNewDate(
            baseEvent.startDate,
            nextOccurrenceDate,
          ),
          endDate: baseEvent.endDate != null
              ? _updateTimeToNewDate(baseEvent.endDate!, nextOccurrenceDate)
              : null,
        );
        await _calendarEventsRepository.createOrUpdate(updatedBaseEvent);
      } else {
        await _calendarEventsRepository.deleteById(baseEvent.id);
      }
    } else {
      final updatedExcludedDates = Set<DateTime>.from(
        baseEvent.repeatRule.excludedDates ?? [],
      )..add(instanceDate);

      final updatedBaseEvent = baseEvent.copyWith(
        repeatRule: baseEvent.repeatRule.copyWith(
          excludedDates: updatedExcludedDates.toList(),
        ),
      );
      await _calendarEventsRepository.createOrUpdate(updatedBaseEvent);
    }

    final newSingleEvent = CalendarEvent(
      id: '',
      title: state.title,
      startDate: state.startDate,
      endDate: state.allDay ? null : state.endDate,
      allDay: state.allDay,
      notes: state.notes.isEmpty ? null : state.notes,
      repeatRule: const RepeatRule(frequency: RepeatFrequency.doNotRepeat),
      eventColor: state.eventColor,
      createdBy: state.currentUserId,
      updatedBy: state.currentUserId,
      users: partnership.users,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _calendarEventsRepository.createOrUpdate(newSingleEvent);
  }

  Future<void> _handleSaveAllFutureEvents({
    required CalendarEvent baseEvent,
    required DateTime instanceDate,
    required UserPartnership partnership,
  }) async {
    if (!baseEvent.startDate.isSameDay(instanceDate)) {
      final updatedBaseEvent = baseEvent.copyWith(
        repeatRule: baseEvent.repeatRule.copyWith(
          endDate: instanceDate.subtract(1.days),
        ),
      );
      await _calendarEventsRepository.createOrUpdate(updatedBaseEvent);
    } else {
      await _calendarEventsRepository.deleteById(baseEvent.id);
    }

    final newRecurringEvent = CalendarEvent(
      id: '',
      title: state.title,
      startDate: state.startDate,
      endDate: state.allDay ? null : state.endDate,
      allDay: state.allDay,
      notes: state.notes.isEmpty ? null : state.notes,
      repeatRule: state.repeatRule,
      eventColor: state.eventColor,
      createdBy: state.currentUserId,
      updatedBy: state.currentUserId,
      users: partnership.users,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _calendarEventsRepository.createOrUpdate(newRecurringEvent);
  }

  DateTime? _getNextOccurrence(CalendarEvent event) {
    final currentDate = event.startDate;
    return switch (event.repeatRule.frequency) {
      RepeatFrequency.daily => currentDate.add(1.days),
      RepeatFrequency.weekly => currentDate.add(7.days),
      RepeatFrequency.monthly => DateTime(
        currentDate.year,
        currentDate.month + 1,
        currentDate.day,
      ),
      RepeatFrequency.yearly => DateTime(
        currentDate.year + 1,
        currentDate.month,
        currentDate.day,
      ),
      // TODO Handle other repeat frequencies
      _ => null,
    };
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
}
