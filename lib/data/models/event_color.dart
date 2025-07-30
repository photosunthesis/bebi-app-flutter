import 'dart:ui';

import 'package:bebi_app/app/theme/app_colors.dart';

enum EventColors {
  black,
  green,
  blue,
  yellow,
  red,
  purple,
  orange;

  Color get color => switch (this) {
    EventColors.black => AppColors.stone600,
    EventColors.green => AppColors.green,
    EventColors.blue => AppColors.blue,
    EventColors.yellow => AppColors.yellow,
    EventColors.red => AppColors.red,
    EventColors.purple => AppColors.purple,
    EventColors.orange => AppColors.orange,
  };
}
