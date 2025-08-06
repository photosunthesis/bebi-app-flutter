import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/ui/features/cycles/cycles_cubit.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/color_extensions.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class CycleLogSection extends StatefulWidget {
  const CycleLogSection({super.key});

  @override
  State<CycleLogSection> createState() => _CycleLogSectionState();
}

class _CycleLogSectionState extends State<CycleLogSection> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cycle log',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          BlocSelector<CyclesCubit, CyclesState, CycleLog?>(
            selector: (state) => state.focusedDatePeriodLog,
            builder: (context, cycleLog) {
              return _buildLogCard(
                color: AppColors.red,
                iconData: Symbols.water_drop,
                title: 'Period',
                subtitle: cycleLog == null
                    ? 'No period logs'
                    : 'Period log on ${cycleLog.date.toEEEEMMMMd()} • ${cycleLog.flow!.name} flow',
                onTap: () {},
              );
            },
          ),
          const SizedBox(height: 12),
          _buildLogCard(
            color: AppColors.orange,
            iconData: Symbols.waves,
            rotationAngle: 90,
            title: 'Symptoms',
            subtitle: 'No symptoms experienced',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildLogCard(
            color: AppColors.pink,
            iconData: Symbols.favorite,
            title: 'Intimate activities',
            subtitle: 'No intimate activities logged',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard({
    required Color color,
    required IconData iconData,
    required String title,
    required String subtitle,
    double rotationAngle = 0,
    VoidCallback? onTap,
  }) {
    return Flexible(
      child: InkWell(
        borderRadius: UiConstants.borderRadius,
        splashFactory: InkRipple.splashFactory,
        onTap: onTap,
        child: Container(
          height: 65,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: color.withAlpha(60),
            borderRadius: UiConstants.borderRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color.darken(0.3),
                          ),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: color.darken(0.3),
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  if (onTap != null)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: color.darken(0.3),
                          width: UiConstants.borderWidth,
                        ),
                        borderRadius: UiConstants.borderRadius,
                      ),
                      child: Icon(
                        Symbols.chevron_right,
                        color: color.darken(0.3),
                        size: 20,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
