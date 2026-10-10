import 'package:flutter/material.dart';

/// The illustrations exported from Figma, referenced by name so no screen
/// hard-codes a file path.
///
/// A missing asset leaves a gap rather than crashing, so a packaging
/// mistake never takes a screen down.
class AppIllustration extends StatelessWidget {
  const AppIllustration({super.key, required this.asset, required this.height});

  final String asset;
  final double height;

  static const String assistantRobot =
      'assets/illustrations/assistant_robot.png';
  static const String ratingRobot = 'assets/illustrations/rating_robot.png';
  static const String dataProtection =
      'assets/illustrations/data_protection.png';
  static const String dataAccess = 'assets/illustrations/data_access.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox(height: height),
    );
  }
}
