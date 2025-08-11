import 'dart:ui';

import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/constants/hive_type_ids.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'event_color.g.dart';

@HiveType(typeId: HiveTypeIds.eventColors)
enum EventColor {
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
    EventColor.black => AppColors.stone600,
    EventColor.green => AppColors.green,
    EventColor.blue => AppColors.blue,
    EventColor.yellow => AppColors.yellow,
    EventColor.pink => AppColors.pink,
    EventColor.orange => AppColors.orange,
    EventColor.red => AppColors.red,
  };
}
