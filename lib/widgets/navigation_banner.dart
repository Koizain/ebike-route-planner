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
        gradient: const LinearGradient(
          colors: [kIOSBlue, kIOSGreen],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              blurRadius: 12,
              color: kIOSBlue.withValues(alpha: 0.4),
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _directionIcon(maneuver.direction),
              size: 30,
              color: Colors.white,
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
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (maneuver.streetName.isNotEmpty)
                  Text(
                    maneuver.streetName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    maneuver.instruction,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
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
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
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
