import 'package:flutter/material.dart';

import '../core/country_codes.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The dialling-code button that sits beside the phone field. Tapping it
/// opens a searchable, alphabetically sorted list of every supported
/// country, so the prefix is a real choice rather than a fixed label.
class CountryCodeField extends StatelessWidget {
  const CountryCodeField({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final CountryCode selected;
  final ValueChanged<CountryCode> onChanged;
  final bool enabled;

  Future<void> _openPicker(BuildContext context) async {
    final CountryCode? picked = await showModalBottomSheet<CountryCode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.xl),
        ),
      ),
      builder: (BuildContext sheetContext) => const _CountryPickerSheet(),
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _openPicker(context) : null,
      borderRadius: BorderRadius.circular(AppSpacing.radiusField),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(selected.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              selected.dialCode,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: enabled ? AppColors.navy500 : AppColors.grey400,
                  ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: enabled ? AppColors.navy300 : AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }
}

/// The sheet itself: a search box over the sorted country list.
class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String languageCode = Localizations.localeOf(context).languageCode;

    final List<CountryCode> countries = CountryCodes.sortedFor(languageCode)
        .where((CountryCode c) => c.matches(_query))
        .toList();

    return SafeArea(
      child: Padding(
        // Lifts the sheet above the keyboard while searching.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
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
                child: Column(
                  children: <Widget>[
                    Text(
                      l10n.countryPickerTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _searchController,
                      onChanged: (String value) =>
                          setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: l10n.countrySearchHint,
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: AppColors.navy300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: countries.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noResults,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                    : ListView.separated(
                        itemCount: countries.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 56),
                        itemBuilder: (BuildContext context, int index) {
                          final CountryCode country = countries[index];
                          return ListTile(
                            leading: Text(
                              country.flag,
                              style: const TextStyle(fontSize: 22),
                            ),
                            title: Text(
                              country.nameFor(languageCode),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            trailing: Text(
                              country.dialCode,
                              textDirection: TextDirection.ltr,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: AppColors.navy500),
                            ),
                            onTap: () => Navigator.of(context).pop(country),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
