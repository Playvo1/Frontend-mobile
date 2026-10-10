import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' show Position;
import 'package:latlong2/latlong.dart';

import '../../core/api_exception.dart';
import '../../core/api_response.dart';
import '../../core/app_router.dart';
import '../../core/location_service.dart';
import '../../l10n/l10n.dart';
import '../../models/amenity.dart';
import '../../models/venue.dart';
import '../../models/venue_filters.dart';
import '../../services/venue_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/assistant_fab.dart';
import '../../widgets/home_search_field.dart';
import '../../widgets/venue_map_view.dart';
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
    this.locationService,
    this.focusedVenueId,
  });

  final VenueFilters filters;
  final VenueService? venueService;

  /// Injectable so the screen can be opened in the gallery and in tests
  /// without touching the device's GPS.
  final LocationService? locationService;

  /// Opens with this venue selected, used by the map button on a result
  /// card. Null selects the first result.
  final int? focusedVenueId;

  @override
  State<VenueMapScreen> createState() => _VenueMapScreenState();
}

class _VenueMapScreenState extends State<VenueMapScreen> {
  late final VenueService _venueService =
      widget.venueService ?? VenueService.create();
  late final LocationService _locationService =
      widget.locationService ?? const LocationService();

  LatLng? _userPosition;

  final TextEditingController _searchController = TextEditingController();

  late VenueFilters _filters = widget.filters;
  List<Venue> _venues = <Venue>[];
  Venue? _selected;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _locate();
  }

  /// Asks for the player's position once the map is on screen. A refusal
  /// is not an error here: the map still works, it just has no blue dot
  /// and cannot order venues by distance.
  Future<void> _locate() async {
    try {
      final Position position = await _locationService.currentPosition();
      if (mounted) {
        setState(() {
          _userPosition = LatLng(position.latitude, position.longitude);
          _venues = _sortByDistance(_venues);
        });
      }
    } on LocationException {
      // Left as it is; the map opens on Gaza instead.
    }
  }

  /// Nearest first, when a position is known. Venues without coordinates
  /// keep their server order at the end of the list.
  List<Venue> _sortByDistance(List<Venue> venues) {
    final LatLng? from = _userPosition;
    if (from == null) {
      return venues;
    }

    final List<Venue> sorted = List<Venue>.of(venues);
    sorted.sort((Venue a, Venue b) {
      if (!a.hasCoordinates) {
        return 1;
      }
      if (!b.hasCoordinates) {
        return -1;
      }
      final double toA = _locationService.distanceBetween(
        fromLatitude: from.latitude,
        fromLongitude: from.longitude,
        toLatitude: a.latitude!,
        toLongitude: a.longitude!,
      );
      final double toB = _locationService.distanceBetween(
        fromLatitude: from.latitude,
        fromLongitude: from.longitude,
        toLatitude: b.latitude!,
        toLongitude: b.longitude!,
      );
      return toA.compareTo(toB);
    });
    return sorted;
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final ApiResponse<List<Venue>> response =
          await _venueService.search(_filters);
      if (!mounted) {
        return;
      }
      final List<Venue> venues = _sortByDistance(response.data ?? <Venue>[]);
      setState(() {
        _venues = venues;
        _selected = venues.isEmpty
            ? null
            : venues.firstWhere(
                (Venue v) => v.id == widget.focusedVenueId,
                orElse: () => venues.first,
              );
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
    if (applied == null || !mounted) {
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
      floatingActionButtonLocation:
          FloatingActionButtonLocation.startFloat,
      floatingActionButton: const AssistantFab(),
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
                : VenueMapView(
                    venues: _venues,
                    selected: _selected,
                    userPosition: _userPosition,
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
