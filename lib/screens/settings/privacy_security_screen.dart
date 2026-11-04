import 'package:flutter/material.dart';

import '../../core/app_router.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/info_row_card.dart';

/// "الخصوصية والأمان" — the hub that leads to the password, policy and
/// access screens.
class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: <Widget>[
            AppScreenHeader(
              title: l10n.privacyTitle,
              subtitle: l10n.privacySubtitle,
              centerTitle: true,
            ),
            const SizedBox(height: AppSpacing.xl),
            InfoRowCard(
              icon: Icons.lock_outline,
              iconColor: AppColors.successAccent,
              iconBackground: AppColors.successAccentHalo,
              title: l10n.passwordRowTitle,
              body: l10n.passwordRowBody,
              onTap: () => AppRouter.toChangePassword(context),
            ),
            InfoRowCard(
              icon: Icons.verified_user_outlined,
              iconColor: AppColors.statusCompleted,
              iconBackground: AppColors.statusCompletedBackground,
              title: l10n.dataProtectionRowTitle,
              body: l10n.dataProtectionRowBody,
              onTap: () => AppRouter.toDataProtection(context),
            ),
            InfoRowCard(
              icon: Icons.manage_accounts_outlined,
              iconColor: const Color(0xFF8B5CF6),
              iconBackground: const Color(0xFFF1EBFE),
              title: l10n.dataAccessRowTitle,
              body: l10n.dataAccessRowBody,
              onTap: () => AppRouter.toDataAccess(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            InfoNoteCard(
              title: l10n.accountSecurityTitle,
              body: l10n.accountSecurityBody,
            ),
          ],
        ),
      ),
    );
  }
}
