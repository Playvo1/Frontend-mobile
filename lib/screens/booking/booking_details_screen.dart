import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_response.dart';
import '../../core/app_router.dart';
import '../../core/failure_messages.dart';
import '../../core/validators.dart';
import '../../l10n/l10n.dart';
import '../../models/booking.dart';
import '../../models/time_slot.dart';
import '../../models/venue.dart';
import '../../services/booking_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/back_circle_button.dart';
import '../../widgets/booking_stepper.dart';
import '../../widgets/booking_summary_card.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/playvo_logo.dart';

/// Step 1 of 3: who is booking. Creating the booking here returns its id,
/// which step 2 needs to attach the payment receipt to.
class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({
    super.key,
    required this.venue,
    required this.slot,
    required this.date,
    this.bookingService,
  });

  final Venue venue;
  final TimeSlot slot;
  final DateTime date;
  final BookingService? bookingService;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  late final BookingService _bookingService =
      widget.bookingService ?? BookingService.create();

  String? _role;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final ApiResponse<Booking> response = await _bookingService.createBooking(
        timeSlotId: widget.slot.id,
        captainName: _nameController.text.trim(),
        captainRole: _role!,
        captainPhone: _phoneController.text.trim(),
      );

      if (!mounted) {
        return;
      }
      final Booking? booking = response.data;
      if (response.success && booking != null) {
        AppRouter.toPaymentProof(
          context,
          booking: booking,
          venue: widget.venue,
          slot: widget.slot,
          date: widget.date,
        );
        return;
      }
      setState(
        () => _errorMessage =
            response.errorFor('time_slot_id') ?? response.message,
      );
    } on ApiException catch (exception) {
      if (!mounted) {
        return;
      }
      setState(
        () => _errorMessage = FailureMessages.of(exception, context.l10n),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _roleLabel(String role, AppLocalizations l10n) {
    switch (role) {
      case CaptainRole.captain:
        return l10n.roleCaptain;
      case CaptainRole.player:
        return l10n.rolePlayer;
      default:
        return l10n.roleOrganizer;
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            children: <Widget>[
              const BookingHeader(),
              const SizedBox(height: AppSpacing.lg),
              const BookingStepper(current: BookingStep.details),
              const SizedBox(height: AppSpacing.xl),
              // Aligned to the reading edge, as in the design, not centred.
              Text(
                l10n.bookingDetailsTitle,
                textAlign: TextAlign.start,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 5),
              Text(
                l10n.bookingDetailsSubtitle,
                textAlign: TextAlign.start,
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              BookingSummaryCard(
                venue: widget.venue,
                dateLabel: BookingHeader.formatWeekday(widget.date),
                dateCaption: BookingHeader.formatDayMonth(widget.date),
                timeLabel: widget.slot.range,
                price: widget.slot.price ?? widget.venue.hourlyPrice,
              ),
              const SizedBox(height: AppSpacing.xl),
              // A section heading, so it reads at the same weight as
              // "بيانات الحجز" above rather than like a field label.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.captainInfoTitle,
                  style: textTheme.headlineSmall?.copyWith(fontSize: 19),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _FieldLabel(label: l10n.fullNameLabel),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: l10n.fullNamePlaceholder,
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    size: 19,
                    color: AppColors.navy300,
                  ),
                ),
                validator: (String? value) => Validators.fullName(value, l10n),
              ),
              const SizedBox(height: AppSpacing.md),
              _FieldLabel(label: l10n.roleLabel),
              DropdownButtonFormField<String>(
                initialValue: _role,
                isExpanded: true,
                hint: Text(l10n.rolePlaceholder, style: textTheme.bodySmall),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.navy300,
                ),
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.groups_outlined,
                    size: 19,
                    color: AppColors.navy300,
                  ),
                ),
                items: CaptainRole.all
                    .map(
                      (String role) => DropdownMenuItem<String>(
                        value: role,
                        child: Text(_roleLabel(role, l10n)),
                      ),
                    )
                    .toList(),
                onChanged: (String? role) => setState(() => _role = role),
                validator: (String? value) =>
                    value == null ? l10n.roleRequired : null,
              ),
              const SizedBox(height: AppSpacing.md),
              _FieldLabel(label: l10n.phoneLabel),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: l10n.phonePlaceholder,
                  prefixIcon: const Icon(
                    Icons.call_outlined,
                    size: 19,
                    color: AppColors.navy300,
                  ),
                ),
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                        ? l10n.phoneRequired
                        : Validators.optionalPhone(value, l10n),
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
                    : Text(l10n.continueLabel),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// The small header the booking steps share: back chevron, logo, city.
class BookingHeader extends StatelessWidget {
  const BookingHeader({super.key, this.city = 'غزة'});

  final String city;

  static const List<String> _monthsAr = <String>[
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  static const List<String> _weekdaysAr = <String>[
    'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',
    'الجمعة', 'السبت', 'الأحد',
  ];

  /// "الأحد" — the bold line of the date column.
  static String formatWeekday(DateTime date) => _weekdaysAr[date.weekday - 1];

  /// "14 سبتمبر" — the smaller line under it.
  static String formatDayMonth(DateTime date) =>
      '${date.day} ${_monthsAr[date.month - 1]}';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.location_on,
              size: 15,
              color: AppColors.orange500,
            ),
            const SizedBox(width: 3),
            Text(city, style: Theme.of(context).textTheme.labelMedium),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 17,
              color: AppColors.navy900,
            ),
          ],
        ),
        // A small explicit gap: the proportional default tucks the
        // wordmark too close to the mark at this size.
        const PlayvoLogo(markHeight: 44, wordmarkSize: 13, gap: -3),
        const AppBackButton(size: 34),
      ],
    );
  }
}

/// A required-field caption above an input.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.navy900),
          ),
          const Text(
            ' *',
            style: TextStyle(color: AppColors.orange500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
