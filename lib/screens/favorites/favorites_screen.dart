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
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/venue_photo.dart';

/// "المفضلة" — the venues the player hearted (SRS FR-17).
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, this.venueService});

  final VenueService? venueService;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final VenueService _venueService =
      widget.venueService ?? VenueService.create();

  List<Venue> _venues = <Venue>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ApiResponse<List<Venue>> response = await _venueService.favorites();
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

  /// Removes the heart and drops the venue from the list straight away, so
  /// the screen matches what the player just did.
  Future<void> _unfavorite(Venue venue) async {
    final List<Venue> previous = _venues;
    setState(() => _venues = _venues.where((Venue v) => v.id != venue.id).toList());

    try {
      await _venueService.toggleFavorite(venue.id, isFavorite: false);
    } on ApiException {
      if (mounted) {
        setState(() => _venues = previous);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: AppBottomNav(
        current: AppTab.favorites,
        onSelected: (AppTab tab) => AppRouter.switchTab(context, tab),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
                AppSpacing.screenHorizontal,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    l10n.favoritesTitle,
                    textAlign: TextAlign.start,
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10n.favoritesSubtitle,
                    textAlign: TextAlign.start,
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_venues.isEmpty && _errorMessage == null) {
      return SingleChildScrollView(
        child: EmptyState(
          icon: Icons.favorite_border,
          title: l10n.noFavoritesTitle,
          subtitle: l10n.noFavoritesSubtitle,
          actionLabel: l10n.findAVenue,
          onAction: () => AppRouter.toVenueSearch(
            context,
            filters: const VenueFilters(),
          ),
        ),
      );
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
          ..._venues.map(
            (Venue venue) => _FavoriteCard(
              venue: venue,
              onTap: () => AppRouter.toVenueDetails(context, venue.id),
              onUnfavorite: () => _unfavorite(venue),
            ),
          ),
        ],
      ),
    );
  }
}

/// A favourite venue: photo on the left with the filled heart, details on
/// the right, and the navy action across the bottom.
class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.venue,
    required this.onTap,
    required this.onUnfavorite,
  });

  final Venue venue;
  final VoidCallback onTap;
  final VoidCallback onUnfavorite;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusField),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
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
                    const SizedBox(height: 5),
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
                            style: textTheme.labelSmall?.copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Star first, so it sits on the right of the score as
                    // the design draws it.
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFF5B400),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          venue.rating.toStringAsFixed(1),
                          textDirection: TextDirection.ltr,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.navy900,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.reviewsCount(venue.reviewCount),
                          style: textTheme.labelSmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 130,
                height: 86,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: VenuePhoto(
                        url: venue.coverPhoto,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.sm + 2),
                      ),
                    ),
                    PositionedDirectional(
                      top: 6,
                      end: 6,
                      child: InkWell(
                        onTap: onUnfavorite,
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            size: 16,
                            color: AppColors.favoriteRed,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
            child: Text(l10n.viewDetails),
          ),
        ],
      ),
    );
  }
}
