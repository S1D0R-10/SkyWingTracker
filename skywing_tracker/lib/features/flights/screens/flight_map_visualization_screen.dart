import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/features/flights/models/flight_session.dart';
import 'package:skywing_tracker/features/flights/providers/flight_provider.dart';

class FlightMapVisualizationScreen extends ConsumerWidget {
  final String flightId;
  const FlightMapVisualizationScreen({super.key, required this.flightId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flightAsync = ref.watch(flightByIdProvider(flightId));

    return Scaffold(
      appBar: AppBar(title: const Text('Flight Map')),
      body: flightAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (flight) {
          if (flight == null) {
            return const Center(child: Text('Flight not found'));
          }
          return _MapView(flight: flight);
        },
      ),
    );
  }
}

class _MapView extends StatefulWidget {
  final FlightSession flight;
  const _MapView({required this.flight});

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  double _toRad(double deg) => deg * math.pi / 180;

  double? _calculateDistance() {
    if (widget.flight.loftLatitude == null ||
        widget.flight.loftLongitude == null) {
      return null;
    }
    const r = 6371.0;
    final lat1 = _toRad(widget.flight.releaseLatitude);
    final lat2 = _toRad(widget.flight.loftLatitude!);
    final dLat = _toRad(
      widget.flight.loftLatitude! - widget.flight.releaseLatitude,
    );
    final dLon = _toRad(
      widget.flight.loftLongitude! - widget.flight.releaseLongitude,
    );
    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);
    final a =
        sinDLat * sinDLat + math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon;
    final c = 2 * math.asin(math.sqrt(a));
    return r * c;
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    markers.add(
      Marker(
        markerId: const MarkerId('release'),
        position: LatLng(
          widget.flight.releaseLatitude,
          widget.flight.releaseLongitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Release Point',
          snippet:
              widget.flight.releaseLocationName ??
              '${widget.flight.releaseLatitude.toStringAsFixed(4)}, '
                  '${widget.flight.releaseLongitude.toStringAsFixed(4)}',
        ),
      ),
    );

    if (widget.flight.loftLatitude != null &&
        widget.flight.loftLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('loft'),
          position: LatLng(
            widget.flight.loftLatitude!,
            widget.flight.loftLongitude!,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Loft',
            snippet: 'Home loft location',
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (widget.flight.loftLatitude == null ||
        widget.flight.loftLongitude == null) {
      return {};
    }
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(widget.flight.releaseLatitude, widget.flight.releaseLongitude),
          LatLng(widget.flight.loftLatitude!, widget.flight.loftLongitude!),
        ],
        color: AppColors.accent,
        width: 3,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
  }

  LatLngBounds _buildBounds() {
    final relLat = widget.flight.releaseLatitude;
    final relLon = widget.flight.releaseLongitude;

    if (widget.flight.loftLatitude == null) {
      return LatLngBounds(
        southwest: LatLng(relLat - 0.1, relLon - 0.1),
        northeast: LatLng(relLat + 0.1, relLon + 0.1),
      );
    }

    final loftLat = widget.flight.loftLatitude!;
    final loftLon = widget.flight.loftLongitude!;
    const pad = 0.05;

    return LatLngBounds(
      southwest: LatLng(
        math.min(relLat, loftLat) - pad,
        math.min(relLon, loftLon) - pad,
      ),
      northeast: LatLng(
        math.max(relLat, loftLat) + pad,
        math.max(relLon, loftLon) + pad,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distance = _calculateDistance();

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              widget.flight.releaseLatitude,
              widget.flight.releaseLongitude,
            ),
            zoom: 8,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            Future.delayed(const Duration(milliseconds: 300), () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngBounds(_buildBounds(), 60),
              );
            });
          },
          markers: _buildMarkers(),
          polylines: _buildPolylines(),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          mapType: MapType.normal,
        ),

        // Info overlay
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _LegendItem(
                      color: Colors.red,
                      label: 'Release Point',
                      sublabel: widget.flight.releaseLocationName,
                    ),
                    if (widget.flight.loftLatitude != null)
                      const _LegendItem(
                        color: Colors.blue,
                        label: 'Loft',
                        sublabel: null,
                      ),
                  ],
                ),
              ),
              if (distance != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.straighten,
                        color: AppColors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Distance: ${distance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String? sublabel;

  const _LegendItem({required this.color, required this.label, this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (sublabel != null)
              Text(
                sublabel!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
