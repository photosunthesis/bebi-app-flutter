import 'package:bebi_app/ui/shared_widgets/buttons/app_text_button.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/cupertino.dart';

class AppTextDropdownPicker<T> extends StatefulWidget {
  const AppTextDropdownPicker({
    super.key,
    required this.items,
    required this.labelBuilder,
    this.controller,
    this.hintText,
    this.focusNode,
    this.onChanged,
    this.selectedIndex,
    this.height = 200,
  });

  final List<T> items;
  final String Function(T item) labelBuilder;
  final TextEditingController? controller;
  final String? hintText;
  final FocusNode? focusNode;
  final void Function(T item)? onChanged;
  final int? selectedIndex;
  final double height;

  @override
  State<AppTextDropdownPicker<T>> createState() =>
      _AppTextDropdownPickerState<T>();
}

class _AppTextDropdownPickerState<T> extends State<AppTextDropdownPicker<T>> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late FixedExtentScrollController _scrollController;
  late int _selectedIndex;
  T? _selectedItem;
  bool _isPickerVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    _selectedIndex = widget.selectedIndex ?? widget.items.length + 1;
    if (widget.selectedIndex != null) {
      _selectedItem = widget.items[widget.selectedIndex!];
      _updateControllerText();
    }

    _scrollController = FixedExtentScrollController(
      initialItem: _selectedIndex,
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_isPickerVisible) {
        setState(() {
          _isPickerVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    if (widget.controller == null) _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemChanged(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedItem = widget.items[index];
      _updateControllerText();
    });
    widget.onChanged?.call(_selectedItem as T);
  }

  void _onPickerDone() {
    setState(() {
      _isPickerVisible = false;
    });
    _focusNode.unfocus();
  }

  void _updateControllerText() {
    if (_selectedItem != null) {
      _controller.text = widget.labelBuilder(_selectedItem as T);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: 150.milliseconds,
      curve: Curves.easeOutCirc,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildTextFormField(), _buildPickerContainer()],
      ),
    );
  }

  Widget _buildTextFormField() {
    return Stack(
      children: [
        AppTextFormField(
          controller: _controller,
          hintText: widget.hintText,
          readOnly: true,
          focusNode: _focusNode,
        ),
        if (_isPickerVisible)
          Positioned(
            top: 8,
            right: 8,
            child: AppTextButton(text: 'Done', onTap: _onPickerDone),
          ),
      ],
    );
  }

  Widget _buildPickerContainer() {
    return AnimatedSwitcher(
      duration: 150.milliseconds,
      child: _isPickerVisible ? _buildPicker() : const SizedBox.shrink(),
    );
  }

  Widget _buildPicker() {
    return SizedBox(
      key: const ValueKey('picker'),
      height: widget.height,
      child: GestureDetector(
        onTap: _focusNode.requestFocus,
        child: CupertinoTheme(
          data: CupertinoThemeData(
            textTheme: CupertinoTextThemeData(
              pickerTextStyle: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          child: CupertinoPicker(
            scrollController: _scrollController,
            itemExtent: 32,
            onSelectedItemChanged: _onItemChanged,
            selectionOverlay: Container(),
            useMagnifier: true,
            magnification: 1.2,
            diameterRatio: 1.2,
            children: widget.items
                .map(
                  (item) => Center(
                    child: Text(
                      widget.labelBuilder(item),
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
