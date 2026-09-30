import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_router.dart';
import '../../l10n/l10n.dart';
import '../../models/booking.dart';
import '../../models/time_slot.dart';
import '../../models/venue.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/booking_stepper.dart';
import '../../widgets/booking_summary_card.dart';
import '../../widgets/success_mark.dart';
import 'booking_details_screen.dart';

/// Step 3 of 3: the receipt was sent, so the booking is recorded and the
/// player gets its reference number.
///
/// The booking still sits at `pending` until an owner approves the payment
/// (SRS FR-11), which is why the payment box says the receipt is under
/// review rather than claiming the money has cleared.
class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({
    super.key,
    required this.booking,
    required this.venue,
    required this.slot,
    required this.date,
  });

  final Booking booking;
  final Venue venue;
  final TimeSlot slot;
  final DateTime date;

  /// "PV258731" — the human-readable reference shown to the player.
  String get _reference => 'PV${booking.id.toString().padLeft(6, '0')}';

  Future<void> _copyReference(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _reference));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.copiedToClipboard)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      bottomNavigationBar: AppBottomNav(
        current: AppTab.home,
        onSelected: (AppTab tab) => AppRouter.switchTab(context, tab),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: <Widget>[
            const BookingHeader(),
            const SizedBox(height: AppSpacing.lg),
            const BookingStepper(current: BookingStep.confirmation),
            const SizedBox(height: AppSpacing.xl),
            const Center(child: SuccessMark()),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.bookingConfirmedTitleFull,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 5),
            Text(
              l10n.bookingConfirmedSubtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            BookingSummaryCard(
              heading: l10n.bookingSummary,
              venue: venue,
              dateLabel: BookingHeader.formatWeekday(date),
              dateCaption: BookingHeader.formatDayMonth(date),
              timeLabel: slot.range,
              price: slot.price ?? venue.hourlyPrice,
            ),
            const SizedBox(height: AppSpacing.md),
            const _PaymentReceivedBox(),
            const SizedBox(height: AppSpacing.md),
            _ReferenceBox(
              reference: _reference,
              onCopy: () => _copyReference(context),
            ),
            const SizedBox(height: AppSpacing.md),
            const _ImportantNotes(),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => AppRouter.switchTab(context, AppTab.bookings),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.calendar_today_outlined, size: 17),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.goToMyBookings),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => AppRouter.toHomeAndClearStack(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.home_outlined, size: 17),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.backToHome),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// The green strip confirming the receipt arrived.
class _PaymentReceivedBox extends StatelessWidget {
  const _PaymentReceivedBox();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusField),
      ),
      // The tick leads the row, which puts it on the right in Arabic.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 15, color: AppColors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.paymentConfirmedTitle,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.paymentConfirmedBody,
                  style: textTheme.labelSmall?.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The booking reference with a copy button.
class _ReferenceBox extends StatelessWidget {
  const _ReferenceBox({required this.reference, required this.onCopy});

  final String reference;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusField),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.local_offer_outlined,
            size: 20,
            color: AppColors.navy500,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.l10n.bookingNumber,
                  style: textTheme.labelSmall?.copyWith(fontSize: 11),
                ),
                Text(
                  reference,
                  textDirection: TextDirection.ltr,
                  style: textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(
              Icons.copy_outlined,
              size: 19,
              color: AppColors.navy300,
            ),
          ),
        ],
      ),
    );
  }
}

/// The bulleted reminders under the reference.
class _ImportantNotes extends StatelessWidget {
  const _ImportantNotes();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final List<String> notes = <String>[
      l10n.bookingNoteArriveOnTime,
      l10n.bookingNoteBringProof,
      l10n.bookingNoteContactUs,
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusField),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                l10n.importantNotes,
                style: textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.notifications_none,
                size: 15,
                color: AppColors.navy500,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final String note in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      note,
                      style: textTheme.labelSmall?.copyWith(height: 1.6),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 6, left: 6),
                    child: CircleAvatar(
                      radius: 2,
                      backgroundColor: AppColors.navy300,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
