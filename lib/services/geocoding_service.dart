import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class SearchResult {
  final String name;
  final double lat;
  final double lng;

  const SearchResult({
    required this.name,
    required this.lat,
    required this.lng,
  });

  LatLng get latLng => LatLng(lat, lng);

  Map<String, dynamic> toJson() => {
        'name': name,
        'lat': lat,
        'lng': lng,
      };

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        name: json['name'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );
}

class GeocodingService {
  static const String _baseUrl =
      'https://nominatim.openstreetmap.org';
  static const Map<String, String> _headers = {
    'User-Agent': 'eBikeRoutePlanner/1.0',
  };

  Future<List<SearchResult>> searchAddress(String query,
      {LatLng? nearLocation}) async {
    if (query.trim().isEmpty) return [];

    var urlStr = '$_baseUrl/search?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=5';
    if (nearLocation != null) {
      final lat = nearLocation.latitude;
      final lng = nearLocation.longitude;
      urlStr +=
          '&viewbox=${lng - 0.05},${lat + 0.05},${lng + 0.05},${lat - 0.05}'
          '&bounded=1';
    } else {
      urlStr += '&countrycodes=lt,lv,ee,pl,de';
    }

    final url = Uri.parse(urlStr);

    try {
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as List;
      return data.map((item) {
        final m = item as Map<String, dynamic>;
        return SearchResult(
          name: m['display_name'] as String,
          lat: double.parse(m['lat'] as String),
          lng: double.parse(m['lon'] as String),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> reverseGeocode(LatLng pos) async {
    final url = Uri.parse(
      '$_baseUrl/reverse?lat=${pos.latitude}&lon=${pos.longitude}'
      '&format=json&zoom=18',
    );

    try {
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
