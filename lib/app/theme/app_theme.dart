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
    bottomNavigationBarTheme: _bottomNavigationBarTheme,
  );

  static const _colorScheme = ColorScheme.light(
    primary: AppColors.purple,
    onPrimary: Colors.white,
    secondary: AppColors.teal,
    tertiary: AppColors.pink,
    secondaryContainer: AppColors.yellow,
    surface: AppColors.grayscale,
    shadow: Colors.black26,
    error: AppColors.red,

    // Text colors
    onSecondary: AppColors.titleText,
    onSurface: AppColors.bodyText,
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

  static final _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: _colorScheme.onPrimary,
    border: OutlineInputBorder(
      borderRadius: UiConstants.defaultBorderRadius,
      borderSide: BorderSide.none,
    ),
  );

  static final _elevatedButtonTheme = ElevatedButtonThemeData(
    style:
        ElevatedButton.styleFrom(
          backgroundColor: _colorScheme.primary,
          foregroundColor: _colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: UiConstants.defaultBorderRadius,
          ),
          minimumSize: const Size.fromHeight(48),
          textStyle: _textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w600, fontSize: 16)
              .copyWith(),
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
      textStyle: _textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(
        borderRadius: UiConstants.defaultBorderRadius,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
    ),
  );

  static final _appBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    backgroundColor: _colorScheme.surface,
    foregroundColor: _colorScheme.onSecondary,
    titleTextStyle: _primaryTextTheme.titleLarge?.copyWith(fontSize: 24),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );

  static final _bottomNavigationBarTheme = BottomNavigationBarThemeData(
    backgroundColor: _colorScheme.onPrimary,
    selectedItemColor: _colorScheme.primary,
    unselectedItemColor: _colorScheme.onSurface.withAlpha(150),
    selectedLabelStyle: _textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: _textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
  );
}
