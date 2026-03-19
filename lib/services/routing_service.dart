import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_point.dart';

class RoutingService {
  static const String _osrmBase = 'https://router.project-osrm.org/route/v1/bike';

  Future<RouteResult?> getRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      '$_osrmBase/${start.longitude},${start.latitude};'
      '${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;

      final route = (data['routes'] as List).first as Map<String, dynamic>;
      final distanceM = (route['distance'] as num).toDouble();
      final durationS = (route['duration'] as num).toDouble();

      final coordinates = (route['geometry']['coordinates'] as List)
          .cast<List>()
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      return RouteResult(
        points: coordinates,
        distanceKm: distanceM / 1000,
        durationMin: durationS / 60,
      );
    } catch (e) {
      return null;
    }
  }
}
