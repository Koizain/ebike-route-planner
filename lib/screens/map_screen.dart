import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/map_controls.dart';
import '../widgets/route_info_panel.dart';
import '../widgets/search_bar_widget.dart';
import 'favorites_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  int _tapState = 0;
  int? _draggingMarkerIndex; // -1=start, -2=end, 0+=waypoint index
  bool _isDragging = false;

  static const _defaultCenter = LatLng(54.6872, 25.2797);

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
    if (_isDragging) return;
    final state = context.read<AppState>();
    if (_tapState == 0 || _tapState == 2) {
      state.clearRoute();
      state.setStartPoint(pos);
      _tapState = 1;
    } else {
      state.setEndPoint(pos);
      _tapState = 2;
    }
  }

  void _showFavorites() {
    final state = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FavoritesPanel(
        onPlaceSelected: (place, asStart) {
          Navigator.pop(context);
          if (asStart) {
            state.setStartPoint(place.position!);
            _tapState = 1;
          } else {
            state.setEndPoint(place.position!);
            _tapState = 2;
          }
        },
      ),
    );
  }

  void _showRouteBottomSheet() {
    final state = context.read<AppState>();
    if (state.currentRoute == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RouteOptionsSheet(state: state),
    );
  }

  Widget _buildLabeledMarker(String label, Color color,
      {bool isDragging = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isDragging ? 32 : 24,
          height: isDragging ? 32 : 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white, width: isDragging ? 3 : 2),
            boxShadow: [
              BoxShadow(
                blurRadius: isDragging ? 8 : 4,
                color: Colors.black45,
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isDragging ? 16 : 12,
              ),
            ),
          ),
        ),
        Icon(
          Icons.arrow_drop_down,
          color: color,
          size: isDragging ? 20 : 14,
        ),
      ],
    );
  }

  Marker _draggableMarker({
    required LatLng point,
    required String label,
    required Color color,
    required int markerIndex,
  }) {
    final active = _draggingMarkerIndex == markerIndex && _isDragging;
    return Marker(
      point: point,
      width: active ? 52 : 38,
      height: active ? 52 : 38,
      child: GestureDetector(
        onLongPress: () {
          setState(() {
            _draggingMarkerIndex = markerIndex;
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          if (_draggingMarkerIndex != markerIndex) return;
          final currentScreenPos =
              _mapController.camera.latLngToScreenOffset(point);
          final newScreenOffset = currentScreenPos + details.delta;
          final newLatLng = _mapController.camera
              .screenOffsetToLatLng(newScreenOffset);
          final state = context.read<AppState>();
          if (markerIndex == -1) {
            state.updateStartPosition(newLatLng);
          } else if (markerIndex == -2) {
            state.updateEndPosition(newLatLng);
          } else {
            state.updateWaypointPosition(markerIndex, newLatLng);
          }
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
            _draggingMarkerIndex = null;
          });
        },
        child: _buildLabeledMarker(label, color, isDragging: active),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    final markers = <Marker>[];

    // Current location blue dot
    if (state.currentLocation != null) {
      markers.add(Marker(
        point: state.currentLocation!,
        width: 20,
        height: 20,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(blurRadius: 4, color: Colors.black45)
            ],
          ),
        ),
      ));
    }

    // Start marker (draggable, labeled A)
    if (state.startPoint != null) {
      markers.add(_draggableMarker(
        point: state.startPoint!.position,
        label: 'A',
        color: Colors.green,
        markerIndex: -1,
      ));
    }

    // Waypoint markers (draggable, labeled C, D, E...)
    for (int i = 0; i < state.waypoints.length; i++) {
      markers.add(_draggableMarker(
        point: state.waypoints[i].position,
        label: state.waypoints[i].label,
        color: Colors.orange,
        markerIndex: i,
      ));
    }

    // End marker (draggable, labeled B)
    if (state.endPoint != null) {
      markers.add(_draggableMarker(
        point: state.endPoint!.position,
        label: 'B',
        color: Colors.red,
        markerIndex: -2,
      ));
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 12,
              onTap: _onTap,
              interactionOptions: InteractionOptions(
                flags: _isDragging
                    ? InteractiveFlag.none
                    : InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
              MarkerLayer(markers: markers),
            ],
          ),
          // Search bar at top
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 0,
            right: 0,
            child: const RouteSearchBar(),
          ),
          // Live tracking overlay
          if (state.isTracking)
            Positioned(
              top: MediaQuery.of(context).padding.top + 130,
              left: 12,
              right: 12,
              child: _trackingBanner(state),
            ),
          // Route info at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: RouteInfoPanel(
              onRouteOptionsTap: _showRouteBottomSheet,
            ),
          ),
          // Map controls
          Positioned(
            right: 12,
            bottom: 90,
            child: MapControls(onFavoritesTap: _showFavorites),
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
          _trackStat(
              'Speed', '${state.currentSpeedKmh.toStringAsFixed(1)} km/h'),
          _trackStat('Distance',
              '${(state.trackingDistanceM / 1000).toStringAsFixed(2)} km'),
          _trackStat('Time', '${minutes}m ${seconds}s'),
        ],
      ),
    );
  }

  Widget _trackStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 14)),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }
}

class _RouteOptionsSheet extends StatelessWidget {
  final AppState state;

  const _RouteOptionsSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    final route = state.currentRoute!;
    final batteryPct = state.batteryUsagePercent();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _summaryRow(Icons.straighten, 'Distance',
                    '${route.distanceKm.toStringAsFixed(1)} km'),
                _summaryRow(Icons.schedule, 'Duration',
                    '${route.durationMin.toStringAsFixed(0)} min'),
                _summaryRow(
                  Icons.battery_charging_full,
                  'Battery Usage',
                  '${batteryPct.toStringAsFixed(0)}%',
                  valueColor: batteryPct > 80
                      ? Colors.red
                      : batteryPct > 50
                          ? Colors.orange
                          : Colors.green,
                ),
                if (route.elevationGainM > 0)
                  _summaryRow(Icons.trending_up, 'Elevation Gain',
                      '${route.elevationGainM.toStringAsFixed(0)} m'),
                if (route.elevationLossM > 0)
                  _summaryRow(Icons.trending_down, 'Elevation Loss',
                      '${route.elevationLossM.toStringAsFixed(0)} m'),
                _summaryRow(Icons.route, 'Route Points',
                    '${route.points.length}'),
                if (state.waypoints.isNotEmpty)
                  _summaryRow(Icons.pin_drop, 'Waypoints',
                      '${state.waypoints.length}'),
                const SizedBox(height: 20),
                // Add waypoint button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Tap on the map to add a waypoint'),
                        ),
                      );
                      // Next tap adds waypoint
                      _addWaypointMode(context, state);
                    },
                    icon: const Icon(Icons.add_location_alt, size: 18),
                    label: const Text('Add Waypoint'),
                  ),
                ),
                const SizedBox(height: 8),
                // Start navigation placeholder
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Navigation coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Start Navigation'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addWaypointMode(BuildContext context, AppState state) {
    // Use the map center as the waypoint position
    final route = state.currentRoute;
    if (route != null && route.points.length > 2) {
      // Add waypoint at the midpoint of the route
      final midIndex = route.points.length ~/ 2;
      state.addWaypoint(route.points[midIndex]);
    }
  }

  Widget _summaryRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
