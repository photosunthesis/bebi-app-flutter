import 'dart:async';

import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:flutter/cupertino.dart';

class AppTextDropdownPicker<T> extends StatefulWidget {
  const AppTextDropdownPicker({
    super.key,
    required this.items,
    required this.labelBuilder,
    this.controller,
    this.hintText,
    this.onChanged,
    this.selectedIndex,
    this.height = 200,
  });

  final List<T> items;
  final String Function(T item) labelBuilder;
  final TextEditingController? controller;
  final String? hintText;
  final void Function(T item)? onChanged;
  final int? selectedIndex;
  final double height;

  @override
  State<AppTextDropdownPicker<T>> createState() =>
      _AppTextDropdownPickerState<T>();
}

class _AppTextDropdownPickerState<T> extends State<AppTextDropdownPicker<T>> {
  late TextEditingController _controller;
  late FixedExtentScrollController _scrollController;
  late int _selectedIndex;
  T? _selectedItem;
  bool _isPickerVisible = false;
  Timer? _blinkTimer;
  bool _isBlinkingPrimary = false;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();

    _selectedIndex = widget.selectedIndex ?? widget.items.length + 1;
    if (widget.selectedIndex != null) {
      _selectedItem = widget.items[widget.selectedIndex!];
      _updateControllerText();
    }

    _scrollController = FixedExtentScrollController(
      initialItem: _selectedIndex,
    );
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _closeTimer?.cancel();
    if (widget.controller == null) _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemChanged(int index) {
    _closeTimer?.cancel();
    _closeTimer = null;
    setState(() {
      _selectedIndex = index;
      _selectedItem = widget.items[index];
      _updateControllerText();
    });
    widget.onChanged?.call(_selectedItem as T);
    _closeTimer = Timer.periodic(3.seconds, (timer) {
      setState(() => _isPickerVisible = false);
      _stopBlinking();
    });
  }

  void _onPickerDone() {
    setState(() => _isPickerVisible = false);
    _stopBlinking();
    _closeTimer?.cancel();
  }

  void _startBlinking() {
    _blinkTimer?.cancel();
    _blinkTimer = null;
    _blinkTimer = Timer.periodic(400.milliseconds, (timer) {
      setState(() => _isBlinkingPrimary = !_isBlinkingPrimary);
    });
  }

  void _stopBlinking() {
    _blinkTimer?.cancel();
    setState(() => _isBlinkingPrimary = false);
  }

  void _updateControllerText() {
    if (_selectedItem != null) {
      _controller.text = widget.labelBuilder(_selectedItem as T);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: 120.milliseconds,
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
          onTap: () {
            setState(() => _isPickerVisible = !_isPickerVisible);
            if (_isPickerVisible) {
              _startBlinking();
            } else {
              _stopBlinking();
              _onPickerDone();
            }
          },
          inputStyle: context.textTheme.bodyMedium?.copyWith(
            color: _isPickerVisible && _isBlinkingPrimary
                ? context.colorScheme.secondary
                : context.colorScheme.primary,
          ),
          textAlign: TextAlign.end,
          controller: _controller,
          readOnly: true,
        ),
        Positioned(
          top: 14,
          left: 12,
          child: Text(
            widget.hintText ?? context.l10n.selectItem,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withAlpha(120),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerContainer() {
    return AnimatedSwitcher(
      duration: 120.milliseconds,
      child: _isPickerVisible ? _buildPicker() : const SizedBox.shrink(),
    );
  }

  Widget _buildPicker() {
    return SizedBox(
      key: const ValueKey('picker'),
      height: widget.height,
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
    );
  }
}
