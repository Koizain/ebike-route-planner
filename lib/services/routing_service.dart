import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_point.dart';

class RoutingService {
  static const String _valhallaBase =
      'https://valhalla1.openstreetmap.de/route';
  static const String _osrmBase =
      'https://router.project-osrm.org/route/v1/bike';

  Future<RouteResult?> getRoute(LatLng start, LatLng end,
      {RouteType routeType = RouteType.bike}) async {
    return getMultiStopRoute([start, end], routeType: routeType);
  }

  Future<RouteResult?> getMultiStopRoute(List<LatLng> stops,
      {RouteType routeType = RouteType.bike}) async {
    if (stops.length < 2) return null;

    final valhallaResult = await _getValhallaRoute(stops, routeType);
    if (valhallaResult != null) return valhallaResult;

    return _getOsrmRoute(stops);
  }

  Map<String, dynamic> _costingOptions(RouteType type) {
    switch (type) {
      case RouteType.bike:
        return {
          'bicycle': {
            'use_roads': 0.0,
            'use_hills': 0.4,
            'avoid_bad_surfaces': 0.8,
          }
        };
      case RouteType.ebike:
        return {
          'bicycle': {
            'use_roads': 0.2,
            'use_hills': 0.8,
            'avoid_bad_surfaces': 0.6,
          }
        };
      case RouteType.mountain:
        return {
          'bicycle': {
            'use_roads': 0.0,
            'use_hills': 1.0,
            'avoid_bad_surfaces': 0.0,
          }
        };
    }
  }

  static ManeuverDirection _parseDirection(String instruction) {
    final lower = instruction.toLowerCase();
    if (lower.contains('roundabout')) return ManeuverDirection.roundabout;
    if (lower.contains('left')) return ManeuverDirection.left;
    if (lower.contains('right')) return ManeuverDirection.right;
    if (lower.contains('straight') ||
        lower.contains('continue') ||
        lower.contains('head')) {
      return ManeuverDirection.straight;
    }
    if (lower.contains('arrive') || lower.contains('destination')) {
      return ManeuverDirection.arrive;
    }
    if (lower.contains('depart') || lower.contains('start')) {
      return ManeuverDirection.depart;
    }
    return ManeuverDirection.unknown;
  }

  Future<RouteResult?> _getValhallaRoute(
      List<LatLng> stops, RouteType routeType) async {
    final locations = stops
        .map((s) => {'lat': s.latitude, 'lon': s.longitude})
        .toList();

    final body = json.encode({
      'locations': locations,
      'costing': 'bicycle',
      'costing_options': _costingOptions(routeType),
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

      final List<LatLng> allPoints = [];
      final List<String> allInstructions = [];
      final List<Maneuver> allManeuvers = [];

      for (final leg in legs) {
        final shape = leg['shape'] as String;
        final points = _decodePolyline(shape);

        if (allPoints.isNotEmpty && points.isNotEmpty) {
          allPoints.addAll(points.skip(1));
        } else {
          allPoints.addAll(points);
        }

        final maneuvers = leg['maneuvers'] as List? ?? [];
        for (final m in maneuvers) {
          final instruction = m['instruction'] as String? ?? '';
          if (instruction.isEmpty) continue;

          allInstructions.add(instruction);

          final beginIdx = m['begin_shape_index'] as int? ?? 0;
          final length = (m['length'] as num?)?.toDouble() ?? 0;
          final streets =
              (m['street_names'] as List?)?.cast<String>() ?? [];
          final loc =
              beginIdx < points.length ? points[beginIdx] : points.last;

          allManeuvers.add(Maneuver(
            instruction: instruction,
            direction: _parseDirection(instruction),
            distanceKm: length,
            streetName: streets.isNotEmpty ? streets.first : '',
            location: loc,
          ));
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
        maneuvers: allManeuvers,
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

      final List<String> instructions = [];
      final List<Maneuver> routeManeuvers = [];
      final legs = route['legs'] as List? ?? [];
      for (final leg in legs) {
        final steps = leg['steps'] as List? ?? [];
        for (final step in steps) {
          final maneuver = step['maneuver'] as Map<String, dynamic>?;
          final name = step['name'] as String? ?? '';
          final distance = (step['distance'] as num?)?.toDouble() ?? 0;
          if (maneuver != null) {
            final type = maneuver['type'] as String? ?? '';
            final modifier = maneuver['modifier'] as String? ?? '';
            final loc = maneuver['location'] as List?;

            String instruction;
            if (type == 'arrive') {
              instruction = 'Arrive at destination';
            } else if (name.isNotEmpty) {
              instruction =
                  '${_capitalize(type)} ${modifier.isNotEmpty ? "$modifier " : ""}onto $name';
            } else {
              instruction = '${_capitalize(type)} $modifier'.trim();
            }

            if (instruction.isNotEmpty) {
              instructions.add(instruction);

              LatLng maneuverLoc;
              if (loc != null && loc.length >= 2) {
                maneuverLoc = LatLng((loc[1] as num).toDouble(),
                    (loc[0] as num).toDouble());
              } else {
                maneuverLoc = stops.first;
              }

              routeManeuvers.add(Maneuver(
                instruction: instruction,
                direction: _parseDirection(instruction),
                distanceKm: distance / 1000,
                streetName: name,
                location: maneuverLoc,
              ));
            }
          }
        }
      }

      return RouteResult(
        points: coordinates,
        distanceKm: distanceM / 1000,
        durationMin: durationS / 60,
        instructions: instructions,
        maneuvers: routeManeuvers,
        routingEngine: 'osrm',
      );
    } catch (e) {
      return null;
    }
  }

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
