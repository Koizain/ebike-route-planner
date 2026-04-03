import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'models/route_point.dart';
import 'screens/map_screen.dart';
import 'screens/range_screen.dart';
import 'screens/saved_routes_screen.dart';
import 'services/app_state.dart';
import 'widgets/live_stats_bar.dart';
import 'widgets/navigation_banner.dart';
import 'widgets/route_info_panel.dart';
import 'widgets/search_bar_widget.dart';

// ── NIGHTRIDE Dark Cockpit Palette ────────────────────────────────────
const kNightBg = Color(0xFF0A0E14);
const kNightSurface = Color(0xFF131820);
const kNightCard = Color(0xFF1A2030);
const kNightAccent = Color(0xFF00FF87); // High-vis electric green
const kNightCyan = Color(0xFF00B4D8); // Route/info cyan
const kNightRed = Color(0xFFFF3366); // Hot coral
const kNightAmber = Color(0xFFFFB800); // Warning amber
const kNightText = Color(0xFFE8ECF1); // Primary text
const kNightTextDim = Color(0xFF6B7280); // Secondary text
const kNightBorder = Color(0xFF252D3A); // Borders/separators

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const EBikeApp(),
    ),
  );
}

class EBikeApp extends StatelessWidget {
  const EBikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData.dark().textTheme,
    );

    return MaterialApp(
      title: 'eBike Route Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: kNightAccent,
          secondary: kNightCyan,
          surface: kNightSurface,
          onPrimary: kNightBg,
          onSecondary: kNightBg,
          onSurface: kNightText,
          error: kNightRed,
        ),
        scaffoldBackgroundColor: kNightBg,
        useMaterial3: true,
        brightness: Brightness.dark,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: kNightSurface,
          foregroundColor: kNightText,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.spaceGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: kNightText,
          ),
        ),
        cardTheme: CardThemeData(
          color: kNightCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: kNightBorder, width: 1),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kNightSurface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: kNightAccent, size: 24);
            }
            return const IconThemeData(color: kNightTextDim, size: 24);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.spaceGrotesk(
                color: kNightAccent,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              );
            }
            return GoogleFonts.spaceGrotesk(
              color: kNightTextDim,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            );
          }),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kNightAccent,
            foregroundColor: kNightBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kNightAccent,
            side: const BorderSide(color: kNightBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kNightCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kNightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kNightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kNightAccent, width: 1.5),
          ),
          labelStyle: GoogleFonts.spaceGrotesk(color: kNightTextDim),
          hintStyle: GoogleFonts.spaceGrotesk(color: kNightTextDim),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: kNightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: kNightBorder),
          ),
          titleTextStyle: GoogleFonts.spaceGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: kNightText,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: kNightCard,
          contentTextStyle: GoogleFonts.spaceGrotesk(color: kNightText),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: kNightBorder),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 768) {
          return const _DesktopLayout();
        }
        return const _MobileLayout();
      },
    );
  }
}

// ── Mobile layout (existing behavior) ──────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            MapScreen(),
            RangeScreen(),
            SavedRoutesScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: kNightBorder,
                width: 1,
              ),
            ),
          ),
          child: const _BottomNav(),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final tabController = DefaultTabController.of(context);
    return ListenableBuilder(
      listenable: tabController,
      builder: (context, _) {
        return NavigationBar(
          selectedIndex: tabController.index,
          onDestinationSelected: (i) => tabController.animateTo(i),
          height: 56,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.battery_charging_full_outlined),
              selectedIcon: Icon(Icons.battery_charging_full),
              label: 'Range',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_outline),
              selectedIcon: Icon(Icons.bookmark),
              label: 'History',
            ),
          ],
        );
      },
    );
  }
}

// ── Desktop layout (sidebar + map) ─────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 380,
            child: Material(
              color: kNightSurface,
              child: _DesktopSidebar(),
            ),
          ),
          Container(width: 1, color: kNightBorder),
          const Expanded(
            child: MapScreen(showOverlays: false),
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      children: [
        // App title
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kNightAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.electric_bike, color: kNightAccent, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'NIGHTRIDE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kNightAccent,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: kNightBorder),
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search bar
                const RouteSearchBar(),
                // Navigation banner
                if (state.isNavigating)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: NavigationBanner(),
                  ),
                // Live stats
                if (state.isTracking) const LiveStatsBar(),
                // Route info panel
                if (state.currentRoute != null ||
                    state.isLoadingRoute ||
                    state.routeError != null)
                  RouteInfoPanel(
                    onRouteOptionsTap: () =>
                        _showRouteDetails(context, state),
                  ),
                // Turn-by-turn maneuver list
                if (state.currentRoute != null &&
                    state.currentRoute!.maneuvers.isNotEmpty)
                  _ManeuversList(
                      maneuvers: state.currentRoute!.maneuvers),
                // Quick actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openSavedRoutes(context),
                          icon:
                              const Icon(Icons.bookmark_outline, size: 18),
                          label: const Text('Saved Routes'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _openRangeSettings(context),
                          icon: const Icon(
                              Icons.battery_charging_full_outlined,
                              size: 18),
                          label: const Text('Battery & Range'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showRouteDetails(BuildContext context, AppState state) {
    if (state.currentRoute == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: const RouteOptionsSheet(),
      ),
    );
  }

  void _openSavedRoutes(BuildContext context) {
    final state = context.read<AppState>();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: kNightBorder),
        ),
        child: SizedBox(
          width: 420,
          height: 520,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ChangeNotifierProvider.value(
              value: state,
              child: const SavedRoutesScreen(),
            ),
          ),
        ),
      ),
    );
  }

  void _openRangeSettings(BuildContext context) {
    final state = context.read<AppState>();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: kNightBorder),
        ),
        child: SizedBox(
          width: 420,
          height: 600,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ChangeNotifierProvider.value(
              value: state,
              child: const RangeScreen(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Turn-by-turn directions list ───────────────────────────────────────

class _ManeuversList extends StatelessWidget {
  final List<Maneuver> maneuvers;
  const _ManeuversList({required this.maneuvers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: kNightBorder),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              const Icon(Icons.directions, size: 18, color: kNightCyan),
              const SizedBox(width: 8),
              Text(
                'DIRECTIONS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kNightCyan,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        ...maneuvers.map((m) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Icon(_directionIcon(m.direction),
                  size: 20, color: kNightAccent),
              title: Text(
                m.instruction,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 13, color: kNightText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: m.streetName.isNotEmpty
                  ? Text(m.streetName,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 12, color: kNightTextDim))
                  : null,
              trailing: Text(
                m.distanceKm < 1
                    ? '${(m.distanceKm * 1000).toStringAsFixed(0)}m'
                    : '${m.distanceKm.toStringAsFixed(1)}km',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: kNightAccent,
                    fontWeight: FontWeight.w600),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  static IconData _directionIcon(ManeuverDirection dir) {
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
