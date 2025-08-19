part of 'calendar_event_form_cubit.dart';

sealed class CalendarEventFormState {
  const CalendarEventFormState();
}

class CalendarEventFormLoadingState extends CalendarEventFormState {
  const CalendarEventFormLoadingState();
}

class CalendarEventFormLoadedState extends CalendarEventFormState {
  const CalendarEventFormLoadedState(this.calendarEvent, this.currentUserId);
  final CalendarEvent? calendarEvent;
  final String currentUserId;
  bool get eventWasCreatedByCurrentUser =>
      calendarEvent == null || calendarEvent?.createdBy == currentUserId;
}

class CalendarEventFormErrorState extends CalendarEventFormState {
  const CalendarEventFormErrorState(this.error);
  final String error;
}

class CalendarEventFormSuccessState extends CalendarEventFormState {
  const CalendarEventFormSuccessState();
}
