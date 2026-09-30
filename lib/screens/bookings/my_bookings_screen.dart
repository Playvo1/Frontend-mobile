import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_response.dart';
import '../../core/app_router.dart';
import '../../core/failure_messages.dart';
import '../../l10n/l10n.dart';
import '../../models/booking.dart';
import '../../models/venue_filters.dart';
import '../../services/booking_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/booking_list_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
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
          await _bookingService.myBookings();
      if (!mounted) {
        return;
      }
      if (response.success) {
        setState(() => _bookings = response.data ?? <Booking>[]);
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
                    onSelected: (int index) =>
                        setState(() => _tabIndex = index),
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

    final List<Booking> visible = _visible;

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
          ...visible.map(
            (Booking booking) => BookingListCard(
              booking: booking,
              onViewDetails: () {
                final int? venueId = booking.venue?.id;
                if (venueId != null) {
                  AppRouter.toVenueDetails(context, venueId);
                }
              },
              onCancel: () => _confirmCancel(booking),
            ),
          ),
        ],
      ),
    );
  }
}
