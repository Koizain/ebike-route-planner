import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: kAccentGreen)),
              const SizedBox(width: 12),
              const Text('Calculating route...',
                  style: TextStyle(color: Colors.white70)),
            ],
          ));
    }

    if (state.routeError != null) {
      return _card(context,
          child: Row(
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(state.routeError!,
                      style: const TextStyle(color: Colors.redAccent))),
            ],
          ));
    }

    if (route == null) return const SizedBox.shrink();

    final distKm = route.distanceKm;
    final durMin = route.durationMin;
    final batteryPct = state.batteryUsagePercent();

    // ETA calculation
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: durMin.round()));
    final etaStr =
        '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';

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
                        ? Colors.redAccent
                        : batteryPct > 50
                            ? Colors.orangeAccent
                            : kAccentGreen,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ETA row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kAccentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time,
                        size: 16, color: kAccentGreen),
                    const SizedBox(width: 6),
                    Text(
                      'Arrive at ~$etaStr',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kAccentGreen,
                      ),
                    ),
                    if (route.elevationGainM > 0) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.trending_up,
                          size: 14, color: Colors.orangeAccent),
                      const SizedBox(width: 3),
                      Text(
                        '${route.elevationGainM.toStringAsFixed(0)}m',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.orangeAccent),
                      ),
                    ],
                    if (route.elevationLossM > 0) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.trending_down,
                          size: 14, color: kAccentBlue),
                      const SizedBox(width: 3),
                      Text(
                        '${route.elevationLossM.toStringAsFixed(0)}m',
                        style: TextStyle(
                            fontSize: 12, color: kAccentBlue),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: OutlinedButton.icon(
                        onPressed: () => _saveRoute(context, state),
                        icon: const Icon(Icons.bookmark_add, size: 16),
                        label: const Text('Save',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: FilledButton.icon(
                        onPressed: onRouteOptionsTap,
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text('Details',
                            style: TextStyle(fontSize: 12)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kNavyMid.withValues(alpha: 0.95),
            kNavyDark.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: kAccentGreen.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            color: Colors.black.withValues(alpha: 0.4),
            offset: const Offset(0, 4),
          ),
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
        Icon(icon, color: color ?? kAccentGreen, size: 22),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color ?? Colors.white)),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
      ],
    );
  }
}
