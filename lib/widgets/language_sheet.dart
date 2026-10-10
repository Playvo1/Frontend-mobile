import 'package:flutter/material.dart';

import '../core/locale_controller.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// "اختر لغة التطبيق" — the two supported languages as radio rows, saved
/// only when the player presses the button.
class LanguageSheet extends StatefulWidget {
  const LanguageSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.xl)),
      ),
      builder: (_) => const LanguageSheet(),
    );
  }

  @override
  State<LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<LanguageSheet> {
  late Locale _draft = LocaleController.locale.value;

  Future<void> _save() async {
    if (_draft != LocaleController.locale.value) {
      await LocaleController.toggle();
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.chooseAppLanguage,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(fontSize: 19),
            ),
            const SizedBox(height: AppSpacing.lg),
            _LanguageRow(
              flag: '🇵🇸',
              label: 'العربية',
              isSelected: _draft == LocaleController.arabic,
              onTap: () => setState(() => _draft = LocaleController.arabic),
            ),
            const SizedBox(height: AppSpacing.sm),
            _LanguageRow(
              flag: '🇬🇧',
              label: 'English',
              isSelected: _draft == LocaleController.english,
              onTap: () => setState(() => _draft = LocaleController.english),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _save,
              child: Text(context.l10n.save),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// One language row: radio on the left, flag and name on the right.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusField),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy50 : AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusField),
          border: Border.all(
            color: isSelected ? AppColors.navy300 : AppColors.fieldBorder,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 21,
              color: isSelected ? AppColors.navy900 : AppColors.grey400,
            ),
            const Spacer(),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: AppSpacing.sm),
            Text(flag, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
