import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The search box with the filter button beside it. Tapping the filter icon
/// opens the "تصفية النتائج" sheet; a dot marks it when filters are on, so
/// the player can see the list is narrowed without opening the sheet.
class HomeSearchField extends StatelessWidget {
  const HomeSearchField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onFilterPressed,
    this.hasActiveFilters = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilterPressed;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusField),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: AppSpacing.md),
          const Icon(Icons.search, size: 20, color: AppColors.navy300),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: context.l10n.searchHint,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
          _FilterButton(
            onPressed: onFilterPressed,
            hasActiveFilters: hasActiveFilters,
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

/// The sliders icon that opens the filter sheet.
class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.onPressed,
    required this.hasActiveFilters,
  });

  final VoidCallback onPressed;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            const Icon(Icons.tune, size: 20, color: AppColors.navy900),
            if (hasActiveFilters)
              PositionedDirectional(
                top: -2,
                end: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.orange500,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
