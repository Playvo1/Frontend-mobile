import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The round back button used at the top of every screen.
///
/// The design places it on the LEFT with a left-pointing chevron on every
/// screen, so this widget hard-codes both rather than following the reading
/// direction — that is what kept flipping it. The one exception is the navy
/// "الملاعب المتاحة" bar, which draws its own on the right.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed, this.size = 36});

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
        decoration: BoxDecoration(
          color: AppColors.grey100,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.fieldBorder),
        ),
        // Flutter mirrors chevron icons automatically in RTL
        // (matchTextDirection), which is what kept flipping this arrow no
        // matter how the row was ordered. Forcing LTR here pins it.
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Icon(
            Icons.chevron_left,
            size: size * 0.55,
            color: AppColors.navy900,
          ),
        ),
      ),
    );
  }
}

/// A row with the back button pinned to the left and the title filling the
/// rest, so headers line up the same way everywhere.
class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.centerTitle = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    // The back button sits on its own row so the title clears it, which is
    // how every screen in the design is laid out.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Physically left, not "end": in English, end resolves to the right
        // and the button jumps sides. The design keeps it left in both
        // languages, so this alignment is physical on purpose.
        Align(
          alignment: Alignment.centerLeft,
          child: AppBackButton(onPressed: onBack),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: centerTitle ? TextAlign.center : TextAlign.start,
          style: textTheme.headlineSmall,
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: centerTitle ? TextAlign.center : TextAlign.start,
            style: textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
