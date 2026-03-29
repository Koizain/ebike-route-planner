import 'dart:async';
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

  // Saved routes
  List<SavedRoute> savedRoutes = [];

  BatteryConfig batteryConfig = const BatteryConfig(
    capacityWh: 500,
    consumptionWhPerKm: 15,
  );

  Future<void> fetchCurrentLocation() async {
    final loc = await _locationService.getCurrentLocation();
    if (loc != null) {
      currentLocation = loc;
      notifyListeners();
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
      waypoints[index] = RoutePoint(
          position: pos, label: waypoints[index].label);
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
      waypoints[i] = RoutePoint(
          position: waypoints[i].position, label: label);
    }
  }

  void clearRoute() {
    startPoint = null;
    endPoint = null;
    currentRoute = null;
    routeError = null;
    elevationProfile = null;
    waypoints.clear();
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

  void fetchPOIsForBounds(double south, double west, double north, double east) {
    if (!showPois) return;
    _poiDebounce?.cancel();
    _poiDebounce = Timer(const Duration(seconds: 1), () async {
      final pois = await _poiService.fetchBikePOIs(
        south: south,
        west: west,
        north: north,
        east: east,
      );
      poiMarkers = pois;
      notifyListeners();
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
    notifyListeners();
  }

  double _haversineM(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final sinLat = _sin(dLat / 2);
    final sinLon = _sin(dLon / 2);
    final h = sinLat * sinLat +
        _cos(_toRad(a.latitude)) * _cos(_toRad(b.latitude)) * sinLon * sinLon;
    return 2 * R * _asin(_sqrt(h));
  }

  static double _toRad(double deg) => deg * 3.141592653589793 / 180;
  static double _sin(double x) => _taylorSin(x);
  static double _cos(double x) => _taylorSin(x + 3.141592653589793 / 2);
  static double _asin(double x) =>
      x + (x * x * x) / 6 + 3 * (x * x * x * x * x) / 40;
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double g = x;
    for (int i = 0; i < 20; i++) {
      g = (g + x / g) / 2;
    }
    return g;
  }

  static double _taylorSin(double x) {
    const pi = 3.141592653589793;
    x = x % (2 * pi);
    if (x > pi) x -= 2 * pi;
    if (x < -pi) x += 2 * pi;
    final x2 = x * x;
    return x * (1 - x2 / 6 * (1 - x2 / 20 * (1 - x2 / 42)));
  }

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

    final stops = _allStops();
    final result = await _routingService.getMultiStopRoute(stops,
        routeType: routeType);

    if (result != null) {
      currentRoute = result;
      notifyListeners();

      final (gain, loss, profile) =
          await _elevationService.getElevation(result.points);
      currentRoute = result.copyWith(
        elevationGainM: gain,
        elevationLossM: loss,
      );
      elevationProfile = profile;
    } else {
      routeError = 'Could not calculate route. Check connection.';
    }
    isLoadingRoute = false;
    notifyListeners();
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
