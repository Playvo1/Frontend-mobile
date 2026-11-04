import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/app_router.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/diagnostics_panel.dart';
import '../../widgets/language_sheet.dart';
import '../../l10n/l10n.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/fixed_chevron.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/app_bottom_nav.dart';

/// "حسابي" — the player's profile, their past matches, and the settings
/// list that ends in log out.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();

  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final User? user = (await _authService.me()).data;
      if (!mounted) {
        return;
      }
      setState(() => _user = user);
    } on ApiException {
      // The screen still renders; the profile block simply stays empty.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Adopts whatever the edit screen saved, so the card shows the server's
  /// version the moment the player comes back.
  Future<void> _openEditProfile() async {
    await AppRouter.toEditProfile(context, _user);
    if (mounted) {
      await _load();
    }
  }

  Future<void> _logOut() async {
    final AppLocalizations l10n = context.l10n;
    final bool confirmed = await ConfirmDialog.show(
      context,
      icon: Icons.logout,
      title: l10n.logoutConfirmTitle,
      body: l10n.logoutConfirmBody,
      confirmLabel: l10n.logOut,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed) {
      return;
    }

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
                    onEdit: _openEditProfile,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionHeader(icon: Icons.settings_outlined, title: l10n.settings),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsList(onLogOut: _logOut),
                  // Debug builds only: shows what /player/profile answered.
                  const DiagnosticsPanel(),
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
          // The avatar leads the row, which puts it on the right in Arabic,
          // with the name and contact details to its left.
          Row(
            children: <Widget>[
              _Avatar(size: 64, photoUrl: user?.photoUrl),
              const SizedBox(width: AppSpacing.md),
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
  const _Avatar({required this.size, this.onTapCamera, this.photoUrl});

  final double size;
  final VoidCallback? onTapCamera;
  final String? photoUrl;

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
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppColors.grey200,
              shape: BoxShape.circle,
            ),
            child: photoUrl == null
                ? Icon(
                    Icons.person,
                    size: size * 0.55,
                    color: AppColors.navy300,
                  )
                : Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    // A broken link must not leave a grey hole where a
                    // face should be.
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person,
                      size: size * 0.55,
                      color: AppColors.navy300,
                    ),
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
                const FixedChevron(size: 15, color: AppColors.navy300),
              ],
            ),
          ),
      ],
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
            onTap: () => AppRouter.toNotificationSettings(context),
          ),
          const Divider(height: 1),
          _SettingsRow(
            icon: Icons.language,
            label: l10n.settingsLanguage,
            value: l10n.languageLabel,
            onTap: () => LanguageSheet.show(context),
          ),
          const Divider(height: 1),
          _SettingsRow(
            icon: Icons.shield_outlined,
            label: l10n.settingsPrivacy,
            onTap: () => AppRouter.toPrivacySecurity(context),
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
        // Icon then label, so they stay together on the reading edge; the
        // value is pushed to the far side.
        child: Row(
          children: <Widget>[
            Icon(icon, size: 19, color: tint),
            const SizedBox(width: AppSpacing.md),
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
          ],
        ),
      ),
    );
  }
}
