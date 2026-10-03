import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The three stages of a reservation, numbered across the top of the
/// booking screens: details, payment proof, confirmation.
enum BookingStep { details, payment, confirmation }

/// Shows where the player is in the booking flow. Finished steps carry a
/// tick, the current one is orange, the rest stay grey.
class BookingStepper extends StatelessWidget {
  const BookingStepper({super.key, required this.current});

  final BookingStep current;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<String> labels = <String>[
      l10n.stepBookingDetails,
      l10n.stepPayment,
      l10n.stepConfirmation,
    ];

    // Step 1 sits on the LEFT in the design, so the row is laid out
    // left-to-right regardless of the app's direction. The labels inside
    // stay Arabic and render normally.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List<Widget>.generate(labels.length * 2 - 1, (int index) {
          if (index.isOdd) {
            final int previous = index ~/ 2;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Container(
                  height: 1.5,
                  color: previous < current.index
                      ? AppColors.orange500
                      : AppColors.grey200,
                ),
              ),
            );
          }

          final int step = index ~/ 2;
          return _Step(
            number: step + 1,
            label: labels[step],
            isDone: step < current.index,
            isCurrent: step == current.index,
          );
        }),
      ),
    );
  }
}

/// One numbered circle with its caption.
class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.label,
    required this.isDone,
    required this.isCurrent,
  });

  final int number;
  final String label;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final bool isActive = isDone || isCurrent;
    final Color color = isActive ? AppColors.orange500 : AppColors.grey400;

    return SizedBox(
      width: 78,
      child: Column(
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent ? AppColors.orange500 : AppColors.white,
              border: Border.all(color: color, width: 1.6),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 17, color: AppColors.orange500)
                  : Text(
                      '$number',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isCurrent ? AppColors.white : color,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: isActive ? AppColors.navy900 : AppColors.grey400,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
