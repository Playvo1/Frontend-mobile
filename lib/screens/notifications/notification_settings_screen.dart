import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_button.dart';

/// "إعدادات الإشعارات" — the master switch and the per-type switches.
///
/// TODO(api): preferences are held in memory only. There is no endpoint to
/// store them yet; point [_save] at one once the backend adds it, and read
/// the saved values on open.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _allEnabled = true;
  bool _bookingConfirmed = true;
  bool _bookingReminder = true;
  bool _offers = true;

  /// Turning the master switch off disables the whole list rather than
  /// clearing it, so the player's per-type choices survive being switched
  /// back on.
  void _setAll(bool value) => setState(() => _allEnabled = value);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: <Widget>[
            AppScreenHeader(
              title: l10n.notificationSettingsTitle,
              centerTitle: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            _SwitchCard(
              icon: Icons.notifications_none,
              title: l10n.notificationsMaster,
              body: l10n.notificationsMasterBody,
              value: _allEnabled,
              onChanged: _setAll,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.notificationTypes,
              style: textTheme.labelMedium?.copyWith(color: AppColors.navy500),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SwitchCard(
              icon: Icons.event_available_outlined,
              title: l10n.notifyBookingConfirmed,
              body: l10n.notifyBookingConfirmedBody,
              value: _bookingConfirmed,
              isEnabled: _allEnabled,
              onChanged: (bool v) => setState(() => _bookingConfirmed = v),
            ),
            _SwitchCard(
              icon: Icons.notifications_active_outlined,
              title: l10n.notifyBookingReminder,
              body: l10n.notifyBookingReminderBody,
              value: _bookingReminder,
              isEnabled: _allEnabled,
              onChanged: (bool v) => setState(() => _bookingReminder = v),
            ),
            _SwitchCard(
              icon: Icons.campaign_outlined,
              title: l10n.notifyOffers,
              body: l10n.notifyOffersBody,
              value: _offers,
              isEnabled: _allEnabled,
              onChanged: (bool v) => setState(() => _offers = v),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row: tinted icon, title and body, and the switch on the far side.
class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.value,
    required this.onChanged,
    this.isEnabled = true,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// False greys the row out while the master switch is off.
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color tint = isEnabled ? AppColors.navy900 : AppColors.grey400;

    return Opacity(
      opacity: isEnabled ? 1 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusField),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.successAccentHalo,
                borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
              ),
              child: Icon(icon, size: 20, color: AppColors.successAccent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700, color: tint),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: textTheme.labelSmall?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Switch(
              value: value,
              onChanged: isEnabled ? onChanged : null,
              thumbColor: const WidgetStatePropertyAll<Color>(AppColors.white),
              trackColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) =>
                    states.contains(WidgetState.selected)
                        ? AppColors.successAccent
                        : AppColors.grey200,
              ),
              trackOutlineColor:
                  const WidgetStatePropertyAll<Color>(Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }
}
