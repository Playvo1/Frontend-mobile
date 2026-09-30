import 'package:flutter/material.dart';

import '../core/offline_state.dart';
import '../core/sync_time_format.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/back_circle_button.dart';

/// Shown when the app cannot reach the API. It names exactly what is
/// cached, so the player knows what still works offline (SRS FR-34/FR-35,
/// which also require the last sync time to be visible).
class OfflineScreen extends StatelessWidget {
  const OfflineScreen({
    super.key,
    required this.onContinueOffline,
    required this.onRetry,
    this.lastSyncedLabel,
  });

  final VoidCallback onContinueOffline;
  final VoidCallback onRetry;

  /// Overrides the time from SYNC_STATUS — used by the gallery to show a
  /// fixed value. Null lets the real cache time through.
  final String? lastSyncedLabel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: AppBottomNav(
        current: AppTab.home,
        onSelected: (AppTab _) => onContinueOffline(),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              // Centres the block on a tall screen but still scrolls on a
              // short one, instead of stranding it near the top.
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: BackCircleButton(),
                      ),
                      const Spacer(),
                      Text(
                        l10n.offlineTitle,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.offlineSubtitle,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(height: 1.8),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ValueListenableBuilder<DateTime?>(
              valueListenable: OfflineState.lastSyncedAt,
              builder: (BuildContext context, DateTime? syncedAt, Widget? _) {
                return _CachedDataCard(
                  lastSyncedLabel: lastSyncedLabel ??
                      (syncedAt == null
                          ? null
                          : SyncTimeFormat.label(syncedAt, l10n)),
                );
              },
            ),
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton(
              onPressed: onContinueOffline,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.arrow_back, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.continueOffline),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.refresh, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.tryAgain),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The panel listing what is available from the cache.
class _CachedDataCard extends StatelessWidget {
  const _CachedDataCard({required this.lastSyncedLabel});

  final String? lastSyncedLabel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.navy50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusField),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.savedDataTitle,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(l10n.savedDataSubtitle, style: textTheme.labelSmall),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              _CachedItem(
                icon: Icons.sports_soccer,
                background: AppColors.statusCompletedBackground,
                color: AppColors.statusCompleted,
                title: l10n.savedSports,
                body: l10n.savedSportsBody,
              ),
              _CachedItem(
                icon: Icons.payments_outlined,
                background: AppColors.orange50,
                color: AppColors.orange500,
                title: l10n.savedPrices,
                body: l10n.savedPricesBody,
              ),
              _CachedItem(
                icon: Icons.stadium_outlined,
                background: AppColors.successAccentHalo,
                color: AppColors.successAccent,
                title: l10n.savedVenues,
                body: l10n.savedVenuesBody,
              ),
            ],
          ),
          if (lastSyncedLabel != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  lastSyncedLabel!,
                  style: textTheme.labelSmall?.copyWith(fontSize: 11),
                ),
                const SizedBox(width: 5),
                Text(
                  '•',
                  style: textTheme.labelSmall?.copyWith(fontSize: 11),
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.lastUpdated,
                  style: textTheme.labelSmall?.copyWith(fontSize: 11),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.schedule,
                  size: 13,
                  color: AppColors.navy300,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One of the three cached-data tiles.
class _CachedItem extends StatelessWidget {
  const _CachedItem({
    required this.icon,
    required this.background,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color background;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: background, shape: BoxShape.circle),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(fontSize: 10, height: 1.5),
          ),
        ],
      ),
    );
  }
}
