import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';

/// The five player tabs from the design. Only [AppTab.home] is built so
/// far; the screen decides what to do with the rest, so this widget stays a
/// dumb bar.
enum AppTab { account, favorites, bookings, explore, home }

/// The bottom navigation bar shared by every player screen.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    required this.onSelected,
  });

  final AppTab current;
  final ValueChanged<AppTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.fieldBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            // Home first: in Arabic the first child sits on the RIGHT, which
            // is where the design puts it, with the account tab on the left.
            _NavItem(
              tab: AppTab.home,
              icon: Icons.home_filled,
              label: l10n.navHome,
              current: current,
              onSelected: onSelected,
            ),
            _NavItem(
              tab: AppTab.explore,
              icon: Icons.search,
              label: l10n.navExplore,
              current: current,
              onSelected: onSelected,
            ),
            _NavItem(
              tab: AppTab.bookings,
              icon: Icons.calendar_today_outlined,
              label: l10n.navBookings,
              current: current,
              onSelected: onSelected,
            ),
            _NavItem(
              tab: AppTab.favorites,
              icon: Icons.favorite_border,
              label: l10n.navFavorites,
              current: current,
              onSelected: onSelected,
            ),
            _NavItem(
              tab: AppTab.account,
              icon: Icons.person_outline,
              label: l10n.navAccount,
              current: current,
              onSelected: onSelected,
            ),
          ],
        ),
      ),
    );
  }
}

/// One tab: icon, label, and the orange underline on the active one.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.icon,
    required this.label,
    required this.current,
    required this.onSelected,
  });

  final AppTab tab;
  final IconData icon;
  final String label;
  final AppTab current;
  final ValueChanged<AppTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final bool isActive = tab == current;
    final Color color = isActive ? AppColors.orange500 : AppColors.navy300;

    return Expanded(
      child: InkWell(
        onTap: () => onSelected(tab),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 18,
                height: 2,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.orange500 : AppColors.white,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
