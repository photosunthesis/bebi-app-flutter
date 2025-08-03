import 'dart:ui';

import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/constants/hive_constants.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'event_color.g.dart';

@HiveType(typeId: HiveTypeIds.eventColors)
enum EventColors {
  @HiveField(0)
  black,
  @HiveField(1)
  green,
  @HiveField(2)
  blue,
  @HiveField(3)
  yellow,
  @HiveField(4)
  pink,
  @HiveField(5)
  orange,
  @HiveField(6)
  red;

  Color get color => switch (this) {
    EventColors.black => AppColors.stone600,
    EventColors.green => AppColors.green,
    EventColors.blue => AppColors.blue,
    EventColors.yellow => AppColors.yellow,
    EventColors.pink => AppColors.pink,
    EventColors.orange => AppColors.orange,
    EventColors.red => AppColors.red,
  };
}
