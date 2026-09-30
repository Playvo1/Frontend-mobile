import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_response.dart';
import '../../core/app_router.dart';
import '../../core/failure_messages.dart';
import '../../l10n/l10n.dart';
import '../../models/amenity.dart';
import '../../models/time_slot.dart';
import '../../models/venue_details.dart';
import '../../services/venue_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/date_strip.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/time_slot_grid.dart';
import '../../widgets/venue_photo.dart';

/// The venue page: gallery, description, amenities, and the day's slots.
///
/// The slots are refetched whenever the date changes, because availability
/// is per day and stale slots would let a player pick an hour the server
/// has already given away.
class VenueDetailsScreen extends StatefulWidget {
  const VenueDetailsScreen({
    super.key,
    required this.venueId,
    this.venueService,
  });

  final int venueId;
  final VenueService? venueService;

  @override
  State<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends State<VenueDetailsScreen> {
  late final VenueService _venueService =
      widget.venueService ?? VenueService.create();

  VenueDetails? _details;
  bool _isLoading = true;
  String? _errorMessage;

  int _galleryIndex = 0;
  int? _selectedSlotId;

  late DateTime _selectedDate = _today;
  late DateTime _stripStart = _today;

  static DateTime get _today {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

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
      final ApiResponse<VenueDetails> response = await _venueService.details(
        widget.venueId,
        date: _selectedDate,
      );
      if (!mounted) {
        return;
      }
      if (response.success) {
        setState(() {
          _details = response.data;
          // A slot id from the previous day means nothing on this one.
          _selectedSlotId = null;
        });
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

  Future<void> _selectDate(DateTime date) async {
    setState(() => _selectedDate = date);
    await _load();
  }

  void _shiftStrip(int direction) {
    final DateTime shifted = DateTime(
      _stripStart.year,
      _stripStart.month,
      _stripStart.day + direction * 5,
    );
    // Never walk back past today: those days cannot be booked.
    setState(
      () => _stripStart = shifted.isBefore(_today) ? _today : shifted,
    );
  }

  void _continueToBooking() {
    final VenueDetails? details = _details;
    final int? slotId = _selectedSlotId;
    if (details == null || slotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.selectSlotFirst)),
      );
      return;
    }

    AppRouter.toBookingDetails(
      context,
      venue: details.venue,
      slot: details.timeSlots.firstWhere((TimeSlot s) => s.id == slotId),
      date: _selectedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final VenueDetails? details = _details;

    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: AppBottomNav(
        current: AppTab.home,
        onSelected: (AppTab tab) => AppRouter.switchTab(context, tab),
      ),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : details == null
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                    child: ErrorBanner(message: _errorMessage),
                  )
                : _buildContent(l10n, details),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n, VenueDetails details) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        _Gallery(
          photos: details.photos,
          index: _galleryIndex,
          isFavorite: details.venue.isFavorite,
          onIndexChanged: (int index) => setState(() => _galleryIndex = index),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      details.venue.name,
                      style: textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _PriceBadge(price: details.venue.hourlyPrice),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.navy300,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    details.venue.shortAddress,
                    style: textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: <Widget>[
                  Text(
                    l10n.reviewsCount(details.venue.reviewCount),
                    style: textTheme.labelSmall?.copyWith(fontSize: 11),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    details.venue.rating.toStringAsFixed(1),
                    textDirection: TextDirection.ltr,
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.navy900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Color(0xFFF5B400),
                  ),
                ],
              ),
              if (details.description.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  details.description,
                  style: textTheme.labelSmall?.copyWith(height: 1.7),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _Amenities(amenities: details.amenities),
              const SizedBox(height: AppSpacing.xl),
              _SectionRow(
                icon: Icons.calendar_today_outlined,
                title: l10n.chooseDateTitle,
                actionLabel: l10n.viewFullCalendar,
                onAction: _pickFromCalendar,
              ),
              const SizedBox(height: AppSpacing.md),
              DateStrip(
                firstDate: _stripStart,
                selected: _selectedDate,
                onSelected: _selectDate,
                onShift: _shiftStrip,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.schedule,
                    size: 15,
                    color: AppColors.navy500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.availableTime,
                    style: textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TimeSlotGrid(
                slots: details.timeSlots,
                selectedId: _selectedSlotId,
                onSelected: (TimeSlot slot) =>
                    setState(() => _selectedSlotId = slot.id),
              ),
              ErrorBanner(message: _errorMessage),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _continueToBooking,
                child: Text(l10n.continueBooking),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickFromCalendar() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _today,
      lastDate: _today.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _stripStart = picked);
      await _selectDate(picked);
    }
  }
}

/// The photo header with its thumbnail strip and the back, share and
/// favourite buttons.
class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.photos,
    required this.index,
    required this.isFavorite,
    required this.onIndexChanged,
  });

  final List<String> photos;
  final int index;
  final bool isFavorite;
  final ValueChanged<int> onIndexChanged;

  @override
  Widget build(BuildContext context) {
    final String? current = photos.isEmpty ? null : photos[index];

    return Column(
      children: <Widget>[
        Stack(
          children: <Widget>[
            SizedBox(
              height: 210,
              width: double.infinity,
              child: VenuePhoto(
                url: current,
                borderRadius: BorderRadius.circular(AppSpacing.radiusField),
              ),
            ),
            // The design keeps the back chevron on the left of the photo
            // and the two actions on the right, so they are pinned by
            // physical side rather than by reading direction.
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              child: _RoundButton(
                icon: Icons.chevron_left,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              // The heart is the outermost button on the right, with share
              // to its left.
              child: Row(
                children: <Widget>[
                  _RoundButton(
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    onPressed: () {},
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _RoundButton(icon: Icons.share_outlined, onPressed: () {}),
                ],
              ),
            ),
            if (photos.isNotEmpty)
              Positioned(
                bottom: AppSpacing.md,
                right: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy900.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.photo_outlined,
                        size: 12,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${index + 1}/${photos.length}',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (photos.length > 1) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _Thumbnails(
            photos: photos,
            index: index,
            onIndexChanged: onIndexChanged,
          ),
        ],
      ],
    );
  }
}

/// A white circular button used over the gallery photo.
class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 19, color: AppColors.navy900),
      ),
    );
  }
}

/// The orange "50 ₪ / ساعة" pill above the venue name.
class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.price});

  final int price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.orange50,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.l10n.pricePerHourSymbol(price),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.orange700,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 5),
          const Icon(
            Icons.sell_outlined,
            size: 14,
            color: AppColors.orange500,
          ),
        ],
      ),
    );
  }
}

/// The row of amenity tiles.
class _Amenities extends StatelessWidget {
  const _Amenities({required this.amenities});

  final List<Amenity> amenities;

  /// Maps the API's icon keys onto Material icons. An unknown key gets a
  /// neutral tick rather than a blank tile, so the backend can add an
  /// amenity without waiting for an app release.
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
      case 'cafe':
        return Icons.local_cafe_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: amenities.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final Amenity amenity = amenities[index];
          return Container(
            width: 74,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  _iconFor(amenity.icon),
                  size: 19,
                  color: AppColors.navy500,
                ),
                const SizedBox(height: 5),
                Text(
                  amenity.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: AppColors.navy500),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A section title with a trailing action link.
class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 15, color: AppColors.navy500),
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
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
                    ?.copyWith(color: AppColors.orange500, fontSize: 11),
              ),
              const Icon(
                Icons.chevron_left,
                size: 14,
                color: AppColors.orange500,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Four thumbnails and, when there are more photos, a navy "+N" tile that
/// stands for the rest.
class _Thumbnails extends StatelessWidget {
  const _Thumbnails({
    required this.photos,
    required this.index,
    required this.onIndexChanged,
  });

  static const int _visible = 4;

  final List<String> photos;
  final int index;
  final ValueChanged<int> onIndexChanged;

  @override
  Widget build(BuildContext context) {
    final int extra = photos.length - _visible;
    final int shown = extra > 0 ? _visible : photos.length;

    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < shown; i++) ...<Widget>[
              Expanded(
                child: InkWell(
                  onTap: () => onIndexChanged(i),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                      border: Border.all(
                        color: i == index
                            ? AppColors.orange500
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: VenuePhoto(
                      url: photos[i],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (extra > 0)
              Expanded(
                child: InkWell(
                  onTap: () => onIndexChanged(_visible),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.navy900,
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                    child: Center(
                      child: Text(
                        context.l10n.morePhotos(extra),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
