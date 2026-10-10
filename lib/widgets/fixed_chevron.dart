import 'package:flutter/material.dart';

/// A chevron that points the way it is asked to, regardless of the app's
/// reading direction.
///
/// Flutter declares its chevron icons with `matchTextDirection`, so a plain
/// `Icon(Icons.chevron_left)` silently flips to point right in Arabic. Any
/// arrow whose direction is a design decision — a back button, a "more"
/// affordance — has to be pinned like this.
class FixedChevron extends StatelessWidget {
  const FixedChevron({
    super.key,
    this.pointsLeft = true,
    this.size = 18,
    this.color,
  });

  final bool pointsLeft;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Icon(
        pointsLeft ? Icons.chevron_left : Icons.chevron_right,
        size: size,
        color: color,
      ),
    );
  }
}
