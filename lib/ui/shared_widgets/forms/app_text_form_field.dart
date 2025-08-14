import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/utils/analytics_utils.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/extension/string_extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

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
    this.inputStyle,
    this.minLines,
    this.maxLines,
    this.readOnly = false,
    this.autofocus = false,
    this.inputBorder,
    this.textAlign,
    this.fillColor,
    this.onTap,
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
  final TextStyle? inputStyle;
  final int? minLines;
  final int? maxLines;
  final bool readOnly;
  final bool autofocus;
  final InputBorder? inputBorder;
  final TextAlign? textAlign;
  final Color? fillColor;
  final VoidCallback? onTap;

  @override
  State<AppTextFormField> createState() => _AppTextFormFieldState();
}

class _AppTextFormFieldState extends State<AppTextFormField> {
  String? _errorText;
  late final _focusNode = widget.focusNode ?? FocusNode();
  late final _inputBorder =
      widget.inputBorder ??
      OutlineInputBorder(
        borderRadius: UiConstants.borderRadius,
        borderSide: BorderSide(
          color: context.colorScheme.outline,
          width: UiConstants.borderWidth,
        ),
      );

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

      if (error != null) {
        logEvent(
          name: 'form_validation_error',
          parameters: {
            'user_id': GetIt.I<FirebaseAuth>().currentUser?.uid ?? 'anonymous',
            'field_label':
                (widget.labelText ?? widget.hintText)?.toSnakeCase() ??
                'unknown_field',
            'error_message': error,
            'field_type': widget.keyboardType?.toString() ?? 'text',
          },
        );
      }
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
            Text(
              widget.labelText!,
              style: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextFormField(
            onTap: widget.onTap,
            textAlign: widget.textAlign ?? TextAlign.start,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            controller: widget.controller,
            readOnly: widget.readOnly,
            focusNode: _focusNode,
            validator: _validator,
            obscuringCharacter: '*',
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            onFieldSubmitted: widget.onSubmitted,
            style: widget.inputStyle ?? context.textTheme.bodyMedium,
            autofillHints: widget.autofillHints,
            inputFormatters: widget.inputFormatters,
            minLines: widget.minLines,
            maxLines: widget.maxLines ?? 1,
            decoration: InputDecoration(
              border: _inputBorder,
              enabledBorder: _inputBorder,
              focusedBorder: _inputBorder,
              errorBorder: _inputBorder,
              focusedErrorBorder: _inputBorder,
              disabledBorder: _inputBorder,
              fillColor: widget.fillColor,
              hintText: widget.hintText,
              hintStyle: (widget.inputStyle ?? context.textTheme.bodyMedium)
                  ?.copyWith(
                    color: context.colorScheme.onSurface.withAlpha(120),
                  ),
              errorText: '',
              errorStyle: const TextStyle(fontSize: 0),
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
                          fontWeight: FontWeight.w600,
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
