import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritePlace {
  final String name;
  final LatLng? position;
  final String? address;

  const FavoritePlace({
    required this.name,
    this.position,
    this.address,
  });

  bool get hasPosition => position != null;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (position != null) 'lat': position!.latitude,
        if (position != null) 'lng': position!.longitude,
        if (address != null) 'address': address,
      };

  factory FavoritePlace.fromJson(Map<String, dynamic> json) {
    LatLng? pos;
    if (json.containsKey('lat') && json.containsKey('lng')) {
      pos = LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      );
    }
    return FavoritePlace(
      name: json['name'] as String,
      position: pos,
      address: json['address'] as String?,
    );
  }

  FavoritePlace copyWith({
    String? name,
    LatLng? position,
    String? address,
  }) {
    return FavoritePlace(
      name: name ?? this.name,
      position: position ?? this.position,
      address: address ?? this.address,
    );
  }
}

class FavoritesService {
  static const _key = 'favorite_places';

  Future<List<FavoritePlace>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) {
      // Return defaults on first load
      final defaults = [
        const FavoritePlace(name: 'Home'),
        const FavoritePlace(name: 'Work'),
      ];
      await _saveFavorites(defaults);
      return defaults;
    }
    return raw
        .map((s) =>
            FavoritePlace.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveFavorite(FavoritePlace place) async {
    final favorites = await loadFavorites();
    final idx = favorites.indexWhere((f) => f.name == place.name);
    if (idx >= 0) {
      favorites[idx] = place;
    } else {
      favorites.add(place);
    }
    await _saveFavorites(favorites);
  }

  Future<void> deleteFavorite(String name) async {
    final favorites = await loadFavorites();
    favorites.removeWhere((f) => f.name == name);
    await _saveFavorites(favorites);
  }

  Future<void> _saveFavorites(List<FavoritePlace> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = favorites.map((f) => json.encode(f.toJson())).toList();
    await prefs.setStringList(_key, raw);
  }
}
