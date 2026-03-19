import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class RouteInfoPanel extends StatelessWidget {
  const RouteInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final route = state.currentRoute;

    if (state.isLoadingRoute) {
      return _card(context, child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 12),
          Text('Calculating route...'),
        ],
      ));
    }

    if (state.routeError != null) {
      return _card(context, child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(state.routeError!, style: const TextStyle(color: Colors.red))),
        ],
      ));
    }

    if (route == null) {
      return _card(context, child: const Text(
        'Tap map to set start & end points',
        style: TextStyle(color: Colors.white60),
        textAlign: TextAlign.center,
      ));
    }

    final distKm = route.distanceKm;
    final durMin = route.durationMin;
    final batteryWh = state.batteryConfig.capacityWh;
    final consumWh = state.batteryConfig.consumptionWhPerKm;
    final energyNeeded = distKm * consumWh;
    final batteryPct = ((energyNeeded / batteryWh) * 100).clamp(0, 100);

    return _card(context, child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _stat(Icons.straighten, '${distKm.toStringAsFixed(1)} km', 'Distance'),
        _stat(Icons.schedule, '${durMin.toStringAsFixed(0)} min', 'Duration'),
        _stat(
          Icons.battery_charging_full,
          '${batteryPct.toStringAsFixed(0)}%',
          'Battery used',
          color: batteryPct > 80
              ? Colors.red
              : batteryPct > 50
                  ? Colors.orange
                  : Colors.green,
        ),
      ],
    ));
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.3))],
      ),
      child: child,
    );
  }

  Widget _stat(IconData icon, String value, String label, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color ?? Colors.green, size: 20),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.white)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }
}
