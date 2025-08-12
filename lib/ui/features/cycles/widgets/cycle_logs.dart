import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class CycleLogs extends StatefulWidget {
  const CycleLogs({super.key});

  @override
  State<CycleLogs> createState() => _CycleLogsState();
}

class _CycleLogsState extends State<CycleLogs> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Logs', style: context.primaryTextTheme.titleLarge),
          const SizedBox(height: 18),
          _buildPeriodSection(),
          const SizedBox(height: 16),
          _buildOtherDataSection(),
        ],
      ),
    );
  }

  Widget _buildPeriodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Period'.toUpperCase(),
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: context.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => context.pushNamed(AppRoutes.logMenstrualCycle),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.red.withAlpha(60),
              borderRadius: UiConstants.borderRadius,
              border: Border.all(
                color: AppColors.red.darken(0.4),
                width: UiConstants.borderWidth,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menstrual Flow',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.red.darken(0.4),
                  ),
                ),
                Icon(Symbols.add_2, size: 16, color: AppColors.red.darken(0.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Other logs'.toUpperCase(),
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: context.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () {},
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.purple.withAlpha(50),
              borderRadius: UiConstants.borderRadius,
              border: Border.all(
                color: AppColors.purple.darken(0.4),
                width: UiConstants.borderWidth,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Symptoms',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: AppColors.purple.darken(0.4),
                        ),
                      ),
                      Icon(
                        Symbols.add_2,
                        size: 16,
                        color: AppColors.purple.darken(0.4),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Divider(
                    color: AppColors.purple.darken(0.4),
                    height: UiConstants.borderWidth,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sexual Activity',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: AppColors.purple.darken(0.4),
                        ),
                      ),
                      Icon(
                        Symbols.add_2,
                        size: 16,
                        color: AppColors.purple.darken(0.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
