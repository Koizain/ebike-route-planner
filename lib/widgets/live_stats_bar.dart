import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        color: kNightCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kNightBorder),
        boxShadow: [
          BoxShadow(
              blurRadius: 12,
              color: kNightAccent.withValues(alpha: 0.08),
              offset: const Offset(0, 2)),
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
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: kNightAccent,
                ),
              ),
              Text('km/h',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 10, color: kNightTextDim)),
            ],
          ),
          _miniStat('Avg', avgSpeed.toStringAsFixed(1), 'km/h'),
          _miniStat('Dist', distKm.toStringAsFixed(2), 'km'),
          _miniStat('Cal', '$calories', 'kcal'),
          // Activity level indicator
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite,
                size: 18,
                color: state.currentSpeedKmh > 10
                    ? kNightRed
                    : kNightTextDim,
              ),
              const SizedBox(height: 2),
              Text(
                activityLevel,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: state.currentSpeedKmh > 10
                      ? kNightRed
                      : kNightTextDim,
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
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: kNightText,
          ),
        ),
        Text(
          '$label ($unit)',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 9, color: kNightTextDim),
        ),
      ],
    );
  }
}
