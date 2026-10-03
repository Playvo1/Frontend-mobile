import 'package:flutter/material.dart';

import '../core/offline_state.dart';
import '../core/sync_time_format.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The strip shown above a list when it is being served from the cache, so
/// the player knows the data is not live and how old it is (SRS FR-35).
///
/// Renders nothing while the app is online, so screens can keep it in the
/// tree unconditionally.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OfflineState.isOffline,
      builder: (BuildContext context, bool isOffline, Widget? child) {
        if (!isOffline) {
          return const SizedBox.shrink();
        }
        return ValueListenableBuilder<DateTime?>(
          valueListenable: OfflineState.lastSyncedAt,
          builder: (BuildContext context, DateTime? syncedAt, Widget? _) {
            final AppLocalizations l10n = context.l10n;
            final TextTheme textTheme = Theme.of(context).textTheme;

            return InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange50,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 17,
                      color: AppColors.orange700,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l10n.offlineTitle,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.orange700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (syncedAt != null)
                            Text(
                              '${l10n.lastUpdated}: '
                              '${SyncTimeFormat.label(syncedAt, l10n)}',
                              style: textTheme.labelSmall
                                  ?.copyWith(fontSize: 10),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_left,
                      size: 17,
                      color: AppColors.orange700,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
