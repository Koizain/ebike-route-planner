import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/app_state.dart';

class MapControls extends StatelessWidget {
  const MapControls({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _fab(
          context,
          heroTag: 'location',
          icon: Icons.my_location,
          onTap: () => state.fetchCurrentLocation(),
        ),
        const SizedBox(height: 8),
        _fab(
          context,
          heroTag: 'trails',
          icon: Icons.directions_bike,
          active: state.showBikeTrails,
          onTap: () => state.toggleBikeTrails(),
        ),
        const SizedBox(height: 8),
        _fab(
          context,
          heroTag: 'clear',
          icon: Icons.close,
          onTap: () => state.clearRoute(),
        ),
      ],
    );
  }

  Widget _fab(BuildContext context, {
    required String heroTag,
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: active ? kNightAccent : kNightCard,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? kNightAccent : kNightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? kNightAccent.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: active ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(
            icon,
            size: 20,
            color: active ? kNightBg : kNightText,
          ),
        ),
      ),
    );
  }
}
