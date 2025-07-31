import 'package:bebi_app/ui/shared_widgets/buttons/app_text_button.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AppMultipleChoiceDropdown<T> extends StatefulWidget {
  const AppMultipleChoiceDropdown({
    required this.items,
    required this.onChanged,
    required this.hintText,
    required this.itemLabelBuilder,
    this.selectedItems = const <Never>[],
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

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextFormField(),
        if (_pickerIsVisible) _buildSelection(),
      ],
    );
  }

  Widget _buildTextFormField() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (!_pickerIsVisible) setState(() => _pickerIsVisible = true);
          },
          // AbsorbPointer is required so taps fucking detect
          // (lost 5hrs tryna make this work jfc)
          child: AbsorbPointer(
            child: AppTextFormField(
              controller: _controller,
              hintText: widget.hintText,
              readOnly: true,
            ),
          ),
        ),
        if (_pickerIsVisible)
          Positioned(
            top: 10,
            right: 8,
            child: AppTextButton(
              text: 'Done',
              onTap: () => setState(() => _pickerIsVisible = false),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
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
  }
}
