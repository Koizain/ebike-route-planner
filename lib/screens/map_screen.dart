import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';
import '../services/app_state.dart';
import '../widgets/elevation_chart.dart';
import '../widgets/map_controls.dart';
import '../widgets/route_info_panel.dart';
import '../widgets/search_bar_widget.dart';
import 'favorites_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final _mapController = MapController();
  int _tapState = 0;
  int? _draggingMarkerIndex;
  bool _isDragging = false;

  // Route animation
  late AnimationController _routeAnimController;
  late Animation<double> _routeAnimation;
  List<LatLng>? _lastRoutePoints;

  static const _defaultCenter = LatLng(54.6872, 25.2797);

  @override
  void initState() {
    super.initState();
    _routeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _routeAnimation = CurvedAnimation(
      parent: _routeAnimController,
      curve: Curves.easeOutCubic,
    );
    _routeAnimController.addListener(() {
      if (mounted) setState(() {});
    });

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

  @override
  void dispose() {
    _routeAnimController.dispose();
    super.dispose();
  }

  void _checkRouteAnimation(AppState state) {
    if (state.currentRoute != null &&
        state.currentRoute!.points != _lastRoutePoints) {
      _lastRoutePoints = state.currentRoute!.points;
      _routeAnimController.forward(from: 0);
    } else if (state.currentRoute == null) {
      _lastRoutePoints = null;
    }
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd) {
      _fetchPOIsForCurrentView();
    }
  }

  void _fetchPOIsForCurrentView() {
    final state = context.read<AppState>();
    if (!state.showPois) return;
    final bounds = _mapController.camera.visibleBounds;
    state.fetchPOIsForBounds(
      bounds.south,
      bounds.west,
      bounds.north,
      bounds.east,
    );
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
      builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: const _RouteOptionsSheet(),
      ),
    );
  }

  Widget _buildLabeledMarker(String label, Color color,
      {bool isDragging = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isDragging ? 36 : 28,
          height: isDragging ? 36 : 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white, width: isDragging ? 3 : 2.5),
            boxShadow: [
              BoxShadow(
                blurRadius: isDragging ? 12 : 6,
                color: color.withValues(alpha: 0.6),
              ),
              BoxShadow(
                blurRadius: isDragging ? 8 : 4,
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isDragging ? 16 : 13,
              ),
            ),
          ),
        ),
        CustomPaint(
          size: Size(12, isDragging ? 10 : 7),
          painter: _TrianglePainter(color: color),
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
      width: active ? 56 : 42,
      height: active ? 56 : 42,
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

    _checkRouteAnimation(state);

    final markers = <Marker>[];

    // Current location blue dot
    if (state.currentLocation != null) {
      markers.add(Marker(
        point: state.currentLocation!,
        width: 22,
        height: 22,
        child: Container(
          decoration: BoxDecoration(
            color: kAccentBlue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                color: kAccentBlue.withValues(alpha: 0.5),
              ),
              const BoxShadow(blurRadius: 4, color: Colors.black45),
            ],
          ),
        ),
      ));
    }

    // Start marker
    if (state.startPoint != null) {
      markers.add(_draggableMarker(
        point: state.startPoint!.position,
        label: 'A',
        color: kAccentGreen,
        markerIndex: -1,
      ));
    }

    // Waypoints
    for (int i = 0; i < state.waypoints.length; i++) {
      markers.add(_draggableMarker(
        point: state.waypoints[i].position,
        label: state.waypoints[i].label,
        color: Colors.orangeAccent,
        markerIndex: i,
      ));
    }

    // End marker
    if (state.endPoint != null) {
      markers.add(_draggableMarker(
        point: state.endPoint!.position,
        label: 'B',
        color: kAccentBlue,
        markerIndex: -2,
      ));
    }

    // POI markers
    if (state.showPois) {
      for (final poi in state.poiMarkers) {
        markers.add(Marker(
          point: poi.position,
          width: 16,
          height: 16,
          child: Container(
            decoration: BoxDecoration(
              color: poi.type == 'repair'
                  ? Colors.orangeAccent
                  : kAccentGreen,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ],
            ),
            child: Icon(
              poi.type == 'repair' ? Icons.build : Icons.local_parking,
              size: 9,
              color: Colors.white,
            ),
          ),
        ));
      }
    }

    // Animated route points
    List<LatLng>? animatedRoutePoints;
    if (state.currentRoute != null) {
      final allPoints = state.currentRoute!.points;
      if (_routeAnimController.isAnimating || !_routeAnimController.isCompleted) {
        final count = (_routeAnimation.value * allPoints.length).round();
        animatedRoutePoints = allPoints.sublist(0, count.clamp(2, allPoints.length));
      } else {
        animatedRoutePoints = allPoints;
      }
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
              onMapEvent: _onMapEvent,
              interactionOptions: InteractionOptions(
                flags: _isDragging
                    ? InteractiveFlag.none
                    : InteractiveFlag.all,
              ),
            ),
            children: [
              // Base tile layer - CyclOSM when bike trails on, regular OSM otherwise
              TileLayer(
                urlTemplate: state.showBikeTrails
                    ? 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: state.showBikeTrails
                    ? const ['a', 'b', 'c']
                    : const [],
                userAgentPackageName: 'com.ebikerouteplanner.app',
              ),
              if (state.currentLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: state.currentLocation!,
                      radius: state.batteryConfig.rangeKm * 1000,
                      useRadiusInMeter: true,
                      color: kAccentGreen.withValues(alpha: 0.06),
                      borderColor: kAccentGreen.withValues(alpha: 0.3),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              if (animatedRoutePoints != null &&
                  animatedRoutePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: animatedRoutePoints,
                      gradientColors: const [
                        kAccentGreen,
                        Color(0xFF00C4FF),
                        kAccentBlue,
                      ],
                      strokeWidth: 5,
                      borderColor: kNavyDark.withValues(alpha: 0.5),
                      borderStrokeWidth: 2,
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
              top: MediaQuery.of(context).padding.top + 180,
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
        gradient: LinearGradient(
          colors: [
            kNavyMid.withValues(alpha: 0.95),
            kNavyDark.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withValues(alpha: 0.4),
          ),
        ],
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
                TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5))),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RouteOptionsSheet extends StatelessWidget {
  const _RouteOptionsSheet();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final route = state.currentRoute!;
    final batteryPct = state.batteryUsagePercent();
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: route.durationMin.round()));
    final etaStr =
        '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kNavyMid, kNavyDark],
        ),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: kAccentGreen.withValues(alpha: 0.2)),
          left: BorderSide(color: kAccentGreen.withValues(alpha: 0.1)),
          right: BorderSide(color: kAccentGreen.withValues(alpha: 0.1)),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.route,
                          color: kAccentGreen, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Route Summary',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _summaryRow(Icons.straighten, 'Distance',
                      '${route.distanceKm.toStringAsFixed(1)} km'),
                  _summaryRow(Icons.schedule, 'Duration',
                      '${route.durationMin.toStringAsFixed(0)} min'),
                  _summaryRow(Icons.access_time, 'ETA', '~$etaStr'),
                  _summaryRow(
                    Icons.battery_charging_full,
                    'Battery Usage',
                    '${batteryPct.toStringAsFixed(0)}%',
                    valueColor: batteryPct > 80
                        ? Colors.redAccent
                        : batteryPct > 50
                            ? Colors.orangeAccent
                            : kAccentGreen,
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
                  // Elevation chart
                  if (state.elevationProfile != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: ElevationChart(
                        profile: state.elevationProfile!,
                        trackingProgressKm: state.isTracking
                            ? state.trackingDistanceM / 1000
                            : null,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Action buttons
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
                        _addWaypointMode(context, state);
                      },
                      icon: const Icon(Icons.add_location_alt, size: 18),
                      label: const Text('Add Waypoint'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // GPX Export
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _exportGpx(context, state),
                      icon: const Icon(Icons.file_download, size: 18),
                      label: const Text('Export GPX'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Navigation coming soon!'),
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
      ),
    );
  }

  void _addWaypointMode(BuildContext context, AppState state) {
    final route = state.currentRoute;
    if (route != null && route.points.length > 2) {
      final midIndex = route.points.length ~/ 2;
      state.addWaypoint(route.points[midIndex]);
    }
  }

  void _exportGpx(BuildContext context, AppState state) async {
    final gpx = state.generateGpx();
    if (gpx.isEmpty) return;

    try {
      final bytes = Uint8List.fromList(utf8.encode(gpx));
      final xFile = XFile.fromData(
        bytes,
        name: 'route.gpx',
        mimeType: 'application/gpx+xml',
      );
      await Share.shareXFiles([xFile], text: 'eBike Route (GPX)');
    } catch (_) {
      // Fallback: copy to clipboard
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPX export not supported on this platform')),
        );
      }
    }
  }

  Widget _summaryRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
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
