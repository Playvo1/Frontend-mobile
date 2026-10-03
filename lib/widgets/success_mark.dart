import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The blue tick with its halo and the short rays around it, used by every
/// confirmation screen so they all look the same.
class SuccessMark extends StatelessWidget {
  const SuccessMark({super.key, this.size = 96});

  /// Diameter of the halo; the rays sit outside it.
  final double size;

  @override
  Widget build(BuildContext context) {
    // The rays need room outside the halo, so the widget is wider than it.
    final double extent = size * 1.7;

    return SizedBox(
      width: extent,
      height: extent,
      child: CustomPaint(
        painter: _RayPainter(haloRadius: size / 2),
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.successAccentHalo,
            ),
            child: Center(
              child: Container(
                width: size * 0.66,
                height: size * 0.66,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.successAccent,
                ),
                child: Icon(
                  Icons.check_rounded,
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
  const _RayPainter({required this.haloRadius});

  final double haloRadius;

  /// Angles in degrees, measured clockwise from twelve o'clock.
  static const List<double> _angles = <double>[
    25, 45, 65, 115, 135, 155, 205, 225, 245, 295, 315, 335,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final Paint paint = Paint()
      ..color = AppColors.successAccent
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
      oldDelegate.haloRadius != haloRadius;
}
