import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class RouteInfoPanel extends StatelessWidget {
  final VoidCallback? onRouteOptionsTap;

  const RouteInfoPanel({super.key, this.onRouteOptionsTap});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final route = state.currentRoute;

    if (state.isLoadingRoute) {
      return _card(context,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Calculating route...'),
            ],
          ));
    }

    if (state.routeError != null) {
      return _card(context,
          child: Row(
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(state.routeError!,
                      style: const TextStyle(color: Colors.red))),
            ],
          ));
    }

    if (route == null) return const SizedBox.shrink();

    final distKm = route.distanceKm;
    final durMin = route.durationMin;
    final batteryPct = state.batteryUsagePercent();

    return GestureDetector(
      onTap: onRouteOptionsTap,
      child: _card(context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat(Icons.straighten,
                      '${distKm.toStringAsFixed(1)} km', 'Distance'),
                  _stat(Icons.schedule,
                      '${durMin.toStringAsFixed(0)} min', 'Duration'),
                  _stat(
                    Icons.battery_charging_full,
                    '${batteryPct.toStringAsFixed(0)}%',
                    'Battery',
                    color: batteryPct > 80
                        ? Colors.red
                        : batteryPct > 50
                            ? Colors.orange
                            : Colors.green,
                  ),
                ],
              ),
              if (route.elevationGainM > 0 ||
                  route.elevationLossM > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.trending_up,
                        size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${route.elevationGainM.toStringAsFixed(0)}m',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.orange),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.trending_down,
                        size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      '${route.elevationLossM.toStringAsFixed(0)}m',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.blue),
                    ),
                    if (state.waypoints.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.pin_drop,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${state.waypoints.length} stops',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.orange),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: OutlinedButton.icon(
                        onPressed: () => _saveRoute(context, state),
                        icon: const Icon(Icons.bookmark_add, size: 16),
                        label: const Text('Save',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: OutlinedButton.icon(
                        onPressed: onRouteOptionsTap,
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text('Details',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )),
    );
  }

  void _saveRoute(BuildContext context, AppState state) {
    final controller = TextEditingController(
      text:
          '${state.currentRoute!.distanceKm.toStringAsFixed(1)}km route',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Route'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Route name',
            hintText: 'e.g. Morning commute',
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
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                state.saveCurrentRoute(name);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Route saved!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHigh
            .withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              blurRadius: 8,
              color: Colors.black.withValues(alpha: 0.3))
        ],
      ),
      child: child,
    );
  }

  Widget _stat(IconData icon, String value, String label,
      {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color ?? Colors.green, size: 20),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color ?? Colors.white)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }
}
