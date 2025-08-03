import 'package:flutter/material.dart';

abstract class UiConstants {
  static const padding = 18.0;
  static final borderWidth = 0.2;

  static const borderRadiusValue = 8.0;
  static const borderRadiusLargeValue = 12.0;
  static const borderRadius = BorderRadius.all(
    Radius.circular(borderRadiusValue),
  );
  static const borderRadiusLarge = BorderRadius.all(
    Radius.circular(borderRadiusLargeValue),
  );
}
