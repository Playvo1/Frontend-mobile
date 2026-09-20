import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The Playvo mark above the two-tone wordmark.
///
/// The wordmark takes its family from [AppTheme.fontFamily] rather than the
/// literal 'Cairo', so it can never silently fall back to a different font
/// than the rest of the app.
///
/// `height: 1.0` is deliberate. Cairo carries a large ascent to leave room
/// for Arabic diacritics, and that empty space would otherwise sit between
/// the mark and the word. Pinning the line box to the font size keeps the
/// wordmark tucked under the mark the way the brand lockup is drawn.
class PlayvoLogo extends StatelessWidget {
  const PlayvoLogo({
    super.key,
    this.markHeight = 130,
    this.wordmarkSize = 30,
    this.gap = -30,
  });

  final double markHeight;
  final double wordmarkSize;

  /// Fine-tuning for the distance between the mark and the wordmark.
  /// Negative values pull the word up; it is drawn, not laid out, so the
  /// widget's own height does not change.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final TextStyle? base = Theme.of(context).textTheme.displaySmall;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.asset(
          'assets/logo/playvo_mark.png',
          height: markHeight,
          errorBuilder: (_, __, ___) => SizedBox(height: markHeight),
        ),
        Transform.translate(
          offset: Offset(0, gap),
          child: Text.rich(
            TextSpan(
              style: base?.copyWith(
                fontSize: wordmarkSize,
                fontFamily: AppTheme.fontFamily,
                height: 1,
              ),
              children: const <InlineSpan>[
                TextSpan(
                  text: 'Play',
                  style: TextStyle(color: AppColors.navy900),
                ),
                TextSpan(
                  text: 'vo',
                  style: TextStyle(color: AppColors.orange500),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    );
  }
}