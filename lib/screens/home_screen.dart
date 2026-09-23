import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../core/api_response.dart';
import '../core/failure_messages.dart';
import '../core/reference_data.dart';
import '../l10n/l10n.dart';
import '../models/venue.dart';
import '../models/venue_filters.dart';
import '../services/venue_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/error_banner.dart';
import '../widgets/home_search_field.dart';
import '../widgets/playvo_logo.dart';
import '../widgets/promo_banner.dart';
import '../widgets/venue_card.dart';
import 'home/venue_filter_sheet.dart';

/// The player's landing screen: greeting, search, and the nearby venues
/// (SRS FR-04, FR-05, FR-17).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.venueService});

  /// Injectable so the gallery and the tests can drive the screen without a
  /// backend.
  final VenueService? venueService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  late final VenueService _venueService =
      widget.venueService ?? VenueService.create();

  VenueFilters _filters = const VenueFilters();
  List<Venue> _venues = <Venue>[];
  bool _isLoading = true;
  String? _errorMessage;

  /// The city shown in the header. Defaults to the MVP's only city.
  String _selectedCity = ReferenceData.cities.first;

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVenues() async {
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
    setState(() {
      _filters = applied;
      // The header follows the sheet, so the two never disagree.
      _selectedCity = applied.city ?? _selectedCity;
    });
    await _loadVenues();
  }

  Future<void> _search(String query) async {
    setState(() => _filters = _filters.copyWith(query: query.trim()));
    await _loadVenues();
  }

  Future<void> _toggleFavorite(Venue venue) async {
    // Flip it straight away — the list must not wait on the network to feel
    // responsive, and the server's answer replaces this a moment later.
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
      // Put it back the way it was; the change never reached the server.
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

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.comingSoon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      bottomNavigationBar: AppBottomNav(
        current: AppTab.home,
        // Only the home tab is built so far.
        onSelected: (AppTab tab) {
          if (tab != AppTab.home) {
            _showComingSoon();
          }
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadVenues,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.sm,
              AppSpacing.screenHorizontal,
              AppSpacing.lg,
            ),
            children: <Widget>[
              _Header(
                city: _selectedCity,
                onCityPressed: _openFilters,
                onNotificationsPressed: _showComingSoon,
                onProfilePressed: _showComingSoon,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Center(child: PlayvoLogo(markHeight: 76, wordmarkSize: 20)),
              const SizedBox(height: AppSpacing.lg),
              _Greeting(greeting: l10n.homeGreeting, subtitle: l10n.homeSubtitle),
              const SizedBox(height: AppSpacing.lg),
              HomeSearchField(
                controller: _searchController,
                onSubmitted: _search,
                onFilterPressed: _openFilters,
                hasActiveFilters: _filters.isActive,
              ),
              const SizedBox(height: AppSpacing.md),
              PromoBanner(onPressed: _showComingSoon),
              const SizedBox(height: AppSpacing.xl),
              _SectionHeader(
                title: l10n.nearbyVenues,
                actionLabel: l10n.viewAll,
                onAction: _showComingSoon,
              ),
              const SizedBox(height: AppSpacing.md),
              ErrorBanner(message: _errorMessage),
              ..._buildVenueList(l10n),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildVenueList(AppLocalizations l10n) {
    if (_isLoading) {
      return const <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_venues.isEmpty && _errorMessage == null) {
      return <Widget>[
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
      ];
    }

    return _venues
        .map(
          (Venue venue) => VenueCard(
            venue: venue,
            onTap: _showComingSoon,
            onBook: _showComingSoon,
            onToggleFavorite: () => _toggleFavorite(venue),
          ),
        )
        .toList();
  }
}

/// Notifications, the city selector, and the profile button.
class _Header extends StatelessWidget {
  const _Header({
    required this.city,
    required this.onCityPressed,
    required this.onNotificationsPressed,
    required this.onProfilePressed,
  });

  final String city;
  final VoidCallback onCityPressed;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) {
    // In Arabic the first child sits on the RIGHT, so the city and profile
    // come first and the bell last — that is what puts the bell on the left,
    // as the design has it. Reversing this order mirrors the whole header.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
            _CircleButton(
              icon: Icons.person_outline,
              onPressed: onProfilePressed,
            ),
            const SizedBox(width: AppSpacing.sm),
            InkWell(
              onTap: onCityPressed,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 6,
                ),
                // Reads right to left: pin, city, chevron.
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.orange500,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      city,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.navy900,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        _CircleButton(
          icon: Icons.notifications_none,
          onPressed: onNotificationsPressed,
          showsBadge: true,
        ),
      ],
    );
  }
}

/// A round icon button, optionally filled navy or carrying an alert dot.
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onPressed,
    this.showsBadge = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool showsBadge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Icon(icon, size: 19, color: AppColors.navy900),
          ),
          if (showsBadge)
            // A small dot on the rim of the circle, not inside it.
            PositionedDirectional(
              top: -1,
              end: -1,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: AppColors.orange500,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "هيا نلعب !" with the orange mark, over the subtitle.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.greeting, required this.subtitle});

  final String greeting;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        Text.rich(
          TextSpan(
            style: textTheme.headlineSmall,
            children: <InlineSpan>[
              TextSpan(text: greeting),
              const TextSpan(
                text: ' !',
                style: TextStyle(color: AppColors.orange500),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, textAlign: TextAlign.center, style: textTheme.bodySmall),
      ],
    );
  }
}

/// A section title with its trailing "عرض الكل" link.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: AppColors.navy900, fontWeight: FontWeight.w700),
        ),
        InkWell(
          onTap: onAction,
          child: Row(
            children: <Widget>[
              Text(
                actionLabel,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.orange500),
              ),
              const Icon(
                Icons.chevron_left,
                size: 15,
                color: AppColors.orange500,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
