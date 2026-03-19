import 'package:latlong2/latlong.dart';

class RoutePoint {
  final LatLng position;
  final String label;

  const RoutePoint({required this.position, required this.label});
}

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMin;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
  });
}
