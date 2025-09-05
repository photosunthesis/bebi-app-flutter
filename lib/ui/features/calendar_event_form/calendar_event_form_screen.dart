import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/ui/features/calendar_event_form/calendar_event_form_cubit.dart';
import 'package:bebi_app/ui/features/calendar_event_form/widgets/calendar_event_form.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_app_bar.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class CalendarEventFormScreen extends StatefulWidget {
  const CalendarEventFormScreen({
    this.calendarEvent,
    this.selectedDate,
    super.key,
  });

  final CalendarEvent? calendarEvent;
  final DateTime? selectedDate;

  @override
  State<CalendarEventFormScreen> createState() =>
      _CalendarEventFormScreenState();
}

class _CalendarEventFormScreenState extends State<CalendarEventFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarEventFormCubit>().initialize(
        widget.calendarEvent,
        widget.selectedDate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CalendarEventFormCubit, CalendarEventFormState>(
      listener: (context, state) {
        if (state.error != null) {
          context.showSnackbar(state.error!, type: SnackbarType.error);
        }

        if (state.saveSuccessful) {
          context.goNamed(
            AppRoutes.calendar,
            queryParameters: {'loadEventsFromServer': 'true'},
          );
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: CalendarEventForm(formKey: _formKey),
      ),
    );
  }

  AppBar _buildAppBar() {
    return MainAppBar.build(
      context,
      actions: [_buildColorSwitcherMenu(), const SizedBox(width: 8)],
    );
  }

  Widget _buildColorSwitcherMenu() {
    return BlocBuilder<CalendarEventFormCubit, CalendarEventFormState>(
      builder: (context, state) {
        return PopupMenuButton<EventColor>(
          splashRadius: 0,
          color: context.colorScheme.surface,
          padding: EdgeInsets.zero,
          menuPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: UiConstants.borderRadius,
            side: BorderSide(
              color: context.colorScheme.outline,
              width: UiConstants.borderWidth,
            ),
          ),
          elevation: 0,
          offset: const Offset(0, 50),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            width: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: UiConstants.borderRadius,
                border: Border.all(
                  color: context.colorScheme.outline,
                  width: UiConstants.borderWidth,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 4),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: state.eventColor.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Icon(Symbols.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
          ),
          onSelected: (value) =>
              context.read<CalendarEventFormCubit>().updateEventColor(value),
          itemBuilder: (_) => EventColor.values
              .map(
                (e) => PopupMenuItem(
                  value: e,
                  height: 36,
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: e.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        e.label,
                        style: context.textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (e == state.eventColor)
                        const Icon(Symbols.check, size: 20),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
