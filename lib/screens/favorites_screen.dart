import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../main.dart';
import '../services/favorites_service.dart';

class FavoritesPanel extends StatefulWidget {
  final void Function(FavoritePlace place, bool asStart) onPlaceSelected;

  const FavoritesPanel({super.key, required this.onPlaceSelected});

  @override
  State<FavoritesPanel> createState() => _FavoritesPanelState();
}

class _FavoritesPanelState extends State<FavoritesPanel> {
  final _favoritesService = FavoritesService();
  List<FavoritePlace> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favs = await _favoritesService.loadFavorites();
    if (mounted) setState(() => _favorites = favs);
  }

  Future<void> _editFavorite(FavoritePlace place) async {
    final nameCtrl = TextEditingController(text: place.name);
    final latCtrl = TextEditingController(
        text: place.position?.latitude.toStringAsFixed(6) ?? '');
    final lngCtrl = TextEditingController(
        text: place.position?.longitude.toStringAsFixed(6) ?? '');

    final result = await showDialog<FavoritePlace>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${place.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: latCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Latitude'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: lngCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Longitude'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final lat = double.tryParse(latCtrl.text);
              final lng = double.tryParse(lngCtrl.text);
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              LatLng? pos;
              if (lat != null && lng != null) {
                pos = LatLng(lat, lng);
              }
              Navigator.pop(
                ctx,
                FavoritePlace(
                  name: name,
                  position: pos,
                  address: place.address,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (result.name != place.name) {
        await _favoritesService.deleteFavorite(place.name);
      }
      await _favoritesService.saveFavorite(result);
      await _loadFavorites();
    }
  }

  Future<void> _addNewFavorite() async {
    final nameCtrl = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Favorite'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. Gym, Coffee Shop',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final n = nameCtrl.text.trim();
              if (n.isNotEmpty) Navigator.pop(ctx, n);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name != null) {
      await _favoritesService.saveFavorite(FavoritePlace(name: name));
      await _loadFavorites();
    }
  }

  void _onFavoriteTap(FavoritePlace place) {
    if (!place.hasPosition) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${place.name} has no location set. Edit it first.'),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Use "${place.name}" as...'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onPlaceSelected(place, true);
            },
            child: const Text('Start'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onPlaceSelected(place, false);
            },
            child: const Text('Destination'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFavorite(FavoritePlace place) async {
    await _favoritesService.deleteFavorite(place.name);
    await _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: kNightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: const Border(
          top: BorderSide(color: kNightAccent, width: 2),
          left: BorderSide(color: kNightBorder, width: 1),
          right: BorderSide(color: kNightBorder, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: kNightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.favorite,
                    color: kNightRed, size: 20),
                const SizedBox(width: 8),
                Text(
                  'FAVORITES',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kNightText,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add,
                      size: 20, color: kNightAccent),
                  onPressed: _addNewFavorite,
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final fav = _favorites[index];
                final icon = fav.name == 'Home'
                    ? Icons.home
                    : fav.name == 'Work'
                        ? Icons.work
                        : Icons.place;
                return ListTile(
                  leading: Icon(icon,
                      color: fav.hasPosition
                          ? kNightCyan
                          : kNightTextDim),
                  title: Text(fav.name,
                      style: GoogleFonts.spaceGrotesk(
                          color: kNightText,
                          fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    fav.hasPosition
                        ? (fav.address ??
                            '${fav.position!.latitude.toStringAsFixed(4)}, '
                                '${fav.position!.longitude.toStringAsFixed(4)}')
                        : 'Not set',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 12, color: kNightTextDim),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            size: 18, color: kNightTextDim),
                        onPressed: () => _editFavorite(fav),
                      ),
                      if (fav.name != 'Home' && fav.name != 'Work')
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: kNightTextDim),
                          onPressed: () => _deleteFavorite(fav),
                        ),
                    ],
                  ),
                  onTap: () => _onFavoriteTap(fav),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
