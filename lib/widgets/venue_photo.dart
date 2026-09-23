import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A venue image with a branded placeholder behind it.
///
/// A path starting with `assets/` is loaded from the bundle, anything else
/// over the network. Either way a missing or slow image falls back to the
/// placeholder, so the card's shape never jumps.
class VenuePhoto extends StatelessWidget {
  const VenuePhoto({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String? url;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final String? photoUrl = url;

    final Widget image;
    if (photoUrl == null || photoUrl.isEmpty) {
      image = const _PhotoPlaceholder();
    } else if (photoUrl.startsWith('assets/')) {
      // A bundled image, used for the mock venues and the promo banner
      // until the API serves real photo URLs.
      image = Image.asset(
        photoUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _PhotoPlaceholder(),
      );
    } else {
      image = Image.network(
        photoUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? progress,
        ) =>
            progress == null ? child : const _PhotoPlaceholder(),
        errorBuilder: (_, __, ___) => const _PhotoPlaceholder(),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: SizedBox(width: width, height: height, child: image),
    );
  }
}

/// The gradient stand-in shown while no photo is available.
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.navy500, AppColors.navy900],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_soccer,
          color: AppColors.navy300,
          size: 28,
        ),
      ),
    );
  }
}
