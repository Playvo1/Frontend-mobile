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
        child: Icon(
          Icons.chevron_left,
          size: size * 0.55,
          color: AppColors.navy900,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                style: textTheme.headlineSmall,
              ),
            ),
            AppBackButton(onPressed: onBack),
          ],
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 5),
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
