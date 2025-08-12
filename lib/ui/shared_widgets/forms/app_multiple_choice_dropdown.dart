import 'dart:async';

import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AppMultipleChoiceDropdown<T> extends StatefulWidget {
  const AppMultipleChoiceDropdown({
    required this.items,
    required this.onChanged,
    required this.hintText,
    required this.itemLabelBuilder,
    this.selectedItems = const [],
    this.controller,
    super.key,
  });

  final List<T> items;
  final ValueChanged<List<T>> onChanged;
  final String hintText;
  final List<T> selectedItems;
  final String Function(T) itemLabelBuilder;
  final TextEditingController? controller;

  @override
  State<AppMultipleChoiceDropdown<T>> createState() =>
      _AppMultipleChoiceDropdownState<T>();
}

class _AppMultipleChoiceDropdownState<T>
    extends State<AppMultipleChoiceDropdown<T>> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  bool _pickerIsVisible = false;
  Timer? _closeTimer;

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _closeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextFormField(),
        if (_pickerIsVisible)
          Container(
            decoration: BoxDecoration(
              borderRadius: UiConstants.borderRadius,
              border: Border.all(
                color: context.colorScheme.outline,
                width: UiConstants.borderWidth,
              ),
            ),
            child: _buildSelection(),
          ),
      ],
    );
  }

  Widget _buildTextFormField() {
    return Stack(
      children: [
        AppTextFormField(
          onTap: () {
            if (!_pickerIsVisible) setState(() => _pickerIsVisible = true);
          },
          controller: _controller,
          inputStyle: context.textTheme.bodyMedium,
          textAlign: TextAlign.end,
          readOnly: true,
        ),
        Positioned(
          top: 14,
          left: 12,
          child: Text(
            widget.hintText,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withAlpha(120),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelection() {
    return Column(
      children: [
        ...widget.items.map((item) {
          final isSelected = widget.selectedItems.contains(item);
          final label = widget.itemLabelBuilder.call(item);
          return InkWell(
            onTap: () => _onItemSelect(item),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: widget.items.last == item
                      ? BorderSide.none
                      : BorderSide(
                          color: context.colorScheme.outline,
                          width: UiConstants.borderWidth,
                        ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(label)),
                  SizedBox(
                    height: 24,
                    child: isSelected ? const Icon(Symbols.check) : null,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _onItemSelect(T item) {
    _closeTimer?.cancel();

    final isSelected = widget.selectedItems.contains(item);
    final newSelectedItems = List<T>.from(widget.selectedItems);

    if (isSelected) {
      newSelectedItems.remove(item);
    } else {
      newSelectedItems.add(item);
    }

    _controller.text = newSelectedItems
        .map((item) => widget.itemLabelBuilder(item).substring(0, 3))
        .join(', ');

    widget.onChanged.call(newSelectedItems);

    _closeTimer = Timer(
      3.seconds,
      () => setState(() => _pickerIsVisible = false),
    );
  }
}
