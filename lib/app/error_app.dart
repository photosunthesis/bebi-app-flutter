import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/constants/font_family.dart';
import 'package:bebi_app/constants/kaomojis.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/localizations/app_localizations.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:flutter/material.dart';

/// {@template error_app}
///
/// Fallback error app displayed when the main application fails to initialize.
///
/// While production-grade applications rarely experience initialization failures
/// (which typically indicate critical system issues), this fallback exists as a
/// safety net since I'm just a small indie dev making this for me and my girlfriend 🤠
///
/// {@endtemplate}
class ErrorApp extends StatelessWidget {
  /// {@macro error_app}
  ErrorApp({
    required this.error,
    required this.attemptNumber,
    required this.maxAttempts,
    this.canRetry = true,
    this.onRetry,
    super.key,
  });

  final Object error;
  final int attemptNumber;
  final int maxAttempts;
  final bool canRetry;
  final VoidCallback? onRetry;

  final kaomoji = Kaomojis.getRandomFromSadSet();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en', 'US'),
      home: Builder(
        builder: (context) => Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            centerTitle: false,
            title: Text(
              context.l10n.initializationFailed,
              style: context.primaryTextTheme.headlineSmall?.copyWith(
                fontFamily: FontFamily.vidaloka,
                color: AppColors.stone900,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: UiConstants.padding,
                ),
                child: Text(
                  context.l10n.initializationErrorDescription,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontFamily: FontFamily.ibmPlexSans,
                    color: AppColors.stone600,
                  ),
                ),
              ),
            ),
          ),
          body: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorContent(context),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context),
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            kaomoji,
            style: context.textTheme.displayMedium?.copyWith(
              color: AppColors.stone500.withAlpha(80),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Text(
              '${context.l10n.attemptDetails(attemptNumber, maxAttempts)} \n'
              '${context.l10n.errorDetails(error.toString())}',
              style: context.textTheme.bodySmall?.copyWith(
                fontFamily: FontFamily.ibmPlexMono,
                color: AppColors.stone600,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: Colors.white,
      backgroundColor: AppColors.stone900,
      minimumSize: const Size.fromHeight(42),
      textStyle: context.textTheme.titleSmall?.copyWith(
        fontFamily: FontFamily.ibmPlexSans,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: UiConstants.borderRadius,
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canRetry && onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                style: buttonStyle,
                child: Text(context.l10n.retryInitialization.toUpperCase()),
              ),
            if (attemptNumber >= maxAttempts) ...[
              const SizedBox(height: 10),
              Text(
                context.l10n.maxRetryReachedMessage,
                style: context.textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  color: context.colorScheme.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
