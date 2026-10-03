import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_response.dart';
import '../../core/app_router.dart';
import '../../l10n/l10n.dart';
import '../../models/amenity.dart';
import '../../models/venue.dart';
import '../../models/venue_filters.dart';
import '../../services/venue_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/home_search_field.dart';
import '../../widgets/venue_photo.dart';
import '../home/venue_filter_sheet.dart';
import 'venue_search_screen.dart';

/// The map view of the same results, reached from the map button on the
/// results screen. Tapping a pin shows that venue's card at the bottom.
///
/// TODO(map): the map itself needs `google_maps_flutter` plus an API key,
/// and VENUE needs latitude/longitude from the backend — neither exists
/// yet. Until then the map area draws a placeholder and the pins are laid
/// out from the result order, so the rest of the screen can be reviewed.
class VenueMapScreen extends StatefulWidget {
  const VenueMapScreen({
    super.key,
    required this.filters,
    this.venueService,
  });

  final VenueFilters filters;
  final VenueService? venueService;

  @override
  State<VenueMapScreen> createState() => _VenueMapScreenState();
}

class _VenueMapScreenState extends State<VenueMapScreen> {
  late final VenueService _venueService =
      widget.venueService ?? VenueService.create();

  final TextEditingController _searchController = TextEditingController();

  late VenueFilters _filters = widget.filters;
  List<Venue> _venues = <Venue>[];
  Venue? _selected;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final ApiResponse<List<Venue>> response =
          await _venueService.search(_filters);
      if (!mounted) {
        return;
      }
      final List<Venue> venues = response.data ?? <Venue>[];
      setState(() {
        _venues = venues;
        _selected = venues.isEmpty ? null : venues.first;
      });
    } on ApiException {
      // The placeholder map still renders; the list simply stays empty.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _filters = _filters.copyWith(query: query.trim()));
    await _load();
  }

  Future<void> _openFilters() async {
    final VenueFilters? applied =
        await VenueFilterSheet.show(context, _filters);
    if (applied == null) {
      return;
    }
    setState(() => _filters = applied);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      bottomNavigationBar: AppBottomNav(
        current: AppTab.home,
        onSelected: (AppTab tab) => AppRouter.switchTab(context, tab),
      ),
      body: Column(
        children: <Widget>[
          VenueTitleBar(
            title: l10n.availableVenuesTitle,
            trailingIcon: Icons.format_list_bulleted,
            onTrailingPressed: () => Navigator.of(context).pop(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.md,
              AppSpacing.screenHorizontal,
              AppSpacing.md,
            ),
            child: Column(
              children: <Widget>[
                HomeSearchField(
                  controller: _searchController,
                  onSubmitted: _search,
                  onFilterPressed: _openFilters,
                  hasActiveFilters: _filters.isActive,
                ),
                const SizedBox(height: AppSpacing.md),
                VenueFilterChips(filters: _filters),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _MapArea(
                    venues: _venues,
                    selected: _selected,
                    onSelected: (Venue venue) =>
                        setState(() => _selected = venue),
                  ),
          ),
          if (_selected != null)
            _SelectedVenueSheet(
              venue: _selected!,
              onTap: () => AppRouter.toVenueDetails(context, _selected!.id),
            ),
        ],
      ),
    );
  }
}

/// Stands in for the real map until the maps package is wired up. Pins are
/// spread over the area in result order, so they are illustrative only.
class _MapArea extends StatelessWidget {
  const _MapArea({
    required this.venues,
    required this.selected,
    required this.onSelected,
  });

  final List<Venue> venues;
  final Venue? selected;
  final ValueChanged<Venue> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: Container(
                color: const Color(0xFFE8EDF2),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.map_outlined,
                          size: 34,
                          color: AppColors.navy300,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          context.l10n.mapUnavailable,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            for (int i = 0; i < venues.length; i++)
              Positioned(
                left: constraints.maxWidth * (0.15 + (i % 3) * 0.28),
                top: constraints.maxHeight * (0.12 + (i ~/ 3) * 0.26),
                child: _Pin(
                  venue: venues[i],
                  isSelected: venues[i].id == selected?.id,
                  onTap: () => onSelected(venues[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One map marker: a ball in a teardrop, orange when selected.
class _Pin extends StatelessWidget {
  const _Pin({
    required this.venue,
    required this.isSelected,
    required this.onTap,
  });

  final Venue venue;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected ? AppColors.orange500 : AppColors.navy900;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.md),
                border: Border.all(color: AppColors.orange500),
              ),
              child: Text(
                venue.name,
                style: const TextStyle(fontSize: 10, color: AppColors.navy900),
              ),
            ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const Icon(
              Icons.sports_soccer,
              size: 17,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// The card pinned to the bottom showing whichever pin is selected.
class _SelectedVenueSheet extends StatelessWidget {
  const _SelectedVenueSheet({required this.venue, required this.onTap});

  final Venue venue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          venue.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppColors.navy300,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                venue.shortAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelSmall
                                    ?.copyWith(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Text(
                              '(${venue.reviewCount})',
                              textDirection: TextDirection.ltr,
                              style: textTheme.labelSmall
                                  ?.copyWith(fontSize: 10),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              venue.rating.toStringAsFixed(1),
                              textDirection: TextDirection.ltr,
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.navy900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFF5B400),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.pricePerHourSymbol(venue.hourlyPrice),
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.navy900,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 132,
                    height: 88,
                    child: VenuePhoto(
                      url: venue.coverPhoto,
                      borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
                    ),
                  ),
                ],
              ),
              if (venue.amenities.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.md),
                _AmenityStrip(amenities: venue.amenities),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The four facility tiles along the bottom of the selected-venue card.
class _AmenityStrip extends StatelessWidget {
  const _AmenityStrip({required this.amenities});

  final List<Amenity> amenities;

  static IconData _iconFor(String? key) {
    switch (key) {
      case 'parking':
        return Icons.local_parking_outlined;
      case 'wc':
        return Icons.wc_outlined;
      case 'lockers':
        return Icons.checkroom_outlined;
      case 'lighting':
        return Icons.light_mode_outlined;
      case 'turf':
        return Icons.grass_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Amenity> shown = amenities.take(4).toList();

    return IntrinsicHeight(
      child: Row(
        children: <Widget>[
          for (int i = 0; i < shown.length; i++) ...<Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  Icon(
                    _iconFor(shown[i].icon),
                    size: 18,
                    color: AppColors.navy500,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    shown[i].name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.navy500,
                    ),
                  ),
                ],
              ),
            ),
            if (i != shown.length - 1) const VerticalDivider(width: 1),
          ],
        ],
      ),
    );
  }
}
