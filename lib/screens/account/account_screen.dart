import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/app_router.dart';
import '../../core/locale_controller.dart';
import '../../l10n/l10n.dart';
import '../../models/booking.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/venue_photo.dart';

/// "حسابي" — the player's profile, their past matches, and the settings
/// list that ends in log out.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, this.authService, this.bookingService});

  final AuthService? authService;
  final BookingService? bookingService;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();
  late final BookingService _bookingService =
      widget.bookingService ?? BookingService.create();

  User? _user;
  List<Booking> _pastMatches = <Booking>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final User? user = (await _authService.me()).data;
      final List<Booking> bookings =
          (await _bookingService.myBookings()).data ?? <Booking>[];
      if (!mounted) {
        return;
      }
      setState(() {
        _user = user;
        // Only finished games belong in the history list.
        _pastMatches = bookings
            .where((Booking b) => b.status == BookingStatus.completed)
            .toList();
      });
    } on ApiException {
      // The screen still renders; the profile block simply stays empty.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logOut() async {
    try {
      await _authService.logout();
    } on ApiException {
      // The token is cleared locally either way.
    }
    if (mounted) {
      await AppRouter.toLoginAndClearStack(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: AppBottomNav(
        current: AppTab.account,
        onSelected: (AppTab tab) => AppRouter.switchTab(context, tab),
      ),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                children: <Widget>[
                  AppScreenHeader(title: l10n.accountTitle),
                  const SizedBox(height: AppSpacing.lg),
                  _ProfileCard(
                    user: _user,
                    onEdit: () => AppRouter.toEditProfile(context, _user),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionHeader(
                    icon: Icons.history,
                    title: l10n.matchHistory,
                    actionLabel: l10n.viewAllShort,
                    onAction: () =>
                        AppRouter.switchTab(context, AppTab.bookings),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ..._pastMatches.map(
                    (Booking booking) => _MatchCard(booking: booking),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(icon: Icons.settings_outlined, title: l10n.settings),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsList(onLogOut: _logOut),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
      ),
    );
  }
}

/// Name, contact details, avatar, and the edit action.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.onEdit});

  final User? user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navy50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusField),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      user?.name ?? '',
                      style: textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    _ContactLine(
                      icon: Icons.mail_outline,
                      value: user?.email ?? '',
                    ),
                    if ((user?.phone ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      _ContactLine(
                        icon: Icons.call_outlined,
                        value: user!.phone!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const _Avatar(size: 64),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.edit_outlined, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.editProfile),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One contact row: the value with its icon on the outer edge.
class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11),
          ),
        ),
        const SizedBox(width: 4),
        Icon(icon, size: 13, color: AppColors.navy300),
      ],
    );
  }
}

/// The circular avatar with its camera badge.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.size, this.onTapCamera});

  final double size;
  final VoidCallback? onTapCamera;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: <Widget>[
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: AppColors.grey200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: size * 0.55,
              color: AppColors.navy300,
            ),
          ),
          PositionedDirectional(
            bottom: 0,
            start: 0,
            child: InkWell(
              onTap: onTapCamera,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.navy900,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: Icon(
                  Icons.photo_camera_outlined,
                  size: size * 0.2,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A section title, with an optional trailing link.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              title,
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 5),
            Icon(icon, size: 16, color: AppColors.navy500),
          ],
        ),
        if (actionLabel != null)
          InkWell(
            onTap: onAction,
            child: Row(
              children: <Widget>[
                Text(
                  actionLabel!,
                  style: textTheme.labelSmall?.copyWith(fontSize: 11),
                ),
                const Icon(
                  Icons.chevron_left,
                  size: 15,
                  color: AppColors.navy300,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One finished match in the history list.
class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DateTime date = booking.date ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.statusCompletedBackground,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Text(
              l10n.matchCompleted,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.statusCompleted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  booking.venue?.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${date.day}/${date.month}/${date.year}  ·  '
                  '${booking.slot?.range ?? ''}',
                  textDirection: TextDirection.ltr,
                  style: textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 68,
            height: 48,
            child: VenuePhoto(
              url: booking.venue?.coverPhoto,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
          ),
        ],
      ),
    );
  }
}

/// The settings rows, ending with log out.
class _SettingsList extends StatelessWidget {
  const _SettingsList({required this.onLogOut});

  final VoidCallback onLogOut;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusField),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: <Widget>[
          _SettingsRow(
            icon: Icons.notifications_none,
            label: l10n.settingsNotifications,
            onTap: () {},
          ),
          const Divider(height: 1),
          _SettingsRow(
            icon: Icons.language,
            label: l10n.settingsLanguage,
            value: l10n.languageLabel,
            onTap: LocaleController.toggle,
          ),
          const Divider(height: 1),
          _SettingsRow(
            icon: Icons.shield_outlined,
            label: l10n.settingsPrivacy,
            onTap: () {},
          ),
          const Divider(height: 1),
          _SettingsRow(
            icon: Icons.help_outline,
            label: l10n.settingsSupport,
            onTap: () {},
          ),
          const Divider(height: 1),
          _SettingsRow(
            icon: Icons.logout,
            label: l10n.logOut,
            color: AppColors.orange500,
            onTap: onLogOut,
          ),
        ],
      ),
    );
  }
}

/// One settings row: label and icon on the right, value on the left.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color tint = color ?? AppColors.navy900;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: textTheme.labelMedium?.copyWith(color: tint),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: textTheme.labelSmall?.copyWith(fontSize: 11),
              ),
            const SizedBox(width: AppSpacing.sm),
            Icon(icon, size: 19, color: tint),
          ],
        ),
      ),
    );
  }
}
