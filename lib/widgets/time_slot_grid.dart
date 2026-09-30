import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/time_slot.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The grid of bookable hours under the date strip. A taken slot is greyed
/// and cannot be selected, so the player never picks an hour the server
/// will reject.
class TimeSlotGrid extends StatelessWidget {
  const TimeSlotGrid({
    super.key,
    required this.slots,
    required this.selectedId,
    required this.onSelected,
  });

  final List<TimeSlot> slots;
  final int? selectedId;
  final ValueChanged<TimeSlot> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (BuildContext context, int index) {
        final TimeSlot slot = slots[index];
        return _SlotCell(
          slot: slot,
          isSelected: slot.id == selectedId,
          onTap: slot.isAvailable ? () => onSelected(slot) : null,
        );
      },
    );
  }
}

/// One hour: the time over its availability caption.
class _SlotCell extends StatelessWidget {
  const _SlotCell({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  final TimeSlot slot;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool isBooked = !slot.isAvailable;

    final Color border = isSelected
        ? AppColors.navy900
        : isBooked
            ? AppColors.grey200
            : AppColors.fieldBorder;
    final Color text = isBooked ? AppColors.grey400 : AppColors.navy900;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: isBooked ? AppColors.grey100 : AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(color: border, width: isSelected ? 1.6 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              slot.displayTime,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isBooked ? l10n.slotBooked : l10n.slotAvailable,
              style: TextStyle(
                fontSize: 9,
                color: isBooked ? AppColors.grey400 : AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
