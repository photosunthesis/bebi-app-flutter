import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// TODO Add dark theme support

abstract class AppTheme {
  static final instance = ThemeData.light(useMaterial3: false).copyWith(
    scaffoldBackgroundColor: _colorScheme.surface,
    colorScheme: _colorScheme,
    textTheme: _textTheme,
    primaryTextTheme: _primaryTextTheme,
    inputDecorationTheme: _inputDecorationTheme,
    elevatedButtonTheme: _elevatedButtonTheme,
    textButtonTheme: _textButtonTheme,
    appBarTheme: _appBarTheme,
    cardTheme: _cardTheme,
    floatingActionButtonTheme: _floatingActionButtonTheme,
    iconButtonTheme: _iconButtonTheme,
  );

  static const _colorScheme = ColorScheme.light(
    primary: AppColors.stone900,
    secondary: AppColors.stone500,
    tertiary: AppColors.stone700,
    surface: AppColors.stone50,
    surfaceContainerHighest: AppColors.stone900,
    error: AppColors.red,

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
          foregroundColor: _colorScheme.onPrimary,
          shape: const RoundedRectangleBorder(
            borderRadius: UiConstants.borderRadius,
          ),
          minimumSize: const Size.fromHeight(44),
          textStyle: _textTheme.labelLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ).copyWith(
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: WidgetStatePropertyAll(_colorScheme.shadow),
          backgroundColor: WidgetStatePropertyAll(_colorScheme.primary),
          foregroundColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? _colorScheme.onPrimary.withAlpha(150)
                : _colorScheme.onPrimary,
          ),
        ),
  );

  static final _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      backgroundColor: _colorScheme.onPrimary,
      foregroundColor: _colorScheme.primary,
      textStyle: _textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      // padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      // maximumSize: const Size.fromHeight(24),
      shape: RoundedRectangleBorder(
        borderRadius: UiConstants.borderRadius,
        side: BorderSide(
          color: _colorScheme.onSecondary,
          width: UiConstants.borderWidth,
        ),
      ),
    ),
  );

  static final _iconButtonTheme = IconButtonThemeData(
    style: IconButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      backgroundColor: _colorScheme.onPrimary,
      foregroundColor: _colorScheme.primary,
      // padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      // maximumSize: const Size.fromHeight(24),
      side: BorderSide(
        color: _colorScheme.onSecondary,
        width: UiConstants.borderWidth,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: UiConstants.borderRadius,
      ),
    ),
  );

  static final _appBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    backgroundColor: _colorScheme.surface,
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
}
