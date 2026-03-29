import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class MapControls extends StatelessWidget {
  const MapControls({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'location',
          onPressed: () => state.fetchCurrentLocation(),
          tooltip: 'My Location',
          child: const Icon(Icons.my_location),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'trails',
          onPressed: () => state.toggleBikeTrails(),
          tooltip: 'Toggle Bike Trails',
          backgroundColor: state.showBikeTrails
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.directions_bike),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'tracking',
          onPressed: () => state.toggleTracking(),
          tooltip: state.isTracking ? 'Stop Tracking' : 'Start Tracking',
          backgroundColor: state.isTracking
              ? Colors.red
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(state.isTracking ? Icons.stop : Icons.gps_fixed),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'clear',
          onPressed: () => state.clearRoute(),
          tooltip: 'Clear Route',
          child: const Icon(Icons.clear),
        ),
      ],
    );
  }
}
