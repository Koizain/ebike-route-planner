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
                      strokeWidth: 2, color: kNightAccent)),
              const SizedBox(width: 12),
              Text('Calculating route...',
                  style: GoogleFonts.spaceGrotesk(color: kNightTextDim)),
            ],
          ));
    }

    if (state.routeError != null) {
      return _card(context,
          child: Row(
            children: [
              const Icon(Icons.error_outline,
                  color: kNightRed, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(state.routeError!,
                      style: GoogleFonts.spaceGrotesk(color: kNightRed))),
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
              // Stats row — HUD style large numbers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat(
                    distKm.toStringAsFixed(1),
                    'km',
                    'Distance',
                    color: kNightAccent,
                  ),
                  Container(
                      width: 1, height: 40, color: kNightBorder),
                  _stat(
                    durMin.toStringAsFixed(0),
                    'min',
                    'Duration',
                    color: kNightCyan,
                  ),
                  Container(
                      width: 1, height: 40, color: kNightBorder),
                  _stat(
                    '${batteryPct.toStringAsFixed(0)}%',
                    '',
                    'Battery',
                    color: batteryPct > 80
                        ? kNightRed
                        : batteryPct > 50
                            ? kNightAmber
                            : kNightAccent,
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
                  color: kNightBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kNightBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: kNightTextDim),
                    const SizedBox(width: 6),
                    Text(
                      'Arrive at ~$etaStr',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kNightText,
                      ),
                    ),
                    if (route.elevationGainM > 0) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.trending_up,
                          size: 14, color: kNightAmber),
                      const SizedBox(width: 3),
                      Text(
                        '${route.elevationGainM.toStringAsFixed(0)}m',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 12, color: kNightAmber),
                      ),
                    ],
                    if (route.elevationLossM > 0) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.trending_down,
                          size: 14, color: kNightCyan),
                      const SizedBox(width: 3),
                      Text(
                        '${route.elevationLossM.toStringAsFixed(0)}m',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 12, color: kNightCyan),
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
                            style: GoogleFonts.spaceGrotesk(fontSize: 13)),
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
                            style: GoogleFonts.spaceGrotesk(fontSize: 13)),
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
        color: kNightCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kNightBorder),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withValues(alpha: 0.4),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _stat(String value, String unit, String label,
      {Color? color, IconData? icon}) {
    final accentColor = color ?? kNightAccent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, color: accentColor, size: 18),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value,
                style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: accentColor)),
            if (unit.isNotEmpty)
              Text(' $unit',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 13, color: kNightTextDim)),
          ],
        ),
        Text(label,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                color: kNightTextDim,
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _difficultyBadge(AppState state) {
    final difficulty = state.routeDifficulty;
    Color color;
    String label;
    switch (difficulty) {
      case 'easy':
        color = kNightAccent;
        label = 'Easy';
      case 'moderate':
        color = kNightAmber;
        label = 'Moderate';
      case 'challenging':
        color = kNightAmber;
        label = 'Challenging';
      case 'hard':
        color = kNightRed;
        label = 'Hard';
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.terrain, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }
}
