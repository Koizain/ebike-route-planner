import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PoiMarker {
  final LatLng position;
  final String type;

  const PoiMarker({required this.position, required this.type});
}

class PoiService {
  static const String _overpassUrl =
      'https://overpass-api.de/api/interpreter';

  Future<List<PoiMarker>> fetchBikePOIs({
    required double south,
    required double west,
    required double north,
    required double east,
  }) async {
    final query = '''
[out:json][timeout:10];
(
  node["amenity"="bicycle_parking"]($south,$west,$north,$east);
  node["amenity"="bicycle_repair_station"]($south,$west,$north,$east);
);
out body;
''';

    try {
      final response = await http
          .post(
            Uri.parse(_overpassUrl),
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List? ?? [];

      return elements.map((e) {
        final m = e as Map<String, dynamic>;
        final lat = (m['lat'] as num).toDouble();
        final lon = (m['lon'] as num).toDouble();
        final tags = m['tags'] as Map<String, dynamic>? ?? {};
        final amenity = tags['amenity'] as String? ?? '';
        final type =
            amenity == 'bicycle_repair_station' ? 'repair' : 'parking';
        return PoiMarker(position: LatLng(lat, lon), type: type);
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
