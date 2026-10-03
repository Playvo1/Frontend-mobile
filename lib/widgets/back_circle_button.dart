import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The round back button the designs put at the TOP-LEFT of a screen, with
/// a left-pointing chevron.
///
/// It exists so the direction stops being decided per screen: in Arabic the
/// instinct is to mirror it to the right, but the design keeps it left on
/// every screen except the navy results bar, which draws its own.
class BackCircleButton extends StatelessWidget {
  const BackCircleButton({super.key, this.onPressed, this.size = 38});

  /// Defaults to popping the current route.
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.grey100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.chevron_left,
          size: size * 0.55,
          color: AppColors.navy900,
        ),
      ),
    );
  }
}
