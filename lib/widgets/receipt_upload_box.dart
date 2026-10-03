import 'dart:io';
// PathMetric comes from dart:ui; material re-exports most painting types
// but not this one.
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../core/receipt_picker.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The dashed drop area for the transfer receipt, and the row showing the
/// chosen file with its size and a button to remove it.
class ReceiptUploadBox extends StatelessWidget {
  const ReceiptUploadBox({
    super.key,
    required this.receipt,
    required this.onPick,
    required this.onClear,
  });

  final PickedReceipt? receipt;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final PickedReceipt? picked = receipt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.upload_file_outlined,
              size: 16,
              color: AppColors.navy500,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.uploadReceiptTitle,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(AppSpacing.radiusField),
          child: DottedBorderBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Column(
                children: <Widget>[
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 34,
                    color: AppColors.navy300,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.uploadReceiptHint,
                    textAlign: TextAlign.center,
                    style: textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.uploadReceiptFormats,
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (picked != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _PickedFileRow(receipt: picked, onClear: onClear),
        ],
      ],
    );
  }
}

/// A rounded rectangle with a dashed outline, drawn by [_DashedBorderPainter].
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

/// Flutter has no dashed border, so the outline is stroked by hand.
class _DashedBorderPainter extends CustomPainter {
  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.navy300
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final RRect rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppSpacing.radiusField),
    );

    final Path path = Path()..addRRect(rect);
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + _dash),
          paint,
        );
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The chosen receipt: thumbnail, name, size, and a button to drop it.
class _PickedFileRow extends StatelessWidget {
  const _PickedFileRow({required this.receipt, required this.onClear});

  final PickedReceipt receipt;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              File(receipt.path),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 40,
                height: 40,
                color: AppColors.grey100,
                child: const Icon(
                  Icons.receipt_long,
                  size: 18,
                  color: AppColors.navy300,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  receipt.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.navy900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  receipt.readableSize,
                  textDirection: TextDirection.ltr,
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: receipt.isWithinLimit
                        ? AppColors.navy300
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 18, color: AppColors.navy300),
          ),
        ],
      ),
    );
  }
}
