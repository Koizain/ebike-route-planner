import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/route_point.dart';

class SavedRoute {
  final String name;
  final DateTime savedAt;
  final RoutePoint start;
  final RoutePoint end;
  final RouteResult route;

  const SavedRoute({
    required this.name,
    required this.savedAt,
    required this.start,
    required this.end,
    required this.route,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'savedAt': savedAt.toIso8601String(),
        'start': start.toJson(),
        'end': end.toJson(),
        'route': route.toJson(),
      };

  factory SavedRoute.fromJson(Map<String, dynamic> json) => SavedRoute(
        name: json['name'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
        start: RoutePoint.fromJson(json['start'] as Map<String, dynamic>),
        end: RoutePoint.fromJson(json['end'] as Map<String, dynamic>),
        route: RouteResult.fromJson(json['route'] as Map<String, dynamic>),
      );
}

class StorageService {
  static const _key = 'saved_routes';

  Future<List<SavedRoute>> loadRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => SavedRoute.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRoute(SavedRoute route) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(json.encode(route.toJson()));
    await prefs.setStringList(_key, raw);
  }

  Future<void> deleteRoute(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    if (index >= 0 && index < raw.length) {
      raw.removeAt(index);
      await prefs.setStringList(_key, raw);
    }
  }
}
