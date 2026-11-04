import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_response.dart';
import '../../core/app_router.dart';
import '../../core/booking_share.dart';
import '../../core/failure_messages.dart';
import '../../l10n/l10n.dart';
import '../../models/booking.dart';
import '../../models/venue.dart';
import '../../models/venue_filters.dart';
import '../../services/booking_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/booking_list_card.dart';
import '../../widgets/diagnostics_panel.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/infinite_scroll.dart';
import '../../widgets/segmented_tabs.dart';

/// "حجوزاتي" — the player's reservations, split into all, upcoming and
/// past.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key, this.bookingService});

  final BookingService? bookingService;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late final BookingService _bookingService =
      widget.bookingService ?? BookingService.create();

  List<Booking> _bookings = <Booking>[];
  int _tabIndex = 0;

  /// SRS FR-14: the history can be narrowed to one sport. Null is all.
  String? _sportFilter;

  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  /// A page shorter than this is the last one.
  static const int _pageSize = 10;
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
      final ApiResponse<List<Booking>> response =
          await _bookingService.myBookings(sportType: _sportFilter);
      if (!mounted) {
        return;
      }
      if (response.success) {
        final List<Booking> bookings = response.data ?? <Booking>[];
        setState(() {
          _bookings = bookings;
          _page = 1;
          _hasMore = response.hasMorePages ?? bookings.length >= _pageSize;
        });
        // FR-13: once a game is over, ask for its rating without waiting
        // for the player to find the button.
        _promptForRatingIfDue();
        await _fillVisibleTab();
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

  /// Appends the next page of history.
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) {
      return;
    }
    setState(() => _isLoadingMore = true);

    try {
      final ApiResponse<List<Booking>> response =
          await _bookingService.myBookings(
        page: _page + 1,
        sportType: _sportFilter,
      );
      if (!mounted) {
        return;
      }
      final List<Booking> next = response.data ?? <Booking>[];
      setState(() {
        if (response.success) {
          _page += 1;
          _bookings = <Booking>[..._bookings, ...next];
        }
        _hasMore = response.success &&
            (response.hasMorePages ?? next.length >= _pageSize);
      });
    } on ApiException {
      if (mounted) {
        setState(() => _hasMore = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  /// The tabs filter what is already loaded, but the list arrives a page at
  /// a time — so a tab can look empty while later pages still hold matching
  /// rows, and a one-item list never overflows enough to trigger a scroll.
  /// This keeps fetching until the tab has something to show or the server
  /// runs out.
  Future<void> _fillVisibleTab() async {
    // Bounded so a server that keeps returning full pages of the other tab
    // cannot spin this forever.
    for (int attempt = 0; attempt < 5; attempt++) {
      if (!mounted || !_hasMore || _visible.length >= _pageSize) {
        return;
      }
      await _loadMore();
    }
  }

  /// Changing the sport refetches rather than filtering what is already
  /// loaded: the server holds pages this screen has never seen.
  Future<void> _setSport(String? sport) async {
    setState(() => _sportFilter = sport);
    await _load();
  }

  /// Index 0 is everything, 1 upcoming, 2 past.
  List<Booking> get _visible {
    switch (_tabIndex) {
      case 1:
        return _bookings.where((Booking b) => b.isUpcoming).toList();
      case 2:
        return _bookings.where((Booking b) => !b.isUpcoming).toList();
      default:
        return _bookings;
    }
  }

  /// True once a prompt has been shown this visit, so re-entering the tab
  /// does not reopen it over and over.
  bool _hasPrompted = false;

  /// Opens the rating screen for the oldest finished booking that has not
  /// been rated. Runs after the frame so it never fights the build.
  void _promptForRatingIfDue() {
    if (_hasPrompted) {
      return;
    }
    final Iterable<Booking> due = _bookings.where((Booking b) => b.awaitsRating);
    if (due.isEmpty) {
      return;
    }
    _hasPrompted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _openRating(due.first);
      }
    });
  }

  Future<void> _openRating(Booking booking) async {
    final bool wasRated = await AppRouter.toRating(context, booking: booking);
    if (wasRated && mounted) {
      // Reflect it immediately; the next load confirms it from the server.
      setState(() {
        _bookings = _bookings
            .map((Booking b) =>
                b.id == booking.id ? b.copyWith(isRated: true) : b)
            .toList();
      });
    }
  }

  Future<void> _share(Booking booking) async {
    final AppLocalizations l10n = context.l10n;
    final bool shared = await BookingShare.share(booking, l10n);
    if (!shared && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shareUnavailable)),
      );
    }
  }

  Future<void> _confirmCancel(Booking booking) async {
    final AppLocalizations l10n = context.l10n;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.cancelBookingConfirm),
        content: Text(l10n.cancelBookingBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.keepBooking),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.cancelBooking,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _bookingService.cancel(booking.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bookingCancelled)),
      );
      await _load();
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() => _errorMessage = FailureMessages.of(exception, l10n));
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
        current: AppTab.bookings,
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
                    l10n.myBookingsTitle,
                    textAlign: TextAlign.start,
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10n.myBookingsSubtitle,
                    textAlign: TextAlign.start,
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SegmentedTabs(
                    labels: <String>[l10n.tabAll, l10n.tabUpcoming, l10n.tabPast],
                    selectedIndex: _tabIndex,
                    onSelected: (int index) {
                      setState(() => _tabIndex = index);
                      _fillVisibleTab();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SportFilterRow(
                    selected: _sportFilter,
                    onSelected: _setSport,
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(l10n)),
            // Debug builds only: shows what `/bookings` actually answered,
            // so a missing reservation can be reported with a screenshot.
            const DiagnosticsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Booking> visible = _visible;

    // Only claim the list is empty once the server has run out; otherwise
    // the tab may simply not have reached its rows yet.
    if (visible.isEmpty && _hasMore && _errorMessage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (visible.isEmpty && _errorMessage == null) {
      return SingleChildScrollView(
        child: EmptyState(
          icon: Icons.event_note_outlined,
          title: l10n.noBookingsTitle,
          subtitle: l10n.noBookingsSubtitle,
          actionLabel: l10n.findAVenue,
          onAction: () => AppRouter.toVenueSearch(
            context,
            filters: const VenueFilters(),
          ),
        ),
      );
    }

    return InfiniteScroll(
      canLoadMore: _hasMore && !_isLoadingMore,
      onLoadMore: _loadMore,
      child: RefreshIndicator(
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
          ...visible.map(
            (Booking booking) => BookingListCard(
              booking: booking,
              onViewDetails: () => AppRouter.toBookingDetail(
                context,
                booking: booking,
                onCancel: () => _confirmCancel(booking),
                onRate: () => _openRating(booking),
              ),
              onCancel: () => _confirmCancel(booking),
              onRate: () => _openRating(booking),
              onShare: () => _share(booking),
            ),
          ),
          LoadMoreFooter(isLoading: _isLoadingMore),
          ],
        ),
      ),
    );
  }
}

/// "كل الرياضات" plus one chip per sport, for SRS FR-14.
///
/// Sports outside the MVP are listed but disabled, so the roadmap shows
/// without promising data that does not exist.
class _SportFilterRow extends StatelessWidget {
  const _SportFilterRow({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  static String _label(String sport, AppLocalizations l10n) {
    switch (sport) {
      case SportType.basketball:
        return l10n.sportBasketball;
      case SportType.volleyball:
        return l10n.sportVolleyball;
      case SportType.tennis:
        return l10n.sportTennis;
      default:
        return l10n.sportFootball;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _Chip(
            label: l10n.allSports,
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final String sport in SportType.available)
            _Chip(
              label: _label(sport, l10n),
              isSelected: selected == sport,
              onTap: () => onSelected(sport),
            ),
          for (final String sport in SportType.comingSoon)
            _Chip(
              label: '${_label(sport, l10n)} · ${l10n.comingSoonTag}',
              isSelected: false,
              isEnabled: false,
              onTap: () {},
            ),
        ],
      ),
    );
  }
}

/// One sport chip.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isEnabled = true,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navy900 : AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(
              color: isSelected ? AppColors.navy900 : AppColors.fieldBorder,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: !isEnabled
                      ? AppColors.grey400
                      : isSelected
                          ? AppColors.white
                          : AppColors.navy900,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}
