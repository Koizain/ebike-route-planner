import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/map_controls.dart';
import '../widgets/route_info_panel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  int _tapState = 0;

  static const _defaultCenter = LatLng(54.6872, 25.2797); // Vilnius

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      appState.fetchCurrentLocation().then((_) {
        if (!mounted) return;
        final loc = appState.currentLocation;
        if (loc != null) {
          _mapController.move(loc, 13);
        }
      });
    });
  }

  void _onTap(TapPosition _, LatLng pos) {
    final state = context.read<AppState>();
    if (_tapState == 0 || _tapState == 2) {
      state.startPoint = null;
      state.endPoint = null;
      state.currentRoute = null;
      state.setStartPoint(pos);
      _tapState = 1;
    } else {
      state.setEndPoint(pos);
      _tapState = 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('eBike Route Planner'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 12,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ebikerouteplanner.app',
              ),
              if (state.showBikeTrails)
                Opacity(
                  opacity: 0.7,
                  child: TileLayer(
                    urlTemplate:
                        'https://tile.waymarkedtrails.org/cycling/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ebikerouteplanner.app',
                  ),
                ),
              if (state.currentLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: state.currentLocation!,
                      radius: state.batteryConfig.rangeKm * 1000,
                      useRadiusInMeter: true,
                      color: Colors.green.withValues(alpha: 0.08),
                      borderColor: Colors.green.withValues(alpha: 0.4),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              if (state.currentRoute != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: state.currentRoute!.points,
                      color: theme.colorScheme.primary,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (state.currentLocation != null)
                    Marker(
                      point: state.currentLocation!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black45)],
                        ),
                      ),
                    ),
                  if (state.startPoint != null)
                    Marker(
                      point: state.startPoint!.position,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.location_on, color: Colors.green, size: 36),
                    ),
                  if (state.endPoint != null)
                    Marker(
                      point: state.endPoint!.position,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.flag, color: Colors.red, size: 36),
                    ),
                ],
              ),
            ],
          ),
          // Live tracking overlay
          if (state.isTracking)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _trackingBanner(state),
            ),
          // Route info at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: const RouteInfoPanel(),
          ),
          // Map controls
          Positioned(
            right: 12,
            bottom: 90,
            child: const MapControls(),
          ),
          // Tap hint
          if (_tapState == 1 && !state.isTracking)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tap map to set destination',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _trackingBanner(AppState state) {
    final elapsed = state.trackingStartTime != null
        ? DateTime.now().difference(state.trackingStartTime!)
        : Duration.zero;
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _trackStat('Speed', '${state.currentSpeedKmh.toStringAsFixed(1)} km/h'),
          _trackStat('Distance', '${(state.trackingDistanceM / 1000).toStringAsFixed(2)} km'),
          _trackStat('Time', '${minutes}m ${seconds}s'),
        ],
      ),
    );
  }

  Widget _trackStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }
}
