import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/app_illustration.dart';
import '../../widgets/info_row_card.dart';

/// "صلاحية الوصول للبيانات" — who can reach the player's data and why.
class DataAccessScreen extends StatelessWidget {
  const DataAccessScreen({super.key});

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
              title: l10n.dataAccessTitle,
              subtitle: l10n.dataAccessSubtitle,
              centerTitle: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Center(child: _AccessMark()),
            const SizedBox(height: AppSpacing.lg),
            InfoRowCard(
              icon: Icons.group_outlined,
              iconColor: AppColors.successAccent,
              iconBackground: AppColors.successAccentHalo,
              title: l10n.limitedAccessTitle,
              body: l10n.limitedAccessBody,
            ),
            InfoRowCard(
              icon: Icons.verified_user_outlined,
              iconColor: AppColors.statusCompleted,
              iconBackground: AppColors.statusCompletedBackground,
              title: l10n.byPermissionTitle,
              body: l10n.byPermissionBody,
            ),
            InfoRowCard(
              icon: Icons.description_outlined,
              iconColor: const Color(0xFF8B5CF6),
              iconBackground: const Color(0xFFF1EBFE),
              title: l10n.safeUseTitle,
              body: l10n.safeUseBody,
            ),
            InfoRowCard(
              icon: Icons.link_off,
              iconColor: AppColors.orange500,
              iconBackground: AppColors.orange50,
              title: l10n.noThirdPartyTitle,
              body: l10n.noThirdPartyBody,
            ),
            const SizedBox(height: AppSpacing.sm),
            InfoNoteCard(
              title: l10n.privacyAccessNoteTitle,
              body: l10n.privacyAccessNoteBody,
            ),
          ],
        ),
      ),
    );
  }
}

/// The people-and-lock illustration above the cards.
class _AccessMark extends StatelessWidget {
  const _AccessMark();

  @override
  Widget build(BuildContext context) {
    return const AppIllustration(
      asset: AppIllustration.dataAccess,
      height: 130,
    );
  }
}
