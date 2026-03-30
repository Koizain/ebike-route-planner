import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/app_state.dart';
import '../services/storage_service.dart';

class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({super.key});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AppState>().loadSavedRoutes();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final routes = state.savedRoutes;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark, color: kIOSBlue, size: 22),
            const SizedBox(width: 8),
            Text('Saved Routes',
                style: GoogleFonts.inter(
                    fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: routes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border,
                      size: 64, color: kIOSSeparator),
                  const SizedBox(height: 16),
                  Text(
                    'No saved routes yet',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: kIOSSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Calculate a route and tap Save to add it here',
                    style: GoogleFonts.inter(
                        color: kIOSSecondaryText, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                return _routeCard(context, state, route, index);
              },
            ),
    );
  }

  Widget _routeCard(
      BuildContext context, AppState state, SavedRoute route, int index) {
    final r = route.route;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kIOSSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          state.loadRoute(route);
          final nav = DefaultTabController.of(context);
          nav.animateTo(0);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      route.name,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: kIOSPrimaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: kIOSSecondaryText),
                    onPressed: () =>
                        _confirmDelete(context, state, index),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _chip(Icons.straighten,
                      '${r.distanceKm.toStringAsFixed(1)} km'),
                  const SizedBox(width: 8),
                  _chip(Icons.schedule,
                      '${r.durationMin.toStringAsFixed(0)} min'),
                  if (r.elevationGainM > 0) ...[
                    const SizedBox(width: 8),
                    _chip(Icons.trending_up,
                        '${r.elevationGainM.toStringAsFixed(0)}m'),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Saved ${_formatDate(route.savedAt)}',
                style: GoogleFonts.inter(
                    color: kIOSSecondaryText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kIOSBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kIOSBlue),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, color: kIOSPrimaryText)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _confirmDelete(BuildContext context, AppState state, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete route?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              state.deleteSavedRoute(index);
              Navigator.pop(ctx);
            },
            child: const Text('Delete',
                style: TextStyle(color: kIOSRed)),
          ),
        ],
      ),
    );
  }
}
