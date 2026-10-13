import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The blue tick with its halo and the short rays around it, used by every
/// confirmation screen so they all look the same.
///
/// [SuccessMark.pending] is the same mark in amber with an hourglass, for a
/// step that has been *received* but not yet approved. The two must not be
/// interchangeable by accident: a tick is the loudest element on the screen
/// and reads as "done" no matter what the text underneath says.
class SuccessMark extends StatelessWidget {
  const SuccessMark({super.key, this.size = 96}) : _isPending = false;

  /// Amber hourglass: the request went through, the outcome has not.
  const SuccessMark.pending({super.key, this.size = 96}) : _isPending = true;

  /// Diameter of the halo; the rays sit outside it.
  final double size;

  final bool _isPending;

  @override
  Widget build(BuildContext context) {
    // The rays need room outside the halo, so the widget is wider than it.
    final double extent = size * 1.7;
    final Color accent =
        _isPending ? AppColors.warning : AppColors.successAccent;
    final Color halo =
        _isPending ? AppColors.orange50 : AppColors.successAccentHalo;

    return SizedBox(
      width: extent,
      height: extent,
      child: CustomPaint(
        painter: _RayPainter(haloRadius: size / 2, colour: accent),
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: halo),
            child: Center(
              child: Container(
                width: size * 0.66,
                height: size * 0.66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
                child: Icon(
                  _isPending ? Icons.hourglass_top_rounded : Icons.check_rounded,
                  color: AppColors.white,
                  size: size * 0.38,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Eight short strokes radiating from the halo, skipping the four points
/// the design leaves clear.
class _RayPainter extends CustomPainter {
  const _RayPainter({required this.haloRadius, required this.colour});

  final double haloRadius;
  final Color colour;

  /// Angles in degrees, measured clockwise from twelve o'clock.
  static const List<double> _angles = <double>[
    25, 45, 65, 115, 135, 155, 205, 225, 245, 295, 315, 335,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final Paint paint = Paint()
      ..color = colour
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final double start = haloRadius + 6;
    final double end = start + haloRadius * 0.26;

    for (final double degrees in _angles) {
      final double radians = degrees * math.pi / 180;
      final Offset direction = Offset(math.sin(radians), -math.cos(radians));
      canvas.drawLine(centre + direction * start, centre + direction * end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RayPainter oldDelegate) =>
      oldDelegate.haloRadius != haloRadius || oldDelegate.colour != colour;
}
