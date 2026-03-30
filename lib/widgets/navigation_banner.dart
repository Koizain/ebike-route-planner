import 'package:flutter/material.dart';
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
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kNavyMid.withValues(alpha: 0.95),
            kNavyDark.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAccentGreen.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
              blurRadius: 12,
              color: Colors.black.withValues(alpha: 0.5)),
        ],
      ),
      child: Row(
        children: [
          // Direction icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kAccentGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _directionIcon(maneuver.direction),
              size: 32,
              color: kAccentGreen,
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
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (maneuver.streetName.isNotEmpty)
                  Text(
                    maneuver.streetName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    maneuver.instruction,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
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
            icon: const Icon(Icons.close, color: Colors.redAccent),
            style: IconButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
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
