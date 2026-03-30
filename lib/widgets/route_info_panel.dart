import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: kIOSBlue)),
              const SizedBox(width: 12),
              Text('Calculating route...',
                  style: GoogleFonts.inter(color: kIOSSecondaryText)),
            ],
          ));
    }

    if (state.routeError != null) {
      return _card(context,
          child: Row(
            children: [
              const Icon(Icons.error_outline,
                  color: kIOSRed, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(state.routeError!,
                      style: GoogleFonts.inter(color: kIOSRed))),
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
              // Stats row - large numbers iOS style
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat(
                    distKm.toStringAsFixed(1),
                    'km',
                    'Distance',
                  ),
                  Container(
                      width: 0.5, height: 40, color: kIOSSeparator),
                  _stat(
                    durMin.toStringAsFixed(0),
                    'min',
                    'Duration',
                  ),
                  Container(
                      width: 0.5, height: 40, color: kIOSSeparator),
                  _stat(
                    '${batteryPct.toStringAsFixed(0)}%',
                    '',
                    'Battery',
                    color: batteryPct > 80
                        ? kIOSRed
                        : batteryPct > 50
                            ? kIOSOrange
                            : kIOSGreen,
                    icon: Icons.battery_charging_full,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ETA row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kIOSBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: kIOSSecondaryText),
                    const SizedBox(width: 6),
                    Text(
                      'Arrive at ~$etaStr',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kIOSPrimaryText,
                      ),
                    ),
                    if (route.elevationGainM > 0) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.trending_up,
                          size: 14, color: kIOSOrange),
                      const SizedBox(width: 3),
                      Text(
                        '${route.elevationGainM.toStringAsFixed(0)}m',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: kIOSOrange),
                      ),
                    ],
                    if (route.elevationLossM > 0) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.trending_down,
                          size: 14, color: kIOSBlue),
                      const SizedBox(width: 3),
                      Text(
                        '${route.elevationLossM.toStringAsFixed(0)}m',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: kIOSBlue),
                      ),
                    ],
                  ],
                ),
              ),
              // Difficulty badge
              if (state.routeDifficulty.isNotEmpty) ...[
                const SizedBox(height: 8),
                _difficultyBadge(state),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: () => _saveRoute(context, state),
                        icon: const Icon(Icons.bookmark_add, size: 16),
                        label: Text('Save',
                            style: GoogleFonts.inter(fontSize: 13)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: FilledButton.icon(
                        onPressed: onRouteOptionsTap,
                        icon: const Icon(Icons.tune, size: 16),
                        label: Text('Details',
                            style: GoogleFonts.inter(fontSize: 13)),
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
        color: kIOSSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _stat(String value, String unit, String label,
      {Color? color, IconData? icon}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, color: color ?? kIOSBlue, size: 18),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: color ?? kIOSPrimaryText)),
            if (unit.isNotEmpty)
              Text(' $unit',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: kIOSSecondaryText)),
          ],
        ),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: kIOSSecondaryText)),
      ],
    );
  }

  Widget _difficultyBadge(AppState state) {
    final difficulty = state.routeDifficulty;
    Color color;
    String label;
    switch (difficulty) {
      case 'easy':
        color = kIOSGreen;
        label = 'Easy';
      case 'moderate':
        color = kIOSOrange;
        label = 'Moderate';
      case 'challenging':
        color = kIOSOrange;
        label = 'Challenging';
      case 'hard':
        color = kIOSRed;
        label = 'Hard';
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.terrain, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }
}
