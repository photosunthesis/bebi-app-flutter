import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/cycles/cycles_cubit.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CycleInsights extends StatelessWidget {
  const CycleInsights({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: 120.milliseconds,
      alignment: Alignment.center,
      curve: Curves.easeOutCirc,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.cycleInsightsTitle,
              style: context.primaryTextTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            BlocBuilder<CyclesCubit, CyclesState>(
              builder: (context, state) {
                return Skeletonizer(
                  textBoneBorderRadius:
                      const TextBoneBorderRadius.fromHeightFactor(0.3),
                  effect: SoldColorEffect(
                    color: context.colorScheme.secondary.withAlpha(40),
                  ),
                  enabled: state.loadingAiSummary,
                  child: MarkdownBody(
                    data: state.aiSummary ?? _getSkeletonFakeData(),
                    styleSheet: MarkdownStyleSheet(
                      p: context.textTheme.bodyMedium?.copyWith(height: 1.4),
                      strong: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      em: context.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getSkeletonFakeData() {
    return '''
Insights about your cycle is displayed like this. Though this one is fake, it gives you an idea of what the insights will look like.

- This is a fake bullet point. Lorem ipsum dolor sit amet, consectetur adipisicing elit. Quisquam, voluptas, sed do eiusmod tempor incididunt ut labore.
- This is another fake bullet point. Ad minim veniam, quis nostrud exercitation ullamco laboris nisi. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi.
- This is the last fake bullet point. Quod, voluptas, sed do eiusmod tempor incididunt ut labore. Et dolore magna aliqua.
''';
  }
}
