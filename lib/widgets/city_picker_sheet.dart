import 'package:flutter/material.dart';

import '../core/reference_data.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The list of cities opened by tapping the location in the header.
///
/// Returns the chosen city, or null when dismissed. The list comes from
/// [ReferenceData] for now; FR-34 moves it to the API with a local cache.
class CityPickerSheet extends StatelessWidget {
  const CityPickerSheet({super.key, required this.selected});

  final String? selected;

  static Future<String?> show(BuildContext context, String? selected) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.xl)),
      ),
      builder: (_) => CityPickerSheet(selected: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Text(
              context.l10n.chooseCity,
              style: textTheme.headlineSmall,
            ),
          ),
          for (final String city in ReferenceData.cities)
            ListTile(
              onTap: () => Navigator.of(context).pop(city),
              leading: Icon(
                Icons.location_on_outlined,
                size: 20,
                color: city == selected ? AppColors.orange500 : AppColors.navy300,
              ),
              title: Text(
                city,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      city == selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              trailing: city == selected
                  ? const Icon(Icons.check, size: 19, color: AppColors.orange500)
                  : null,
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
