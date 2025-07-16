import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit() : super(CalendarState.initial());

  void setFocusedDay(DateTime date) {
    emit(state.copyWith(focusedDay: date));
  }
}
