import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/data/models/save_changes_dialog_options.dart';
import 'package:bebi_app/ui/features/calendar_event_details/calendar_event_details_cubit.dart';
import 'package:bebi_app/ui/features/calendar_event_details/components/delete_event_bottom_dialog.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_app_bar.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/color_extensions.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:material_symbols_icons/symbols.dart';

class CalendarEventDetailsScreen extends StatefulWidget {
  const CalendarEventDetailsScreen({required this.calendarEvent, super.key});

  final CalendarEvent calendarEvent;

  @override
  State<CalendarEventDetailsScreen> createState() =>
      _CalendarEventDetailsScreenState();
}

class _CalendarEventDetailsScreenState
    extends State<CalendarEventDetailsScreen> {
  late final CalendarEvent _event = widget.calendarEvent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<CalendarEventDetailsCubit>().initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  AppBar _buildAppBar() {
    return MainAppBar.build(
      context,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child:
              BlocSelector<
                CalendarEventDetailsCubit,
                CalendarEventDetailsState,
                bool
              >(
                selector: (state) => state is CalendarEventDetailsLoadingState,
                builder: (context, loading) {
                  return SizedBox(
                    width: 50,
                    child: OutlinedButton(
                      onPressed: !loading
                          ? () async {
                              await context.pushNamed<CalendarEvent>(
                                AppRoutes.updateCalendarEvent,
                                extra: _event,
                                pathParameters: {'id': _event.id},
                              );
                            }
                          : null,
                      child: Text(context.l10n.editButton.toUpperCase()),
                    ),
                  );
                },
              ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        _buildTitleSection(),
        _buildDateTimeSection(),
        if (_event.notes != null && _event.notes!.isNotEmpty)
          _buildNotesSection(),
        _buildDeleteButton(),
      ],
    );
  }

  Widget _buildTitleSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Text(
          _event.title,
          style: context.primaryTextTheme.headlineMedium?.copyWith(
            color: _event.color.darken(0.15),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    final date = _event.allDay
        ? _event.startDate.toEEEEMMMMdyyyy()
        : _event.startDate.toDateRange(_event.endDate!);

    final dateTimeText =
        _event.repeatRule.frequency == RepeatFrequency.doNotRepeat
        ? date
        : '$date - ${context.l10n.repeats} ${_event.repeatRule.frequency.label.toLowerCase()}';

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      sliver: SliverToBoxAdapter(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Symbols.edit_calendar,
              size: 18,
              color: _event.color.darken(0.2),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(dateTimeText, style: context.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      sliver: SliverToBoxAdapter(
        child: Expanded(
          child: MarkdownBody(
            data: _event.notes!,
            styleSheet: MarkdownStyleSheet(
              p: context.textTheme.bodyMedium,
              h1: context.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              h2: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              h3: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              h4: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              h5: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              h6: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              strong: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              em: context.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Spacer(),
          const SizedBox(height: 32),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(UiConstants.padding),
              child:
                  BlocSelector<
                    CalendarEventDetailsCubit,
                    CalendarEventDetailsState,
                    bool
                  >(
                    selector: (state) =>
                        state is CalendarEventDetailsLoadingState,
                    builder: (context, loading) {
                      return OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.colorScheme.error.darken(),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                        ),
                        onPressed: loading ? null : _onDelete,
                        child: Text(
                          context.l10n.deleteEventButton.toUpperCase(),
                        ),
                      );
                    },
                  ),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Future<void> _onDelete() async {
    final result = await showDeleteEventBottomDialog(
      context,
      widget.calendarEvent,
    );

    if (result == SaveChangesDialogOptions.onlyThisEvent ||
        result == SaveChangesDialogOptions.allFutureEvents) {
      await context.read<CalendarEventDetailsCubit>().deleteCalendarEvent(
        widget.calendarEvent.id,
        deleteAllEvents: result == SaveChangesDialogOptions.allFutureEvents,
        instanceDate: widget.calendarEvent.startDate,
      );

      context.goNamed(
        AppRoutes.calendar,
        queryParameters: {'loadEventsFromServer': 'true'},
      );
    }
  }
}
