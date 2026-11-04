import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_response.dart';
import '../../core/failure_messages.dart';
import '../../core/sync_time_format.dart';
import '../../l10n/l10n.dart';
import '../../models/app_notification.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/fixed_chevron.dart';
import '../../widgets/infinite_scroll.dart';

/// "الإشعارات" — the inbox, grouped by day (SRS FR-10, FR-11, FR-12).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.notificationService});

  final NotificationService? notificationService;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationService _service =
      widget.notificationService ?? NotificationService.create();

  List<AppNotification> _items = <AppNotification>[];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _errorMessage;

  /// A page shorter than this is the last one.
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _page = 1;
      _hasMore = true;
    });

    try {
      final ApiResponse<List<AppNotification>> response = await _service.list();
      if (!mounted) {
        return;
      }
      if (response.success) {
        final List<AppNotification> items =
            response.data ?? <AppNotification>[];
        setState(() {
          _items = items;
          _hasMore = response.hasMorePages ?? items.length >= _pageSize;
        });
        return;
      }
      setState(() => _errorMessage = response.message);
    } on ApiException catch (exception) {
      if (!mounted) {
        return;
      }
      setState(
        () => _errorMessage = FailureMessages.of(exception, context.l10n),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) {
      return;
    }
    setState(() => _isLoadingMore = true);

    try {
      final ApiResponse<List<AppNotification>> response =
          await _service.list(page: _page + 1);
      if (!mounted) {
        return;
      }
      final List<AppNotification> next = response.data ?? <AppNotification>[];
      setState(() {
        if (response.success) {
          _page += 1;
          _items = <AppNotification>[..._items, ...next];
        }
        _hasMore = response.success &&
            (response.hasMorePages ?? next.length >= _pageSize);
      });
    } on ApiException {
      if (mounted) {
        setState(() => _hasMore = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  /// Marks one read on the server first; the row only changes once that
  /// succeeds, so the badge never lies about what the server holds.
  Future<void> _markRead(AppNotification item) async {
    if (item.isRead) {
      return;
    }
    try {
      final ApiResponse<void> response = await _service.markRead(item.id);
      if (!mounted || !response.success) {
        return;
      }
      setState(() {
        _items = _items
            .map((AppNotification n) =>
                n.id == item.id ? n.copyWith(isRead: true) : n)
            .toList();
      });
    } on ApiException {
      // Leaving it unread is the honest outcome of a failed write.
    }
  }

  /// Splits the list into today, yesterday and older, dropping any group
  /// that has nothing in it.
  Map<String, List<AppNotification>> _grouped(AppLocalizations l10n) {
    final DateTime now = DateTime.now();
    final Map<String, List<AppNotification>> groups =
        <String, List<AppNotification>>{};

    // Seeded in display order first: a Map keeps insertion order, so
    // building it from an unsorted response would otherwise put older
    // notifications above today's.
    for (final String label in <String>[
      l10n.groupToday,
      l10n.groupYesterday,
      l10n.groupLastWeek,
    ]) {
      groups[label] = <AppNotification>[];
    }

    for (final AppNotification item in _items) {
      final DateTime at = item.createdAt ?? now;
      final int days = DateTime(now.year, now.month, now.day)
          .difference(DateTime(at.year, at.month, at.day))
          .inDays;
      final String label = days <= 0
          ? l10n.groupToday
          : days == 1
              ? l10n.groupYesterday
              : l10n.groupLastWeek;
      groups[label]!.add(item);
    }

    groups.removeWhere(
      (String _, List<AppNotification> items) => items.isEmpty,
    );
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: AppScreenHeader(
                title: l10n.notificationsTitle,
                centerTitle: true,
              ),
            ),
            Expanded(child: _buildBody(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty && _errorMessage == null) {
      return SingleChildScrollView(
        child: EmptyState(
          icon: Icons.notifications_none,
          title: l10n.notificationsEmptyTitle,
          subtitle: l10n.notificationsEmptyBody,
        ),
      );
    }

    final Map<String, List<AppNotification>> groups = _grouped(l10n);

    return InfiniteScroll(
      canLoadMore: _hasMore && !_isLoadingMore,
      onLoadMore: _loadMore,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            0,
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
          ),
          children: <Widget>[
            ErrorBanner(message: _errorMessage),
            for (final MapEntry<String, List<AppNotification>> group
                in groups.entries)
              _Group(
                label: group.key,
                items: group.value,
                onTap: _markRead,
              ),
            LoadMoreFooter(isLoading: _isLoadingMore),
          ],
        ),
      ),
    );
  }
}

/// A day heading with its notifications under it.
class _Group extends StatelessWidget {
  const _Group({
    required this.label,
    required this.items,
    required this.onTap,
  });

  final String label;
  final List<AppNotification> items;
  final ValueChanged<AppNotification> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: AppColors.navy500),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map(
          (AppNotification item) =>
              _NotificationCard(item: item, onTap: () => onTap(item)),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

/// One notification row.
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  /// The icon and tint each kind is drawn with.
  static ({IconData icon, Color color, Color background}) _style(String type) {
    switch (type) {
      case NotificationType.bookingConfirmed:
        return (
          icon: Icons.event_available_outlined,
          color: AppColors.statusCompleted,
          background: AppColors.statusCompletedBackground,
        );
      case NotificationType.bookingReminder:
        return (
          icon: Icons.notifications_none,
          color: AppColors.successAccent,
          background: AppColors.successAccentHalo,
        );
      case NotificationType.offer:
        return (
          icon: Icons.local_offer_outlined,
          color: AppColors.statusCancelled,
          background: AppColors.statusCancelledBackground,
        );
      case NotificationType.matchFinished:
        return (
          icon: Icons.sports_soccer,
          color: const Color(0xFF8B5CF6),
          background: const Color(0xFFF1EBFE),
        );
      default:
        return (
          icon: Icons.campaign_outlined,
          color: AppColors.orange500,
          background: AppColors.orange50,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ({IconData icon, Color color, Color background}) style =
        _style(item.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusField),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusField),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: style.background,
                    borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
                  ),
                  child: Icon(style.icon, size: 20, color: style.color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              item.title,
                              style: textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (item.createdAt != null)
                            Text(
                              SyncTimeFormat.label(item.createdAt!, l10n),
                              style:
                                  textTheme.labelSmall?.copyWith(fontSize: 10),
                            ),
                          if (!item.isRead) ...<Widget>[
                            const SizedBox(width: 5),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.successAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.body,
                        style: textTheme.labelSmall?.copyWith(height: 1.7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FixedChevron(size: 17, color: AppColors.navy300),
            ),
          ],
        ),
      ),
    );
  }
}
