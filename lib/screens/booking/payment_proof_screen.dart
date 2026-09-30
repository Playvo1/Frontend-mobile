import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_response.dart';
import '../../core/app_router.dart';
import '../../core/failure_messages.dart';
import '../../core/receipt_picker.dart';
import '../../l10n/l10n.dart';
import '../../models/booking.dart';
import '../../models/time_slot.dart';
import '../../models/venue.dart';
import '../../services/booking_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/booking_stepper.dart';
import '../../widgets/booking_summary_card.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/receipt_upload_box.dart';
import 'booking_details_screen.dart';

/// Step 2 of 3: the bank transfer receipt.
///
/// The booking already exists at this point — it was created in step 1 and
/// sits at `pending` until an owner approves this receipt (SRS FR-11).
class PaymentProofScreen extends StatefulWidget {
  const PaymentProofScreen({
    super.key,
    required this.booking,
    required this.venue,
    required this.slot,
    required this.date,
    this.bookingService,
    this.receiptPicker = const ReceiptPicker(),
  });

  final Booking booking;
  final Venue venue;
  final TimeSlot slot;
  final DateTime date;
  final BookingService? bookingService;
  final ReceiptPicker receiptPicker;

  @override
  State<PaymentProofScreen> createState() => _PaymentProofScreenState();
}

class _PaymentProofScreenState extends State<PaymentProofScreen> {
  late final BookingService _bookingService =
      widget.bookingService ?? BookingService.create();

  PickedReceipt? _receipt;
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _pickReceipt() async {
    final AppLocalizations l10n = context.l10n;
    try {
      final PickedReceipt? picked = await widget.receiptPicker.pick();
      if (!mounted || picked == null) {
        return;
      }
      setState(() {
        _receipt = picked;
        // Checked here rather than on submit, so the player is told before
        // waiting through an upload that the server would reject.
        _errorMessage = picked.isWithinLimit ? null : l10n.fileTooLarge;
      });
    } on Exception {
      if (mounted) {
        setState(() => _errorMessage = l10n.errorUnexpected);
      }
    }
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = context.l10n;
    final PickedReceipt? receipt = _receipt;

    if (receipt == null) {
      setState(() => _errorMessage = l10n.selectReceiptFirst);
      return;
    }
    if (!receipt.isWithinLimit) {
      setState(() => _errorMessage = l10n.fileTooLarge);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final ApiResponse<Booking> response =
          await _bookingService.uploadPaymentReceipt(
        bookingId: widget.booking.id,
        filePath: receipt.path,
      );

      if (!mounted) {
        return;
      }
      if (response.success) {
        await AppRouter.toBookingConfirmation(
          context,
          booking: response.data ?? widget.booking,
          venue: widget.venue,
          slot: widget.slot,
          date: widget.date,
        );
        return;
      }
      setState(
        () => _errorMessage = response.errorFor('receipt') ?? response.message,
      );
    } on ApiException catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = FailureMessages.of(exception, l10n));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
            const BookingStepper(current: BookingStep.payment),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.paymentTitle,
              textAlign: TextAlign.start,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 5),
            Text(
              l10n.paymentSubtitle,
              textAlign: TextAlign.start,
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            BookingSummaryCard(
              heading: l10n.bookingSummary,
              venue: widget.venue,
              dateLabel: BookingHeader.formatWeekday(widget.date),
              dateCaption: BookingHeader.formatDayMonth(widget.date),
              timeLabel: widget.slot.range,
              price: widget.slot.price ?? widget.venue.hourlyPrice,
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusField),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: ReceiptUploadBox(
                receipt: _receipt,
                onPick: _pickReceipt,
                onClear: () => setState(() {
                  _receipt = null;
                  _errorMessage = null;
                }),
              ),
            ),
            ErrorBanner(message: _errorMessage),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.white,
                      ),
                    )
                  : Text(l10n.sendPaymentProof),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
