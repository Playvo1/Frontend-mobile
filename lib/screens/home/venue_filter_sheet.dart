import 'package:flutter/material.dart';

import '../../core/reference_data.dart';
import '../../l10n/l10n.dart';
import '../../models/venue.dart';
import '../../models/venue_filters.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// The "تصفية النتائج" sheet (SRS FR-04), opened from the filter icon
/// beside the search box.
///
/// It edits a working copy and returns it only when "عرض النتائج" is
/// pressed, so backing out of the sheet leaves the current results alone.
/// Returns null when dismissed.
class VenueFilterSheet extends StatefulWidget {
  const VenueFilterSheet({super.key, required this.initial});

  final VenueFilters initial;

  /// Opens the sheet and resolves to the chosen filters, or null.
  static Future<VenueFilters?> show(
    BuildContext context,
    VenueFilters initial,
  ) {
    return showModalBottomSheet<VenueFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.xl)),
      ),
      builder: (_) => VenueFilterSheet(initial: initial),
    );
  }

  @override
  State<VenueFilterSheet> createState() => _VenueFilterSheetState();
}

class _VenueFilterSheetState extends State<VenueFilterSheet> {
  late VenueFilters _draft = widget.initial;

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _draft.date ?? now,
      firstDate: now,
      // A booking cannot be made further out than the owners publish slots.
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _draft = _draft.copyWith(date: picked));
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _draft.time ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _draft = _draft.copyWith(time: picked));
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.sm,
          AppSpacing.screenHorizontal,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.navy900),
                ),
                Expanded(
                  child: Text(
                    l10n.filterTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            _FilterRow(
              icon: Icons.location_on_outlined,
              label: l10n.filterCityRegion,
              child: _Dropdown<String>(
                value: _draft.city,
                hint: l10n.allCities,
                items: ReferenceData.cities,
                labelBuilder: (String city) => city,
                onChanged: (String? city) =>
                    setState(() => _draft = _draft.copyWith(city: city)),
              ),
            ),
            _FilterRow(
              icon: Icons.sports_soccer_outlined,
              label: l10n.filterSport,
              onClear: _draft.sportType == null
                  ? null
                  : () => setState(
                        () => _draft = _draft.copyWith(sportType: null),
                      ),
              child: _Dropdown<String>(
                value: _draft.sportType,
                hint: l10n.sportFootball,
                items: SportType.all,
                labelBuilder: (String _) => l10n.sportFootball,
                onChanged: (String? sport) =>
                    setState(() => _draft = _draft.copyWith(sportType: sport)),
              ),
            ),
            _FilterRow(
              icon: Icons.calendar_today_outlined,
              label: l10n.filterDate,
              onClear: _draft.date == null
                  ? null
                  : () => setState(() => _draft = _draft.copyWith(date: null)),
              child: _PickerButton(
                text: _draft.date == null
                    ? l10n.chooseDate
                    : _formatDate(_draft.date!),
                isPlaceholder: _draft.date == null,
                onPressed: _pickDate,
              ),
            ),
            _FilterRow(
              icon: Icons.schedule_outlined,
              label: l10n.filterTime,
              onClear: _draft.time == null
                  ? null
                  : () => setState(() => _draft = _draft.copyWith(time: null)),
              child: _PickerButton(
                text: _draft.time == null
                    ? l10n.chooseTime
                    : _draft.time!.format(context),
                isPlaceholder: _draft.time == null,
                onPressed: _pickTime,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),
            _PriceRange(
              label: l10n.filterPrice,
              minPrice: _draft.minPrice,
              maxPrice: _draft.maxPrice,
              onChanged: (RangeValues values) => setState(
                () => _draft = _draft.copyWith(
                  minPrice: values.start,
                  maxPrice: values.end,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            _RatingChips(
              label: l10n.filterRating,
              selected: _draft.minRating,
              onSelected: (int? rating) =>
                  setState(() => _draft = _draft.copyWith(minRating: rating)),
            ),

            const SizedBox(height: AppSpacing.xl),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        setState(() => _draft = const VenueFilters()),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.navy50,
                      side: BorderSide.none,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(l10n.filterReset),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_draft),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(l10n.filterApply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One labelled row of the sheet: icon and label on the outer edge, the
/// control filling the rest, and an optional clear button.
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.icon,
    required this.label,
    required this.child,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 116,
            child: Row(
              children: <Widget>[
                Icon(icon, size: 17, color: AppColors.navy500),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                if (onClear != null)
                  InkWell(
                    onTap: onClear,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.cancel,
                        size: 15,
                        color: AppColors.navy300,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// A bordered dropdown matching the field styling.
class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.navy300),
      hint: Text(hint, style: Theme.of(context).textTheme.bodySmall),
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      items: items
          .map(
            (T item) => DropdownMenuItem<T>(
              value: item,
              child: Text(labelBuilder(item)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

/// A bordered button that looks like the dropdowns but opens a picker.
class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.text,
    required this.onPressed,
    required this.isPlaceholder,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSpacing.radiusField),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusField),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: isPlaceholder ? textTheme.bodySmall : textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.navy300),
          ],
        ),
      ),
    );
  }
}

/// The shekels-per-hour range slider with its two value bubbles.
class _PriceRange extends StatelessWidget {
  const _PriceRange({
    required this.label,
    required this.minPrice,
    required this.maxPrice,
    required this.onChanged,
  });

  final String label;
  final double minPrice;
  final double maxPrice;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        SizedBox(
          width: 116,
          child: Text(
            label,
            maxLines: 2,
            style: textTheme.labelMedium,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _PriceBubble(value: maxPrice),
        Expanded(
          child: RangeSlider(
            values: RangeValues(minPrice, maxPrice),
            min: VenueFilters.priceFloor,
            max: VenueFilters.priceCeiling,
            divisions:
                (VenueFilters.priceCeiling - VenueFilters.priceFloor) ~/ 5,
            activeColor: AppColors.navy900,
            inactiveColor: AppColors.grey200,
            onChanged: onChanged,
          ),
        ),
        _PriceBubble(value: minPrice),
      ],
    );
  }
}

/// One end of the price range, drawn as a small rounded chip.
class _PriceBubble extends StatelessWidget {
  const _PriceBubble({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Text(
        value.round().toString(),
        textDirection: TextDirection.ltr,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: AppColors.navy900, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// "1+ 2+ 3+ 4+ 5+" — tapping the selected chip again clears the filter.
class _RatingChips extends StatelessWidget {
  const _RatingChips({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final int? selected;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 116,
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.star_border_rounded,
                size: 18,
                color: AppColors.navy500,
              ),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(5, (int index) {
              final int rating = index + 1;
              final bool isSelected = selected == rating;
              return InkWell(
                onTap: () => onSelected(isSelected ? null : rating),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.navy900 : AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Text(
                    '$rating+',
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.navy900,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
