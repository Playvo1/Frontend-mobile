import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The pill-shaped "الكل / القادمة / السابقة" switch above the bookings
/// list. The selected segment is filled navy.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Row(
        children: List<Widget>.generate(labels.length, (int index) {
          final bool isSelected = index == selectedIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navy900 : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.navy500,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
