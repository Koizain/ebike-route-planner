import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/app_state.dart';

class LiveStatsBar extends StatelessWidget {
  const LiveStatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.isTracking) return const SizedBox.shrink();

    final elapsed = state.trackingStartTime != null
        ? DateTime.now().difference(state.trackingStartTime!)
        : Duration.zero;
    final avgSpeed = elapsed.inSeconds > 0
        ? (state.trackingDistanceM / 1000) / (elapsed.inSeconds / 3600)
        : 0.0;
    final distKm = state.trackingDistanceM / 1000;
    final calories = (distKm * 30).round();
    final activityLevel = state.currentSpeedKmh > 20
        ? 'High'
        : state.currentSpeedKmh > 10
            ? 'Active'
            : state.currentSpeedKmh > 3
                ? 'Light'
                : 'Idle';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kNavyMid.withValues(alpha: 0.95),
            kNavyDark.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: kAccentBlue.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              blurRadius: 10,
              color: Colors.black.withValues(alpha: 0.4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Current speed - large
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.currentSpeedKmh.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text('km/h',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.5))),
            ],
          ),
          _miniStat('Avg', avgSpeed.toStringAsFixed(1), 'km/h'),
          _miniStat('Dist', distKm.toStringAsFixed(2), 'km'),
          _miniStat('Cal', '$calories', 'kcal'),
          // Heart rate zone indicator
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite,
                size: 18,
                color: state.currentSpeedKmh > 10
                    ? Colors.redAccent
                    : Colors.white38,
              ),
              const SizedBox(height: 2),
              Text(
                activityLevel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: state.currentSpeedKmh > 10
                      ? Colors.redAccent
                      : Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, String unit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          '$label ($unit)',
          style: TextStyle(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.4)),
        ),
      ],
    );
  }
}
