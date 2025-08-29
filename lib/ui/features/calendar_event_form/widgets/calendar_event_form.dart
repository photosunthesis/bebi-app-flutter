import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/ui/features/calendar_event_form/calendar_event_form_cubit.dart';
import 'package:bebi_app/ui/features/calendar_event_form/widgets/date_fields_bottom_dialog.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
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
  const CalendarEventForm({
    required this.formKey,
    required this.title,
    required this.onTitleChanged,
    required this.startDate,
    required this.endDate,
    required this.repeatRule,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onRepeatRuleChanged,
    required this.notes,
    required this.onNotesChanged,
    required this.allDay,
    required this.onAllDayChanged,
    required this.selectedColor,
    required this.onSave,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final ValueChanged<String> onTitleChanged;
  final DateTime startDate;
  final DateTime endDate;
  final RepeatRule repeatRule;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;
  final ValueChanged<RepeatRule> onRepeatRuleChanged;
  final String notes;
  final ValueChanged<String> onNotesChanged;
  final bool allDay;
  final ValueChanged<bool> onAllDayChanged;
  final EventColor selectedColor;
  final VoidCallback onSave;

  @override
  State<CalendarEventForm> createState() => _CalendarEventFormState();
}

class _CalendarEventFormState extends State<CalendarEventForm> {
  late final _startDate = widget.startDate;
  late final _endDate = widget.endDate;
  final _docChangeSignal = SignalNotifier();
  final _docLayoutKey = GlobalKey();
  final _composer = MutableDocumentComposer();
  late final _titleController = TextEditingController(text: widget.title);
  late final _docEditor = createDefaultDocumentEditor(
    document: _doc,
    composer: _composer,
  );
  late final _doc = deserializeMarkdownToDocument(
    widget.notes,
    syntax: MarkdownSyntax.normal,
  );
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
        widget.onNotesChanged(markdown);
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
    return Form(
      key: widget.formKey,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildTitleField(),
              _buildDateField(),
              _buildNotesSection(),
              SliverFillRemaining(
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
              ),
            ],
          ),
          _buildStickyMarkdownToolbar(),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 16, left: 22, right: 22),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            AppTextFormField(
              autofocus: true,
              inputBorder: InputBorder.none,
              controller: _titleController,
              hintText: context.l10n.newEventHint,
              textInputAction: TextInputAction.done,
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.zero,
              inputStyle: context.primaryTextTheme.headlineMedium?.copyWith(
                color: widget.selectedColor.color.darken(0.15),
              ),
              onChanged: widget.onTitleChanged,
              maxLines: 3,
              minLines: 1,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.l10n.titleRequired;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return SliverToBoxAdapter(
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          DateFieldsBottomDialog.show(
            context,
            startDate: _startDate,
            endDate: _endDate,
            allDay: widget.allDay,
            onAllDayChanged: widget.onAllDayChanged,
            repeatRule: widget.repeatRule,
            onStartDateChanged: widget.onStartDateChanged,
            onEndDateChanged: widget.onEndDateChanged,
            onRepeatRuleChanged: widget.onRepeatRuleChanged,
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
                color: widget.selectedColor.color.darken(0.2),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: AnimatedSize(
                  alignment: Alignment.centerLeft,
                  duration: 120.milliseconds,
                  child: Text(
                    _buildDateFieldText(),
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildDateFieldText() {
    final date = widget.allDay
        ? _startDate.toEEEEMMMMdyyyy()
        : _startDate.toDateRange(_endDate);

    if (widget.repeatRule.frequency == RepeatFrequency.doNotRepeat) {
      return date;
    }

    return '$date - ${context.l10n.repeats} ${widget.repeatRule.frequency.label.toLowerCase()}';
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
    return BlocSelector<CalendarEventFormCubit, CalendarEventFormState, bool>(
      selector: (state) => state is CalendarEventFormLoadingState,
      builder: (context, loading) {
        return ElevatedButton(
          onPressed: widget.onSave,
          child: Text(
            (loading ? context.l10n.savingButton : context.l10n.saveButton)
                .toUpperCase(),
          ),
        );
      },
    );
  }
}
