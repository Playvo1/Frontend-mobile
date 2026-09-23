import 'package:flutter/material.dart';

import '../../core/app_router.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/language_selector.dart';
import '../../widgets/playvo_logo.dart';
import '../../widgets/primary_button.dart';

/// Confirms that the password was changed, so the player is told the reset
/// worked instead of being dropped back on the login form with no feedback.
///
/// It is a dead end on purpose: the button clears the whole stack, so Back
/// cannot walk into the spent OTP or the reset form behind it.
class ResetSuccessScreen extends StatelessWidget {
  const ResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.screenVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Align(
                alignment: AlignmentDirectional.topEnd,
                child: LanguageSelector(),
              ),
              const Spacer(),
              const Center(child: PlayvoLogo()),
              const SizedBox(height: AppSpacing.xxl),
              const Center(child: _SuccessMark()),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                l10n.resetSuccessTitle,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.resetSuccessSubtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
              const Spacer(),
              PrimaryButton(
                label: l10n.backToLoginButton,
                onPressed: () => AppRouter.toLoginAndClearStack(context),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// The circled tick with its soft halo, as drawn in the design.
class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.successAccentHalo,
      ),
      child: Center(
        child: Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.successAccent,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}
