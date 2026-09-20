import 'package:flutter/material.dart';

import '../core/locale_controller.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The language switcher pinned to the top outer corner of every auth
/// screen. It reads and writes [LocaleController] directly, so no screen
/// needs to know how the language is stored.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: LocaleController.toggle,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.language, size: 18, color: AppColors.navy900),
            const SizedBox(width: 6),
            Text(
              context.l10n.languageLabel,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.navy900,
            ),
          ],
        ),
      ),
    );
  }
}
