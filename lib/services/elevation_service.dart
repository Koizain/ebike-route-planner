import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ElevationService {
  static const String _apiBase =
      'https://api.open-elevation.com/api/v1/lookup';

  /// Sample route points every ~500m and fetch elevation data.
  /// Returns (gain, loss) in meters.
  Future<(double gain, double loss)> getElevation(List<LatLng> points) async {
    if (points.length < 2) return (0.0, 0.0);

    final sampled = _sampleEvery500m(points);
    if (sampled.length < 2) return (0.0, 0.0);

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

      if (response.statusCode != 200) return (0.0, 0.0);

      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List;

      double gain = 0;
      double loss = 0;
      for (int i = 1; i < results.length; i++) {
        final prev = (results[i - 1]['elevation'] as num).toDouble();
        final curr = (results[i]['elevation'] as num).toDouble();
        final diff = curr - prev;
        if (diff > 0) {
          gain += diff;
        } else {
          loss += diff.abs();
        }
      }
      return (gain, loss);
    } catch (_) {
      return (0.0, 0.0);
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

    // Limit to 100 points to avoid API overload
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
