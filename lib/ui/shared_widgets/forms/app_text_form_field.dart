import 'package:bebi_app/ui/shared_widgets/shadow_container.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextFormField extends StatefulWidget {
  const AppTextFormField({
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
    this.autofillHints,
    this.inputFormatters,
    super.key,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextFormField> createState() => _AppTextFormFieldState();
}

class _AppTextFormFieldState extends State<AppTextFormField> {
  late final _focusNode = widget.focusNode ?? FocusNode();

  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _errorText != null) {
        setState(() => _errorText = null);
      }
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  String? _validator(String? value) {
    final error = widget.validator?.call(value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _errorText = error);
    });
    return error;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: 300.milliseconds,
      curve: Curves.easeOutCirc,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.labelText != null) ...[
            Text(widget.labelText!, style: context.textTheme.labelLarge),
            const SizedBox(height: 8),
          ],
          ShadowContainer(
            child: TextFormField(
              enabled: widget.enabled,
              controller: widget.controller,
              focusNode: _focusNode,
              validator: _validator,
              obscuringCharacter: '*',
              textInputAction: widget.textInputAction,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              onFieldSubmitted: widget.onSubmitted,
              style: context.textTheme.bodyMedium,
              autofillHints: widget.autofillHints,
              inputFormatters: widget.inputFormatters,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurface.withAlpha(120),
                ),
                errorText: '',
                errorStyle: const TextStyle(fontSize: 0),
              ),
            ),
          ),
          AnimatedOpacity(
            duration: 300.milliseconds,
            curve: Curves.easeOutCirc,
            opacity: _errorText != null ? 1.0 : 0.0,
            child: SizedBox(
              height: _errorText != null ? 32 : 0,
              child: _errorText != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _errorText!,
                        key: ValueKey(_errorText),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.error,
                          letterSpacing: 0,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
