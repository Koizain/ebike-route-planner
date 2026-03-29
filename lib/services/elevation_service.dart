import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_point.dart';

class ElevationService {
  static const String _apiBase =
      'https://api.open-elevation.com/api/v1/lookup';

  Future<(double gain, double loss, ElevationProfile? profile)> getElevation(
      List<LatLng> points) async {
    if (points.length < 2) return (0.0, 0.0, null);

    final sampled = _sampleEvery500m(points);
    if (sampled.length < 2) return (0.0, 0.0, null);

    try {
      final locations = sampled
          .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
          .toList();

      final response = await http
          .post(
            Uri.parse(_apiBase),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'locations': locations}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return (0.0, 0.0, null);

      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List;

      double gain = 0;
      double loss = 0;
      final elevations = <double>[];
      final distances = <double>[];
      double cumDist = 0;

      for (int i = 0; i < results.length; i++) {
        final elev = (results[i]['elevation'] as num).toDouble();
        elevations.add(elev);

        if (i == 0) {
          distances.add(0);
        } else {
          cumDist += _haversineM(sampled[i - 1], sampled[i]) / 1000.0;
          distances.add(cumDist);
          final diff = elev - elevations[i - 1];
          if (diff > 0) {
            gain += diff;
          } else {
            loss += diff.abs();
          }
        }
      }

      final profile = ElevationProfile(
        elevations: elevations,
        distances: distances,
      );
      return (gain, loss, profile);
    } catch (_) {
      return (0.0, 0.0, null);
    }
  }

  List<LatLng> _sampleEvery500m(List<LatLng> points) {
    const sampleDistM = 500.0;
    final sampled = <LatLng>[points.first];
    double accumulated = 0;

    for (int i = 1; i < points.length; i++) {
      accumulated += _haversineM(points[i - 1], points[i]);
      if (accumulated >= sampleDistM) {
        sampled.add(points[i]);
        accumulated = 0;
      }
    }

    if (sampled.last != points.last) {
      sampled.add(points.last);
    }

    if (sampled.length > 100) {
      final step = sampled.length / 100;
      final reduced = <LatLng>[];
      for (double i = 0; i < sampled.length; i += step) {
        reduced.add(sampled[i.floor()]);
      }
      if (reduced.last != sampled.last) {
        reduced.add(sampled.last);
      }
      return reduced;
    }

    return sampled;
  }

  double _haversineM(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final sinLat = sin(dLat / 2);
    final sinLon = sin(dLon / 2);
    final h = sinLat * sinLat +
        cos(_toRad(a.latitude)) * cos(_toRad(b.latitude)) * sinLon * sinLon;
    return 2 * R * asin(sqrt(h));
  }

  double _toRad(double deg) => deg * pi / 180;
}
