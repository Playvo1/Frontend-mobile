import 'package:flutter/material.dart';

import '../core/app_router.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The floating assistant button that sits above the bottom bar on the
/// browsing screens.
///
/// It carries a label the first time it appears and collapses to the round
/// icon after a few seconds, so it announces itself once without standing
/// in front of the content for the whole session.
class AssistantFab extends StatefulWidget {
  const AssistantFab({super.key, this.showLabel = true});

  /// Set false where the label would collide with content.
  final bool showLabel;

  @override
  State<AssistantFab> createState() => _AssistantFabState();
}

class _AssistantFabState extends State<AssistantFab> {
  bool _isLabelVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.showLabel) {
      _isLabelVisible = true;
      // Collapsing is cosmetic, so a missing frame is harmless; the guard
      // is only there because the timer outlives a quick pop.
      Future<void>.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _isLabelVisible = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // The button leads the row so it sits on the anchored edge — right
        // in Arabic, left in English — with the bubble trailing beside it.
        _Button(
          onTap: () => AppRouter.toAssistant(context),
          onLongPress: () => setState(() => _isLabelVisible = !_isLabelVisible),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: _isLabelVisible
              ? Padding(
                  padding:
                      const EdgeInsetsDirectional.only(start: AppSpacing.sm),
                  child: _Bubble(
                    label: l10n.assistantFabLabel,
                    tag: l10n.assistantFabTag,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// "تحدث مع المساعد الذكي" with its live dot and badge.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.label, required this.tag});

  final String label;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.navy900,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.navy900.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.orange500.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.orange500,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// The round orange button with its halo and online dot.
class _Button extends StatelessWidget {
  const _Button({required this.onTap, required this.onLongPress});

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // The halo is a ring, not a shadow, so it stays visible on a
            // white list background.
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
                border: Border.all(color: AppColors.orange500, width: 2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.orange500.withValues(alpha: 0.28),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange500,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 26,
                color: AppColors.white,
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
