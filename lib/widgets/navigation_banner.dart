import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/route_point.dart';
import '../services/app_state.dart';

class NavigationBanner extends StatelessWidget {
  const NavigationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.isNavigating || state.currentRoute == null) {
      return const SizedBox.shrink();
    }

    final maneuver = state.currentManeuver;
    if (maneuver == null) return const SizedBox.shrink();

    final distM = state.distanceToNextManeuverM;
    final distStr = distM < 1000
        ? '${distM.toStringAsFixed(0)}m'
        : '${(distM / 1000).toStringAsFixed(1)}km';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kNightCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kNightAccent, width: 2),
        boxShadow: [
          BoxShadow(
              blurRadius: 16,
              color: kNightAccent.withValues(alpha: 0.2),
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Direction icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: kNightAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kNightAccent.withValues(alpha: 0.3)),
            ),
            child: Icon(
              _directionIcon(maneuver.direction),
              size: 30,
              color: kNightAccent,
            ),
          ),
          const SizedBox(width: 14),
          // Distance and street
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  distStr,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: kNightAccent,
                  ),
                ),
                if (maneuver.streetName.isNotEmpty)
                  Text(
                    maneuver.streetName,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kNightText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    maneuver.instruction,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: kNightTextDim,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Stop navigation button
          IconButton(
            onPressed: () => state.stopNavigation(),
            icon: const Icon(Icons.close, color: kNightText),
            style: IconButton.styleFrom(
              backgroundColor: kNightBorder,
            ),
            tooltip: 'Stop Navigation',
          ),
        ],
      ),
    );
  }

  IconData _directionIcon(ManeuverDirection dir) {
    switch (dir) {
      case ManeuverDirection.left:
        return Icons.turn_left;
      case ManeuverDirection.right:
        return Icons.turn_right;
      case ManeuverDirection.straight:
        return Icons.arrow_upward;
      case ManeuverDirection.roundabout:
        return Icons.roundabout_left;
      case ManeuverDirection.arrive:
        return Icons.flag;
      case ManeuverDirection.depart:
        return Icons.navigation;
      case ManeuverDirection.unknown:
        return Icons.arrow_upward;
    }
  }
}
