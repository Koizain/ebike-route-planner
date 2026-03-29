import 'package:latlong2/latlong.dart';

class RoutePoint {
  final LatLng position;
  final String label;

  const RoutePoint({required this.position, required this.label});

  Map<String, dynamic> toJson() => {
        'lat': position.latitude,
        'lng': position.longitude,
        'label': label,
      };

  factory RoutePoint.fromJson(Map<String, dynamic> json) => RoutePoint(
        position: LatLng(
          (json['lat'] as num).toDouble(),
          (json['lng'] as num).toDouble(),
        ),
        label: json['label'] as String,
      );
}

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMin;
  final double elevationGainM;
  final double elevationLossM;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
    this.elevationGainM = 0,
    this.elevationLossM = 0,
  });

  RouteResult copyWith({
    double? elevationGainM,
    double? elevationLossM,
  }) {
    return RouteResult(
      points: points,
      distanceKm: distanceKm,
      durationMin: durationMin,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      elevationLossM: elevationLossM ?? this.elevationLossM,
    );
  }

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => [p.latitude, p.longitude]).toList(),
        'distanceKm': distanceKm,
        'durationMin': durationMin,
        'elevationGainM': elevationGainM,
        'elevationLossM': elevationLossM,
      };

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    final pts = (json['points'] as List)
        .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();
    return RouteResult(
      points: pts,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationMin: (json['durationMin'] as num).toDouble(),
      elevationGainM: (json['elevationGainM'] as num?)?.toDouble() ?? 0,
      elevationLossM: (json['elevationLossM'] as num?)?.toDouble() ?? 0,
    );
  }
}
