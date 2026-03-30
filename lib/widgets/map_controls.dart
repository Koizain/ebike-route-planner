import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/app_state.dart';

class MapControls extends StatelessWidget {
  final VoidCallback? onFavoritesTap;

  const MapControls({super.key, this.onFavoritesTap});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _controlButton(
          heroTag: 'location',
          onPressed: () => state.fetchCurrentLocation(),
          tooltip: 'My Location',
          icon: Icons.my_location,
          isActive: false,
        ),
        const SizedBox(height: 8),
        _controlButton(
          heroTag: 'trails',
          onPressed: () => state.toggleBikeTrails(),
          tooltip: 'CyclOSM Layer',
          icon: Icons.directions_bike,
          isActive: state.showBikeTrails,
        ),
        const SizedBox(height: 8),
        _controlButton(
          heroTag: 'heatmap',
          onPressed: () => state.toggleHeatmap(),
          tooltip: 'Popular Routes',
          icon: Icons.local_fire_department,
          isActive: state.showHeatmap,
          activeColor: kIOSOrange,
        ),
        const SizedBox(height: 8),
        _controlButton(
          heroTag: 'pois',
          onPressed: () => state.togglePois(),
          tooltip: 'Bike POIs',
          icon: Icons.local_parking,
          isActive: state.showPois,
        ),
        const SizedBox(height: 8),
        _controlButton(
          heroTag: 'favorites',
          onPressed: onFavoritesTap,
          tooltip: 'Favorites',
          icon: Icons.favorite_outline,
          isActive: false,
        ),
        const SizedBox(height: 8),
        _controlButton(
          heroTag: 'tracking',
          onPressed: () => state.toggleTracking(),
          tooltip: state.isTracking ? 'Stop Tracking' : 'Start Tracking',
          icon: state.isTracking ? Icons.stop : Icons.gps_fixed,
          isActive: state.isTracking,
          activeColor: kIOSRed,
        ),
        const SizedBox(height: 8),
        _controlButton(
          heroTag: 'compass',
          onPressed: () => state.toggleHeadingUp(),
          tooltip: state.headingUp ? 'North Up' : 'Heading Up',
          icon: Icons.explore_outlined,
          isActive: state.headingUp,
        ),
        const SizedBox(height: 8),
        _controlButton(
          heroTag: 'clear',
          onPressed: () => state.clearRoute(),
          tooltip: 'Clear Route',
          icon: Icons.clear,
          isActive: false,
        ),
      ],
    );
  }

  Widget _controlButton({
    required String heroTag,
    required VoidCallback? onPressed,
    required String tooltip,
    required IconData icon,
    required bool isActive,
    Color? activeColor,
  }) {
    final color = activeColor ?? kIOSBlue;
    return SizedBox(
      width: 44,
      height: 44,
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        tooltip: tooltip,
        elevation: 2,
        backgroundColor: isActive ? color : kIOSSurface,
        foregroundColor: isActive ? Colors.white : kIOSPrimaryText,
        shape: const CircleBorder(),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
