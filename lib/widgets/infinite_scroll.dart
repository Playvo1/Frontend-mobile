import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Calls [onLoadMore] when the reader nears the end of [child].
///
/// Written as a notification listener rather than a ScrollController so it
/// wraps any scrollable without the screen having to own and dispose one.
class InfiniteScroll extends StatelessWidget {
  const InfiniteScroll({
    super.key,
    required this.child,
    required this.onLoadMore,
    required this.canLoadMore,
  });

  final Widget child;
  final VoidCallback onLoadMore;

  /// False while a page is in flight or once the last page has arrived, so
  /// the callback does not fire on every scroll frame.
  final bool canLoadMore;

  /// How close to the end counts as "nearly there", in logical pixels. Far
  /// enough ahead that the next page is usually ready before it is needed.
  static const double _threshold = 400;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (!canLoadMore || notification.metrics.axis != Axis.vertical) {
          return false;
        }
        final double remaining =
            notification.metrics.maxScrollExtent - notification.metrics.pixels;
        if (remaining <= _threshold) {
          onLoadMore();
        }
        // Never swallow the notification: the refresh indicator and the
        // scrollbar need it too.
        return false;
      },
      child: child,
    );
  }
}

/// The row at the end of a paginated list: a spinner while the next page
/// loads, and nothing once the list is complete.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({super.key, required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            context.l10n.loadingMore,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.navy500),
          ),
        ],
      ),
    );
  }
}
