import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/location_service.dart';
import '../models/venue.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The map itself, kept in its own widget so the screen around it does not
/// depend on which map provider is used.
///
/// Tiles come from OpenStreetMap: it needs no API key and no billing
/// account, unlike Google Maps. Swapping provider later means changing
/// this one file.
class VenueMapView extends StatefulWidget {
  const VenueMapView({
    super.key,
    required this.venues,
    required this.selected,
    required this.onSelected,
    this.userPosition,
  });

  final List<Venue> venues;
  final Venue? selected;
  final ValueChanged<Venue> onSelected;

  /// The player's own location, when it was granted.
  final LatLng? userPosition;

  @override
  State<VenueMapView> createState() => _VenueMapViewState();
}

class _VenueMapViewState extends State<VenueMapView> {
  final MapController _controller = MapController();

  @override
  void didUpdateWidget(VenueMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow the selection, so tapping a venue in the list below moves the
    // map to it.
    final Venue? selected = widget.selected;
    if (selected != null &&
        selected.id != oldWidget.selected?.id &&
        selected.hasCoordinates) {
      _controller.move(
        LatLng(selected.latitude!, selected.longitude!),
        _controller.camera.zoom,
      );
    }
  }

  LatLng get _initialCentre {
    final Venue? selected = widget.selected;
    if (selected != null && selected.hasCoordinates) {
      return LatLng(selected.latitude!, selected.longitude!);
    }
    return widget.userPosition ??
        const LatLng(
          LocationService.fallbackLatitude,
          LocationService.fallbackLongitude,
        );
  }

  @override
  Widget build(BuildContext context) {
    final List<Venue> mappable =
        widget.venues.where((Venue v) => v.hasCoordinates).toList();

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: _initialCentre,
        initialZoom: 13,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // OpenStreetMap's tile policy asks for an identifying agent.
          userAgentPackageName: 'app.playvo',
        ),
        if (widget.userPosition != null)
          MarkerLayer(
            markers: <Marker>[
              Marker(
                point: widget.userPosition!,
                width: 22,
                height: 22,
                child: const _UserDot(),
              ),
            ],
          ),
        MarkerLayer(
          markers: mappable
              .map(
                (Venue venue) => Marker(
                  point: LatLng(venue.latitude!, venue.longitude!),
                  width: 150,
                  height: 64,
                  alignment: Alignment.topCenter,
                  child: _VenueMarker(
                    venue: venue,
                    isSelected: venue.id == widget.selected?.id,
                    onTap: () => widget.onSelected(venue),
                  ),
                ),
              )
              .toList(),
        ),
        const _OsmAttribution(),
      ],
    );
  }
}

/// The blue dot showing where the player is.
class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.successAccent,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 3),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.successAccent.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// A venue pin: the ball marker, plus its name when it is the selected one.
class _VenueMarker extends StatelessWidget {
  const _VenueMarker({
    required this.venue,
    required this.isSelected,
    required this.onTap,
  });

  final Venue venue;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected ? AppColors.orange500 : AppColors.navy900;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2),
            ),
            child: const Icon(
              Icons.sports_soccer,
              size: 17,
              color: AppColors.white,
            ),
          ),
          if (isSelected) ...<Widget>[
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.md),
                border: Border.all(color: AppColors.orange500),
              ),
              child: Text(
                venue.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.navy900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// OpenStreetMap's licence requires visible attribution.
class _OsmAttribution extends StatelessWidget {
  const _OsmAttribution();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.all(4),
        child: ColoredBox(
          color: Color(0xCCFFFFFF),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              '© OpenStreetMap',
              style: TextStyle(fontSize: 9, color: AppColors.navy500),
            ),
          ),
        ),
      ),
    );
  }
}
