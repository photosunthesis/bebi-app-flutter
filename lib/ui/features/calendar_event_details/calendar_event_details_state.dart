part of 'calendar_event_details_cubit.dart';

sealed class CalendarEventDetailsState {
  const CalendarEventDetailsState();
}

class CalendarEventDetailsLoadingState extends CalendarEventDetailsState {
  const CalendarEventDetailsLoadingState();
}

class CalendarEventDetailsLoadedState extends CalendarEventDetailsState {
  const CalendarEventDetailsLoadedState();
}

class CalendarEventDetailsErrorState extends CalendarEventDetailsState {
  const CalendarEventDetailsErrorState(this.error);
  final String error;
}

class CalendarEventDetailsDeleteSuccessState extends CalendarEventDetailsState {
  const CalendarEventDetailsDeleteSuccessState();
}
