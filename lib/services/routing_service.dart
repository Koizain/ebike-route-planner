import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_point.dart';

class RoutingService {
  static const String _valhallaBase =
      'https://valhalla1.openstreetmap.de/route';
  static const String _osrmBase =
      'https://router.project-osrm.org/route/v1/bike';

  Future<RouteResult?> getRoute(LatLng start, LatLng end) async {
    return getMultiStopRoute([start, end]);
  }

  Future<RouteResult?> getMultiStopRoute(List<LatLng> stops) async {
    if (stops.length < 2) return null;

    // Try Valhalla first (bike-friendly, avoids highways)
    final valhallaResult = await _getValhallaRoute(stops);
    if (valhallaResult != null) return valhallaResult;

    // Fallback to OSRM
    return _getOsrmRoute(stops);
  }

  Future<RouteResult?> _getValhallaRoute(List<LatLng> stops) async {
    final locations = stops
        .map((s) => {'lat': s.latitude, 'lon': s.longitude})
        .toList();

    final body = json.encode({
      'locations': locations,
      'costing': 'bicycle',
      'costing_options': {
        'bicycle': {
          'use_roads': 0.0,
          'use_hills': 0.4,
          'avoid_bad_surfaces': 0.8,
        }
      },
      'directions_options': {
        'units': 'kilometers',
      },
    });

    try {
      final response = await http
          .post(
            Uri.parse(_valhallaBase),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final trip = data['trip'] as Map<String, dynamic>;
      final legs = trip['legs'] as List;

      // Decode all leg shapes and combine
      final List<LatLng> allPoints = [];
      final List<String> allInstructions = [];

      for (final leg in legs) {
        final shape = leg['shape'] as String;
        final points = _decodePolyline(shape);
        if (allPoints.isNotEmpty && points.isNotEmpty) {
          // Skip duplicate junction point
          allPoints.addAll(points.skip(1));
        } else {
          allPoints.addAll(points);
        }

        // Extract turn-by-turn instructions
        final maneuvers = leg['maneuvers'] as List? ?? [];
        for (final m in maneuvers) {
          final instruction = m['instruction'] as String?;
          if (instruction != null && instruction.isNotEmpty) {
            allInstructions.add(instruction);
          }
        }
      }

      final summary = trip['summary'] as Map<String, dynamic>;
      final distanceKm = (summary['length'] as num).toDouble();
      final durationSec = (summary['time'] as num).toDouble();

      return RouteResult(
        points: allPoints,
        distanceKm: distanceKm,
        durationMin: durationSec / 60,
        instructions: allInstructions,
        routingEngine: 'valhalla',
      );
    } catch (e) {
      return null;
    }
  }

  Future<RouteResult?> _getOsrmRoute(List<LatLng> stops) async {
    final coords =
        stops.map((s) => '${s.longitude},${s.latitude}').join(';');
    final url = Uri.parse(
      '$_osrmBase/$coords?overview=full&geometries=geojson&steps=true',
    );

    try {
      final response =
          await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;

      final route =
          (data['routes'] as List).first as Map<String, dynamic>;
      final distanceM = (route['distance'] as num).toDouble();
      final durationS = (route['duration'] as num).toDouble();

      final coordinates = (route['geometry']['coordinates'] as List)
          .cast<List>()
          .map((c) =>
              LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      // Extract instructions from OSRM steps
      final List<String> instructions = [];
      final legs = route['legs'] as List? ?? [];
      for (final leg in legs) {
        final steps = leg['steps'] as List? ?? [];
        for (final step in steps) {
          final maneuver = step['maneuver'] as Map<String, dynamic>?;
          final name = step['name'] as String? ?? '';
          if (maneuver != null) {
            final type = maneuver['type'] as String? ?? '';
            final modifier = maneuver['modifier'] as String? ?? '';
            if (type == 'arrive') {
              instructions.add('Arrive at destination');
            } else if (name.isNotEmpty) {
              instructions.add(
                  '${_capitalize(type)} ${modifier.isNotEmpty ? "$modifier " : ""}onto $name');
            }
          }
        }
      }

      return RouteResult(
        points: coordinates,
        distanceKm: distanceM / 1000,
        durationMin: durationS / 60,
        instructions: instructions,
        routingEngine: 'osrm',
      );
    } catch (e) {
      return null;
    }
  }

  /// Decode Valhalla's encoded polyline (precision 6)
  static List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e6, lng / 1e6));
    }

    return points;
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
