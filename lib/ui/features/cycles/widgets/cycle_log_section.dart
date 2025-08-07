import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:flutter/material.dart';

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
            'Cycle logs',
            style: context.primaryTextTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Divider(thickness: 0.4, color: context.colorScheme.secondary),
        ],
      ),
    );
  }
}
