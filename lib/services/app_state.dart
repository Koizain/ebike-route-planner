import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_point.dart';
import '../models/battery_config.dart';
import 'routing_service.dart';
import 'location_service.dart';

class AppState extends ChangeNotifier {
  final RoutingService _routingService = RoutingService();
  final LocationService _locationService = LocationService();

  LatLng? currentLocation;
  RoutePoint? startPoint;
  RoutePoint? endPoint;
  RouteResult? currentRoute;
  bool isLoadingRoute = false;
  String? routeError;
  bool showBikeTrails = true;

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
    startPoint = RoutePoint(position: pos, label: 'Start');
    notifyListeners();
    _maybeCalculateRoute();
  }

  void setEndPoint(LatLng pos) {
    endPoint = RoutePoint(position: pos, label: 'End');
    notifyListeners();
    _maybeCalculateRoute();
  }

  void clearRoute() {
    startPoint = null;
    endPoint = null;
    currentRoute = null;
    routeError = null;
    notifyListeners();
  }

  void toggleBikeTrails() {
    showBikeTrails = !showBikeTrails;
    notifyListeners();
  }

  void updateBatteryConfig(BatteryConfig config) {
    batteryConfig = config;
    notifyListeners();
  }

  Future<void> _maybeCalculateRoute() async {
    if (startPoint == null || endPoint == null) return;
    isLoadingRoute = true;
    routeError = null;
    notifyListeners();

    final result = await _routingService.getRoute(
      startPoint!.position,
      endPoint!.position,
    );

    isLoadingRoute = false;
    if (result != null) {
      currentRoute = result;
    } else {
      routeError = 'Could not calculate route. Check connection.';
    }
    notifyListeners();
  }
}
