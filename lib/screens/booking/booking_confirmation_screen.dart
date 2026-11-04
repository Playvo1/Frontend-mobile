import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_router.dart';
import '../../core/booking_share.dart';
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
            // Amber, not a green tick: the receipt has been received but an
            // admin still has to verify it, and the slot is only held until
            // then. A tick here reads as "paid and booked".
            const Center(child: SuccessMark.pending()),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.bookingConfirmedTitleFull,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Center(child: _AwaitingApprovalPill()),
            const SizedBox(height: AppSpacing.sm),
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
            OutlinedButton(
              onPressed: () async {
                final bool shared = await BookingShare.share(booking, l10n);
                if (!shared && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.shareUnavailable)),
                  );
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.ios_share, size: 17),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.shareBooking),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
/// "بانتظار تأكيد الإدارة" — the one element that states the booking's real
/// standing, placed directly under the title where the eye lands first.
class _AwaitingApprovalPill extends StatelessWidget {
  const _AwaitingApprovalPill();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.orange50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.orange100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.schedule_rounded,
            size: 15,
            color: AppColors.warning,
          ),
          const SizedBox(width: 6),
          Text(
            context.l10n.bookingAwaitingApproval,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The receipt arrived; the money has not been verified. The box is amber
/// for that reason — a green tick next to "payment" claims the transfer
/// cleared, which is the one thing this screen cannot say yet.
class _PaymentReceivedBox extends StatelessWidget {
  const _PaymentReceivedBox();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.orange50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusField),
        border: Border.all(color: AppColors.orange100),
      ),
      // The icon leads the row, which puts it on the right in Arabic.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.upload_file_rounded,
              size: 14,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.paymentConfirmedTitle,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.paymentConfirmedBody,
                  style: textTheme.labelSmall?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.bookingNotConfirmedYet,
                  style: textTheme.labelSmall?.copyWith(
                    height: 1.6,
                    fontWeight: FontWeight.w700,
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
              // The bullet comes first, which puts it on the right of the
              // line in Arabic.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 7, right: 2, left: 7),
                    child: CircleAvatar(
                      radius: 2.5,
                      backgroundColor: AppColors.navy300,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      note,
                      style: textTheme.labelSmall?.copyWith(height: 1.6),
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
