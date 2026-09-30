import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The horizontal row of days on the venue page. The chosen day is filled
/// orange; the arrows step the window a week at a time.
class DateStrip extends StatelessWidget {
  const DateStrip({
    super.key,
    required this.firstDate,
    required this.selected,
    required this.onSelected,
    required this.onShift,
    this.visibleDays = 5,
  });

  /// The first day drawn in the strip.
  final DateTime firstDate;

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  /// Called with -1 or +1 when an arrow is tapped, so the parent decides
  /// how far back the calendar may go.
  final ValueChanged<int> onShift;

  final int visibleDays;

  static const List<String> _weekdaysAr = <String>[
    'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',
    'الجمعة', 'السبت', 'الأحد',
  ];

  static const List<String> _monthsAr = <String>[
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _Arrow(icon: Icons.chevron_right, onPressed: () => onShift(-1)),
        ...List<Widget>.generate(visibleDays, (int index) {
          final DateTime day = DateTime(
            firstDate.year,
            firstDate.month,
            firstDate.day + index,
          );
          return Expanded(
            child: _DayCell(
              day: day,
              weekdayLabel: _weekdaysAr[day.weekday - 1],
              monthLabel: _monthsAr[day.month - 1],
              isSelected: _isSameDay(day, selected),
              onTap: () => onSelected(day),
            ),
          );
        }),
        _Arrow(icon: Icons.chevron_left, onPressed: () => onShift(1)),
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// One day in the strip: the number over the month name.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.weekdayLabel,
    required this.monthLabel,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime day;
  final String weekdayLabel;
  final String monthLabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.orange500 : AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(
              color: isSelected ? AppColors.orange500 : AppColors.fieldBorder,
            ),
          ),
          child: Column(
            children: <Widget>[
              Text(
                weekdayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.white : AppColors.navy500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                day.day.toString(),
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.white : AppColors.navy900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                monthLabel,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? AppColors.white : AppColors.navy300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One of the two stepping arrows beside the strip.
class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 20, color: AppColors.navy300),
      ),
    );
  }
}
