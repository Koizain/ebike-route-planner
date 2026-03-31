import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_point.dart';
import '../models/battery_config.dart';
import 'routing_service.dart';
import 'location_service.dart';
import 'elevation_service.dart';
import 'storage_service.dart';
import 'poi_service.dart';

class AppState extends ChangeNotifier {
  final RoutingService _routingService = RoutingService();
  final LocationService _locationService = LocationService();
  final ElevationService _elevationService = ElevationService();
  final StorageService storageService = StorageService();
  final PoiService _poiService = PoiService();

  LatLng? currentLocation;
  RoutePoint? startPoint;
  RoutePoint? endPoint;
  RouteResult? currentRoute;
  bool isLoadingRoute = false;
  String? routeError;
  bool showBikeTrails = true;

  // Route type
  RouteType routeType = RouteType.bike;

  // Elevation profile
  ElevationProfile? elevationProfile;
  bool isLoadingElevation = false;

  // POI markers
  List<PoiMarker> poiMarkers = [];
  bool showPois = false;
  Timer? _poiDebounce;

  // Multi-stop waypoints
  List<RoutePoint> waypoints = [];

  // Live tracking
  bool isTracking = false;
  StreamSubscription<LatLng>? _trackingSubscription;
  double trackingDistanceM = 0;
  LatLng? _lastTrackingPoint;
  DateTime? trackingStartTime;
  double currentSpeedKmh = 0;

  // Navigation
  bool isNavigating = false;
  int currentManeuverIndex = 0;

  // Heatmap overlay
  bool showHeatmap = false;

  // Heading-up mode
  bool headingUp = false;
  double userHeading = 0;

  // Saved routes
  List<SavedRoute> savedRoutes = [];

  BatteryConfig batteryConfig = const BatteryConfig(
    capacityWh: 500,
    consumptionWhPerKm: 15,
  );

  // Route difficulty based on elevation gain per km
  String get routeDifficulty {
    if (currentRoute == null) return '';
    final route = currentRoute!;
    if (route.distanceKm <= 0) return 'easy';
    final gainPerKm = route.elevationGainM / route.distanceKm;
    if (gainPerKm < 5) return 'easy';
    if (gainPerKm < 15) return 'moderate';
    if (gainPerKm < 30) return 'challenging';
    return 'hard';
  }

  // Current navigation maneuver
  Maneuver? get currentManeuver {
    if (!isNavigating || currentRoute == null) return null;
    final maneuvers = currentRoute!.maneuvers;
    if (currentManeuverIndex >= maneuvers.length) return null;
    return maneuvers[currentManeuverIndex];
  }

  // Distance to next maneuver in meters
  double get distanceToNextManeuverM {
    if (!isNavigating || currentRoute == null || currentLocation == null) {
      return 0;
    }
    final maneuvers = currentRoute!.maneuvers;
    if (currentManeuverIndex >= maneuvers.length) return 0;
    return _haversineM(
        currentLocation!, maneuvers[currentManeuverIndex].location);
  }

  Future<void> fetchCurrentLocation() async {
    try {
      final loc = await _locationService.getCurrentLocation();
      if (loc != null) {
        currentLocation = loc;
        notifyListeners();
      }
    } catch (_) {
      // Location fetch failed, ignore
    }
  }

  void setStartPoint(LatLng pos) {
    startPoint = RoutePoint(position: pos, label: 'A');
    notifyListeners();
    _maybeCalculateRoute();
  }

  void setEndPoint(LatLng pos) {
    endPoint = RoutePoint(position: pos, label: 'B');
    notifyListeners();
    _maybeCalculateRoute();
  }

  void swapStartEnd() {
    final tmpStart = startPoint;
    final tmpEnd = endPoint;
    startPoint = tmpEnd != null
        ? RoutePoint(position: tmpEnd.position, label: 'A')
        : null;
    endPoint = tmpStart != null
        ? RoutePoint(position: tmpStart.position, label: 'B')
        : null;
    waypoints = waypoints.reversed.toList();
    notifyListeners();
    _maybeCalculateRoute();
  }

  void addWaypoint(LatLng pos) {
    final label = String.fromCharCode(67 + waypoints.length);
    waypoints.add(RoutePoint(position: pos, label: label));
    notifyListeners();
    _maybeCalculateRoute();
  }

  void removeWaypoint(int index) {
    if (index >= 0 && index < waypoints.length) {
      waypoints.removeAt(index);
      _relabelWaypoints();
      notifyListeners();
      _maybeCalculateRoute();
    }
  }

  void updateWaypointPosition(int index, LatLng pos) {
    if (index >= 0 && index < waypoints.length) {
      waypoints[index] =
          RoutePoint(position: pos, label: waypoints[index].label);
      notifyListeners();
      _maybeCalculateRoute();
    }
  }

  void updateStartPosition(LatLng pos) {
    startPoint = RoutePoint(position: pos, label: 'A');
    notifyListeners();
    _maybeCalculateRoute();
  }

  void updateEndPosition(LatLng pos) {
    endPoint = RoutePoint(position: pos, label: 'B');
    notifyListeners();
    _maybeCalculateRoute();
  }

  void _relabelWaypoints() {
    for (int i = 0; i < waypoints.length; i++) {
      final label = String.fromCharCode(67 + i);
      waypoints[i] =
          RoutePoint(position: waypoints[i].position, label: label);
    }
  }

  void clearRoute() {
    startPoint = null;
    endPoint = null;
    currentRoute = null;
    routeError = null;
    elevationProfile = null;
    waypoints.clear();
    stopNavigation();
    notifyListeners();
  }

  void toggleBikeTrails() {
    showBikeTrails = !showBikeTrails;
    notifyListeners();
  }

  void setRouteType(RouteType type) {
    if (routeType == type) return;
    routeType = type;
    notifyListeners();
    _maybeCalculateRoute();
  }

  void togglePois() {
    showPois = !showPois;
    notifyListeners();
  }

  void toggleHeatmap() {
    showHeatmap = !showHeatmap;
    notifyListeners();
  }

  void toggleHeadingUp() {
    headingUp = !headingUp;
    notifyListeners();
  }

  // Navigation
  void startNavigation() {
    if (currentRoute == null || currentRoute!.maneuvers.isEmpty) return;
    isNavigating = true;
    currentManeuverIndex = 0;
    if (!isTracking) {
      _startTracking();
    }
    notifyListeners();
  }

  void stopNavigation() {
    if (!isNavigating) return;
    isNavigating = false;
    currentManeuverIndex = 0;
    notifyListeners();
  }

  void _updateNavigationProgress(LatLng pos) {
    if (!isNavigating || currentRoute == null) return;
    final maneuvers = currentRoute!.maneuvers;
    if (maneuvers.isEmpty || currentManeuverIndex >= maneuvers.length) return;

    final distToNext =
        _haversineM(pos, maneuvers[currentManeuverIndex].location);
    if (distToNext < 30) {
      if (currentManeuverIndex + 1 < maneuvers.length) {
        currentManeuverIndex++;
      } else {
        stopNavigation();
      }
    }
  }

  void _updateHeading(LatLng from, LatLng to) {
    final dLon = _toRad(to.longitude - from.longitude);
    final lat1 = _toRad(from.latitude);
    final lat2 = _toRad(to.latitude);
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    userHeading = (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  void fetchPOIsForBounds(
      double south, double west, double north, double east) {
    if (!showPois) return;
    _poiDebounce?.cancel();
    _poiDebounce = Timer(const Duration(seconds: 1), () async {
      try {
        final pois = await _poiService.fetchBikePOIs(
          south: south,
          west: west,
          north: north,
          east: east,
        );
        poiMarkers = pois;
        notifyListeners();
      } catch (_) {
        // POI fetch is non-critical, silently ignore
      }
    });
  }

  void updateBatteryConfig(BatteryConfig config) {
    batteryConfig = config;
    notifyListeners();
  }

  // Live tracking
  void toggleTracking() {
    if (isTracking) {
      _stopTracking();
    } else {
      _startTracking();
    }
  }

  void _startTracking() {
    isTracking = true;
    trackingDistanceM = 0;
    _lastTrackingPoint = currentLocation;
    trackingStartTime = DateTime.now();
    currentSpeedKmh = 0;

    _trackingSubscription = _locationService.positionStream().listen((pos) {
      currentLocation = pos;
      if (_lastTrackingPoint != null) {
        final dist = _haversineM(_lastTrackingPoint!, pos);
        trackingDistanceM += dist;
        final elapsed = DateTime.now().difference(trackingStartTime!);
        if (elapsed.inSeconds > 0) {
          currentSpeedKmh =
              (trackingDistanceM / 1000) / (elapsed.inSeconds / 3600);
        }
        // Update heading when moved significantly
        if (dist > 5) {
          _updateHeading(_lastTrackingPoint!, pos);
        }
        // Update navigation progress
        _updateNavigationProgress(pos);
      }
      _lastTrackingPoint = pos;
      notifyListeners();
    });
    notifyListeners();
  }

  void _stopTracking() {
    isTracking = false;
    _trackingSubscription?.cancel();
    _trackingSubscription = null;
    if (isNavigating) {
      stopNavigation();
    }
    notifyListeners();
  }

  double _haversineM(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final sinLat = math.sin(dLat / 2);
    final sinLon = math.sin(dLon / 2);
    final h = sinLat * sinLat +
        math.cos(_toRad(a.latitude)) * math.cos(_toRad(b.latitude)) *
            sinLon *
            sinLon;
    return 2 * R * math.asin(math.sqrt(h));
  }

  static double _toRad(double deg) => deg * math.pi / 180;

  // Saved routes
  Future<void> loadSavedRoutes() async {
    savedRoutes = await storageService.loadRoutes();
    notifyListeners();
  }

  Future<void> saveCurrentRoute(String name) async {
    if (currentRoute == null || startPoint == null || endPoint == null) return;
    final saved = SavedRoute(
      name: name,
      savedAt: DateTime.now(),
      start: startPoint!,
      end: endPoint!,
      route: currentRoute!,
    );
    await storageService.saveRoute(saved);
    await loadSavedRoutes();
  }

  Future<void> deleteSavedRoute(int index) async {
    await storageService.deleteRoute(index);
    await loadSavedRoutes();
  }

  void loadRoute(SavedRoute saved) {
    startPoint = saved.start;
    endPoint = saved.end;
    currentRoute = saved.route;
    routeError = null;
    elevationProfile = null;
    waypoints.clear();
    notifyListeners();
  }

  double batteryUsagePercent() {
    if (currentRoute == null) return 0;
    final distKm = currentRoute!.distanceKm;
    final baseEnergy = distKm * batteryConfig.consumptionWhPerKm;
    final elevGain = currentRoute!.elevationGainM;
    final elevMultiplier = 1.0 + (elevGain / 100.0) * 0.2;
    final totalEnergy = baseEnergy * elevMultiplier;
    return ((totalEnergy / batteryConfig.capacityWh) * 100).clamp(0, 999);
  }

  List<LatLng> _allStops() {
    final stops = <LatLng>[];
    if (startPoint != null) stops.add(startPoint!.position);
    for (final wp in waypoints) {
      stops.add(wp.position);
    }
    if (endPoint != null) stops.add(endPoint!.position);
    return stops;
  }

  Future<void> _maybeCalculateRoute() async {
    if (startPoint == null || endPoint == null) return;
    isLoadingRoute = true;
    routeError = null;
    elevationProfile = null;
    notifyListeners();

    try {
      final stops = _allStops();
      final result =
          await _routingService.getMultiStopRoute(stops, routeType: routeType);

      if (result != null) {
        currentRoute = result;
        isLoadingRoute = false;
        notifyListeners();

        // Fire-and-forget: fetch elevation in background
        unawaited(_fetchElevationForRoute(result));
      } else {
        routeError = 'Could not calculate route. Check connection.';
        isLoadingRoute = false;
        notifyListeners();
      }
    } catch (_) {
      routeError = 'Route calculation failed. Try again.';
      isLoadingRoute = false;
      notifyListeners();
    }
  }

  Future<void> _fetchElevationForRoute(RouteResult route) async {
    isLoadingElevation = true;
    notifyListeners();

    try {
      final (gain, loss, profile) =
          await _elevationService.getElevation(route.points);
      // Only update if this route is still the current one
      if (currentRoute == route) {
        currentRoute = route.copyWith(
          elevationGainM: gain,
          elevationLossM: loss,
        );
        elevationProfile = profile;
      }
    } catch (_) {
      // Elevation is non-critical, skip on failure
    } finally {
      isLoadingElevation = false;
      notifyListeners();
    }
  }

  String generateGpx() {
    if (currentRoute == null) return '';
    final points = currentRoute!.points;
    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sb.writeln(
        '<gpx version="1.1" creator="eBike Route Planner" xmlns="http://www.topografix.com/GPX/1/1">');
    sb.writeln('  <trk>');
    sb.writeln(
        '    <name>${currentRoute!.distanceKm.toStringAsFixed(1)}km eBike Route</name>');
    sb.writeln('    <trkseg>');
    for (final p in points) {
      sb.writeln(
          '      <trkpt lat="${p.latitude}" lon="${p.longitude}"></trkpt>');
    }
    sb.writeln('    </trkseg>');
    sb.writeln('  </trk>');
    sb.writeln('</gpx>');
    return sb.toString();
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    _poiDebounce?.cancel();
    super.dispose();
  }
}
