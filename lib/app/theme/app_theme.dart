import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

// TODO Add dark theme support

abstract class AppTheme {
  static final instance = ThemeData.light(useMaterial3: false).copyWith(
    scaffoldBackgroundColor: _colorScheme.surface,
    colorScheme: _colorScheme,
    textTheme: _textTheme,
    primaryTextTheme: _primaryTextTheme,
    inputDecorationTheme: _inputDecorationTheme,
    elevatedButtonTheme: _elevatedButtonTheme,
    outlinedButtonTheme: _outlinedButtonTheme,
    iconButtonTheme: _iconButtonTheme,
    textButtonTheme: _textButtonTheme,
    appBarTheme: _appBarTheme,
    cardTheme: _cardTheme,
    floatingActionButtonTheme: _floatingActionButtonTheme,
    iconTheme: _iconTheme,
    actionIconTheme: _actionIconTheme,
  );

  static final _actionIconTheme = ActionIconThemeData(
    backButtonIconBuilder: (context) => const Icon(Symbols.arrow_back),
    closeButtonIconBuilder: (context) => const Icon(Symbols.close),
  );

  static const _colorScheme = ColorScheme.light(
    primary: AppColors.stone900,
    secondary: AppColors.stone500,
    tertiary: AppColors.stone700,
    surface: AppColors.stone50,
    surfaceContainerHighest: AppColors.stone900,
    error: AppColors.red,
    inversePrimary: AppColors.green,
    outline: AppColors.stone700,

    // Text colors
    onSecondary: AppColors.stone900,
    onSurface: AppColors.stone700,
  );

  static final _textTheme = Typography.material2021().black.apply(
    fontFamily: 'IBMPlexSans',
    bodyColor: _colorScheme.onSurface,
    displayColor: _colorScheme.onSurface,
    decorationColor: _colorScheme.onSurface,
  );

  static final _primaryTextTheme = Typography.material2021().black.apply(
    fontFamily: 'Vidaloka',
    bodyColor: _colorScheme.onSecondary,
    displayColor: _colorScheme.onSecondary,
    decorationColor: _colorScheme.onSecondary,
  );

  static const _inputDecorationBorder = OutlineInputBorder(
    borderRadius: UiConstants.borderRadius,
    borderSide: BorderSide.none,
  );

  static final _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: _colorScheme.onSurface.withAlpha(20),
    border: _inputDecorationBorder,
    errorBorder: _inputDecorationBorder,
    focusedBorder: _inputDecorationBorder,
    focusedErrorBorder: _inputDecorationBorder,
    disabledBorder: _inputDecorationBorder,
    enabledBorder: _inputDecorationBorder,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  );

  static final _elevatedButtonTheme = ElevatedButtonThemeData(
    style:
        ElevatedButton.styleFrom(
          backgroundColor: _colorScheme.primary,
          foregroundColor: _colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: UiConstants.borderRadius,
          ),
          textStyle: _textTheme.labelLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size.fromHeight(42),
        ).copyWith(
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: WidgetStatePropertyAll(_colorScheme.shadow),
          backgroundColor: WidgetStatePropertyAll(_colorScheme.primary),
          foregroundColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? _colorScheme.surface.withAlpha(100)
                : _colorScheme.surface,
          ),
        ),
  );

  static final _outlinedButtonTheme = OutlinedButtonThemeData(
    style:
        OutlinedButton.styleFrom(
          backgroundColor: _colorScheme.surface,
          foregroundColor: _colorScheme.primary,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: _colorScheme.secondary,
              width: UiConstants.borderWidth,
            ),
            borderRadius: UiConstants.borderRadius,
          ),
          textStyle: _textTheme.labelLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        ).copyWith(
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: WidgetStatePropertyAll(_colorScheme.shadow),
          backgroundColor: WidgetStatePropertyAll(_colorScheme.surface),
          foregroundColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? _colorScheme.primary.withAlpha(100)
                : _colorScheme.primary,
          ),
        ),
  );

  static final _textButtonTheme = TextButtonThemeData(
    style:
        TextButton.styleFrom(
          backgroundColor: _colorScheme.surface,
          foregroundColor: _colorScheme.primary,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: _colorScheme.secondary,
              width: UiConstants.borderWidth,
            ),
            borderRadius: UiConstants.borderRadius,
          ),
          textStyle: _textTheme.labelLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ).copyWith(
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: WidgetStatePropertyAll(_colorScheme.shadow),
          backgroundColor: WidgetStatePropertyAll(_colorScheme.surface),
          foregroundColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? _colorScheme.primary.withAlpha(100)
                : _colorScheme.primary,
          ),
        ),
  );

  static final _iconButtonTheme = IconButtonThemeData(
    style:
        IconButton.styleFrom(
          backgroundColor: _colorScheme.surface,
          foregroundColor: _colorScheme.primary,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: AppColors.stone900,
              width: UiConstants.borderWidth,
            ),
            borderRadius: UiConstants.borderRadius,
          ),
          visualDensity: VisualDensity.compact,
        ).copyWith(
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: WidgetStatePropertyAll(_colorScheme.shadow),
          backgroundColor: WidgetStatePropertyAll(_colorScheme.surface),
          foregroundColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? _colorScheme.primary.withAlpha(100)
                : _colorScheme.primary,
          ),
        ),
  );

  static final _appBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    backgroundColor: Colors.transparent,
    foregroundColor: _colorScheme.onSecondary,
    titleTextStyle: _primaryTextTheme.headlineMedium,
  );

  static final _cardTheme = CardThemeData(
    color: _colorScheme.onPrimary,
    shadowColor: _colorScheme.shadow,
    surfaceTintColor: _colorScheme.surface,
    elevation: 0,
  );

  static final _floatingActionButtonTheme = FloatingActionButtonThemeData(
    elevation: 0,
    foregroundColor: _colorScheme.onPrimary,
    backgroundColor: _colorScheme.primary,
  );

  static final _iconTheme = IconThemeData(color: _colorScheme.secondary);
}
