import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/data/models/save_changes_dialog_options.dart';
import 'package:bebi_app/ui/features/calendar_event_form/calendar_event_form_cubit.dart';
import 'package:bebi_app/ui/features/calendar_event_form/components/date_fields_bottom_dialog.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/modals/options_bottom_dialog.dart';
import 'package:bebi_app/ui/shared_widgets/specialized/sticky_markdown_toolbar.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/color_extensions.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor_markdown/super_editor_markdown.dart';

class CalendarEventForm extends StatefulWidget {
  const CalendarEventForm({required this.formKey, super.key});

  final GlobalKey<FormState> formKey;

  @override
  State<CalendarEventForm> createState() => _CalendarEventFormState();
}

class _CalendarEventFormState extends State<CalendarEventForm> {
  final _docChangeSignal = SignalNotifier();
  final _docLayoutKey = GlobalKey();
  final _composer = MutableDocumentComposer();
  late final _titleController = TextEditingController();
  late final _docEditor = createDefaultDocumentEditor(
    document: _doc,
    composer: _composer,
  );
  late final _doc = MutableDocument.empty();
  late final _docOps = CommonEditorOperations(
    editor: _docEditor,
    document: _doc,
    composer: _composer,
    documentLayoutResolver: () => _docLayoutKey.currentState as DocumentLayout,
  );

  @override
  void initState() {
    super.initState();

    _docEditor.addListener(
      FunctionalEditListener((changeList) {
        _docChangeSignal.notifyListeners();
        final markdown = serializeDocumentToMarkdown(_doc);
        context.read<CalendarEventFormCubit>().updateNotes(markdown);
      }),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _docEditor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CalendarEventFormCubit, CalendarEventFormState>(
      listenWhen: (previous, current) =>
          previous.title != current.title || previous.notes != current.notes,
      listener: (context, state) {
        if (_titleController.text != state.title) {
          _titleController.text = state.title;
        }

        final currentMarkdown = serializeDocumentToMarkdown(_doc);
        if (currentMarkdown != state.notes) {
          final newDoc = deserializeMarkdownToDocument(
            state.notes,
            syntax: MarkdownSyntax.normal,
          );
          // Replace document content
          while (_doc.isNotEmpty) {
            _doc.deleteNodeAt(0);
          }
          for (var i = 0; i < newDoc.length; i++) {
            _doc.insertNodeAt(i, newDoc.getNodeAt(i)!);
          }
        }
      },
      child: Form(
        key: widget.formKey,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildTitleField(),
                _buildDateField(),
                _buildNotesSection(),
                _buildSaveButtonSection(),
              ],
            ),
            _buildStickyMarkdownToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 16, left: 22, right: 22),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            BlocBuilder<CalendarEventFormCubit, CalendarEventFormState>(
              builder: (context, state) {
                return AppTextFormField(
                  autofocus: true,
                  inputBorder: InputBorder.none,
                  controller: _titleController,
                  hintText: context.l10n.newEventHint,
                  textInputAction: TextInputAction.done,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  inputStyle: context.primaryTextTheme.headlineMedium?.copyWith(
                    color: state.eventColor.color.darken(0.15),
                  ),
                  onChanged: (value) =>
                      context.read<CalendarEventFormCubit>().updateTitle(value),
                  maxLines: 3,
                  minLines: 1,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.titleRequired;
                    }
                    return null;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return SliverToBoxAdapter(
      child: BlocBuilder<CalendarEventFormCubit, CalendarEventFormState>(
        builder: (context, state) {
          return InkWell(
            splashFactory: NoSplash.splashFactory,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              DateFieldsBottomDialog.show(
                context,
                startDate: state.startDate,
                endDate: state.endDate,
                allDay: state.allDay,
                onAllDayChanged: (value) =>
                    context.read<CalendarEventFormCubit>().updateAllDay(value),
                repeatRule: state.repeatRule,
                onStartDateChanged: (value) => context
                    .read<CalendarEventFormCubit>()
                    .updateStartDate(value),
                onEndDateChanged: (value) =>
                    context.read<CalendarEventFormCubit>().updateEndDate(value),
                onRepeatRuleChanged: (value) => context
                    .read<CalendarEventFormCubit>()
                    .updateRepeatRule(value),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Symbols.edit_calendar,
                    size: 18,
                    color: state.eventColor.color.darken(0.2),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: AnimatedSize(
                      alignment: Alignment.centerLeft,
                      duration: 120.milliseconds,
                      child: Text(
                        _buildDateFieldText(state),
                        style: context.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _buildDateFieldText(CalendarEventFormState state) {
    final date = state.allDay
        ? state.startDate.toEEEEMMMMdyyyy()
        : state.startDate.toDateRange(
            state.endDate ?? state.startDate.add(1.hours),
          );

    if (state.repeatRule.frequency == RepeatFrequency.doNotRepeat) {
      return date;
    }

    return '$date - ${context.l10n.repeats} ${state.repeatRule.frequency.label.toLowerCase()}';
  }

  Widget _buildNotesSection() {
    return SuperEditor(
      editor: _docEditor,
      componentBuilders: [
        HintComponentBuilder(
          context.l10n.eventNotesHint,
          (context) => context.textTheme.bodyMedium!.copyWith(
            color: context.colorScheme.secondary.withAlpha(100),
          ),
        ),
      ],
      stylesheet: defaultStylesheet.copyWith(
        documentPadding: EdgeInsets.zero,
        addRulesAfter: [
          StyleRule(
            BlockSelector.all,
            (document, node) => {
              Styles.padding: const CascadingPadding.symmetric(vertical: 4),
              Styles.textStyle: context.textTheme.bodyMedium,
            },
          ),
          StyleRule(
            const BlockSelector('header1'),
            (document, node) => {
              Styles.textStyle: context.textTheme.headlineLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            },
          ),
          StyleRule(
            const BlockSelector('header2'),
            (document, node) => {
              Styles.textStyle: context.textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            },
          ),
          StyleRule(
            const BlockSelector('header3'),
            (document, node) => {
              Styles.textStyle: context.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            },
          ),
          StyleRule(
            const BlockSelector('header4'),
            (document, node) => {
              Styles.textStyle: context.textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            },
          ),
          StyleRule(
            const BlockSelector('header5'),
            (document, node) => {
              Styles.textStyle: context.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            },
          ),
          StyleRule(
            const BlockSelector('header6'),
            (document, node) => {
              Styles.textStyle: context.textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            },
          ),
          StyleRule(
            const BlockSelector('b'),
            (document, node) => {
              Styles.textStyle: context.textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            },
          ),
          StyleRule(
            const BlockSelector('i'),
            (document, node) => {
              Styles.textStyle: context.textTheme.bodyMedium!.copyWith(
                fontStyle: FontStyle.italic,
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButtonSection() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          children: [
            const Spacer(),
            const SizedBox(height: 200),
            _buildSaveButton(),
            const SafeArea(child: SizedBox(height: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyMarkdownToolbar() {
    return MultiListenableBuilder(
      listenables: {_docChangeSignal, _composer.selectionNotifier},
      builder: (_) {
        if (_composer.selection == null) return const SizedBox();
        return StickyMarkdownToolbar(
          editor: _docEditor,
          document: _doc,
          composer: _composer,
          commonOps: _docOps,
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return BlocBuilder<CalendarEventFormCubit, CalendarEventFormState>(
      builder: (context, state) {
        return ElevatedButton(
          onPressed: state.isLoading
              ? null
              : () async {
                  if (widget.formKey.currentState?.validate() ?? false) {
                    SaveChangesDialogOptions? saveOption;

                    if (state.originalEvent?.isRecurring == true) {
                      saveOption = await _showConfirmSaveDialog();
                      if (saveOption == SaveChangesDialogOptions.cancel) return;
                    }

                    await context.read<CalendarEventFormCubit>().save(
                      saveOption: saveOption,
                    );
                  }
                },
          child: Text(
            (state.isLoading
                    ? context.l10n.savingButton
                    : context.l10n.saveButton)
                .toUpperCase(),
          ),
        );
      },
    );
  }

  Future<SaveChangesDialogOptions> _showConfirmSaveDialog() async {
    final result = await OptionsBottomDialog.show(
      context,
      title: context.l10n.saveChangesToEventTitle,
      description: context.l10n.saveChangesToEventMessage,
      options: [
        Option(
          text: context.l10n.saveOnlyThisEvent,
          value: SaveChangesDialogOptions.onlyThisEvent,
          style: OptionStyle.primary,
        ),
        Option(
          text: context.l10n.saveAllFutureEvents,
          value: SaveChangesDialogOptions.allFutureEvents,
          style: OptionStyle.primary,
        ),
        Option(
          text: context.l10n.cancelButton,
          value: SaveChangesDialogOptions.cancel,
        ),
      ],
    );

    return result ?? SaveChangesDialogOptions.cancel;
  }
}
