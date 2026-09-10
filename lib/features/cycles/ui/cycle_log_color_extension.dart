import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/features/cycles/domain/entities/cycle_log.dart';
import 'package:material_ui/material_ui.dart';

extension CycleLogColorExtension on CycleLog {
  Color get color => switch (type) {
    LogType.period => AppColors.red,
    LogType.ovulation => AppColors.blue,
    LogType.symptom => AppColors.purple,
    LogType.intimacy => AppColors.purple,
  };
}
