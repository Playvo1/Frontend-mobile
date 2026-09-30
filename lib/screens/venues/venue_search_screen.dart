import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_response.dart';
import '../../core/app_router.dart';
import '../../core/failure_messages.dart';
import '../../l10n/l10n.dart';
import '../../models/venue.dart';
import '../../models/venue_filters.dart';
import '../../services/venue_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/home_search_field.dart';
import '../../widgets/venue_result_card.dart';
import '../home/venue_filter_sheet.dart';

/// "الملاعب المتاحة" — the results list, with the active filters shown as
/// chips under the search box so the player can see what is narrowing the
/// list and drop any of it in one tap (SRS FR-04).
class VenueSearchScreen extends StatefulWidget {
  const VenueSearchScreen({
    super.key,
    required this.initialFilters,
    this.venueService,
  });

  final VenueFilters initialFilters;
  final VenueService? venueService;

  @override
  State<VenueSearchScreen> createState() => _VenueSearchScreenState();
}

class _VenueSearchScreenState extends State<VenueSearchScreen> {
  late final TextEditingController _searchController =
      TextEditingController(text: widget.initialFilters.query);

  late final VenueService _venueService =
      widget.venueService ?? VenueService.create();

  late VenueFilters _filters = widget.initialFilters;
  List<Venue> _venues = <Venue>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ApiResponse<List<Venue>> response =
          await _venueService.search(_filters);
      if (!mounted) {
        return;
      }
      if (response.success) {
        setState(() => _venues = response.data ?? <Venue>[]);
        return;
      }
      setState(() => _errorMessage = response.message);
    } on ApiException catch (exception) {
      if (!mounted) {
        return;
      }
      setState(
        () => _errorMessage = FailureMessages.of(exception, context.l10n),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  Future<void> _applyFilters(VenueFilters filters) async {
    setState(() => _filters = filters);
    await _load();
  }

  Future<void> _toggleFavorite(Venue venue) async {
    setState(() {
      _venues = _venues
          .map(
            (Venue v) =>
                v.id == venue.id ? v.copyWith(isFavorite: !v.isFavorite) : v,
          )
          .toList();
    });
    try {
      await _venueService.toggleFavorite(
        venue.id,
        isFavorite: !venue.isFavorite,
      );
    } on ApiException {
      if (mounted) {
        setState(() {
          _venues = _venues
              .map(
                (Venue v) => v.id == venue.id
                    ? v.copyWith(isFavorite: venue.isFavorite)
                    : v,
              )
              .toList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      // The design reaches this screen from Home, so Home stays the active
      // tab rather than switching to Explore.
      bottomNavigationBar: AppBottomNav(
        current: AppTab.home,
        onSelected: (AppTab tab) => AppRouter.switchTab(context, tab),
      ),
      body: Column(
        children: <Widget>[
          VenueTitleBar(
            title: l10n.availableVenuesTitle,
            trailingIcon: Icons.map_outlined,
            onTrailingPressed: () =>
                AppRouter.toVenueMap(context, filters: _filters),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.md,
              AppSpacing.screenHorizontal,
              0,
            ),
            child: Column(
              children: <Widget>[
                HomeSearchField(
                  controller: _searchController,
                  onSubmitted: (String query) =>
                      _applyFilters(_filters.copyWith(query: query.trim())),
                  onFilterPressed: _openFilters,
                  hasActiveFilters: _filters.isActive,
                ),
                const SizedBox(height: AppSpacing.md),
                VenueFilterChips(filters: _filters),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      l10n.venuesFound(_venues.length),
                      style: textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.swap_vert,
                          size: 15,
                          color: AppColors.navy500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.sortNearest,
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            color: AppColors.navy900,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: AppColors.navy300,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _buildResults(l10n)),
        ],
      ),
    );
  }

  Widget _buildResults(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          0,
          AppSpacing.screenHorizontal,
          AppSpacing.lg,
        ),
        children: <Widget>[
          ErrorBanner(message: _errorMessage),
          if (_venues.isEmpty && _errorMessage == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(
                child: Text(
                  l10n.noVenuesFound,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ..._venues.map(
            (Venue venue) => VenueResultCard(
              venue: venue,
              onTap: () => AppRouter.toVenueDetails(context, venue.id),
              onToggleFavorite: () => _toggleFavorite(venue),
            ),
          ),
        ],
      ),
    );
  }
}

/// The navy bar across the top: back on the right, and a button on the
/// left that swaps between the list and the map.
class VenueTitleBar extends StatelessWidget {
  const VenueTitleBar({
    super.key,
    required this.title,
    required this.trailingIcon,
    required this.onTrailingPressed,
  });

  final String title;

  /// The map icon on the list screen, the list icon on the map screen.
  final IconData trailingIcon;
  final VoidCallback onTrailingPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navy900,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.lg),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          // Back on the right, map on the left, as the design draws it —
          // the first child of a Row sits on the right in Arabic.
          child: Row(
            children: <Widget>[
              _BarButton(
                icon: Icons.chevron_right,
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.white,
                        fontSize: 19,
                      ),
                ),
              ),
              _BarButton(icon: trailingIcon, onPressed: onTrailingPressed),
            ],
          ),
        ),
      ),
    );
  }
}

/// One chip per active filter, shared by the list and map screens.
class VenueFilterChips extends StatelessWidget {
  const VenueFilterChips({super.key, required this.filters});

  final VenueFilters filters;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    final List<Widget> chips = <Widget>[
      if (filters.city != null)
        _Chip(icon: Icons.location_on_outlined, label: filters.city!),
      if (filters.sportType != null)
        _Chip(icon: Icons.sports_soccer, label: l10n.sportFootball),
      if (filters.date != null)
        _Chip(
          icon: Icons.calendar_today_outlined,
          label: '${filters.date!.day}/${filters.date!.month}',
        ),
      if (filters.time != null)
        _Chip(icon: Icons.schedule, label: filters.time!.format(context)),
    ];

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, int index) => chips[index],
      ),
    );
  }
}

/// One filter chip. Read-only, as in the design: the filters are changed
/// in the sheet, which is the single place that owns them.
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppColors.navy500),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontSize: 11, color: AppColors.navy900),
          ),
        ],
      ),
    );
  }
}

/// A round button on the navy title bar.
class _BarButton extends StatelessWidget {
  const _BarButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.white),
      ),
    );
  }
}
