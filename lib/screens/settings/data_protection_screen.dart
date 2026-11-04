import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/app_illustration.dart';
import '../../widgets/info_row_card.dart';

/// "الخصوصية وحماية البيانات" — the policy text, as plain cards.
class DataProtectionScreen extends StatelessWidget {
  const DataProtectionScreen({super.key});

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
              title: l10n.dataProtectionTitle,
              subtitle: l10n.dataProtectionSubtitle,
              centerTitle: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Center(child: _ShieldMark()),
            const SizedBox(height: AppSpacing.lg),
            InfoRowCard(
              icon: Icons.description_outlined,
              iconColor: AppColors.successAccent,
              iconBackground: AppColors.successAccentHalo,
              title: l10n.howWeUseTitle,
              body: l10n.howWeUseBody,
            ),
            InfoRowCard(
              icon: Icons.verified_user_outlined,
              iconColor: AppColors.successAccent,
              iconBackground: AppColors.successAccentHalo,
              title: l10n.howWeProtectTitle,
              body: l10n.howWeProtectBody,
            ),
            InfoRowCard(
              icon: Icons.group_outlined,
              iconColor: AppColors.successAccent,
              iconBackground: AppColors.successAccentHalo,
              title: l10n.limitAccessTitle,
              body: l10n.limitAccessBody,
            ),
            InfoRowCard(
              icon: Icons.storage_outlined,
              iconColor: AppColors.successAccent,
              iconBackground: AppColors.successAccentHalo,
              title: l10n.secureStorageTitle,
              body: l10n.secureStorageBody,
            ),
            const SizedBox(height: AppSpacing.sm),
            InfoNoteCard(
              title: l10n.privacyMattersTitle,
              body: l10n.privacyMattersBody,
            ),
          ],
        ),
      ),
    );
  }
}

/// The shield illustration above the policy cards.
class _ShieldMark extends StatelessWidget {
  const _ShieldMark();

  @override
  Widget build(BuildContext context) {
    return const AppIllustration(
      asset: AppIllustration.dataProtection,
      height: 150,
    );
  }
}
