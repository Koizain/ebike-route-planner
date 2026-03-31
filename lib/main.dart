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

// iOS System Colors
const kIOSBlue = Color(0xFF007AFF);
const kIOSGreen = Color(0xFF34C759);
const kIOSRed = Color(0xFFFF3B30);
const kIOSOrange = Color(0xFFFF9500);
const kIOSBackground = Color(0xFFF2F2F7);
const kIOSSurface = Color(0xFFFFFFFF);
const kIOSPrimaryText = Color(0xFF000000);
const kIOSSecondaryText = Color(0xFF8E8E93);
const kIOSSeparator = Color(0xFFC6C6C8);

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
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    );

    return MaterialApp(
      title: 'eBike Route Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: kIOSBlue,
          secondary: kIOSGreen,
          surface: kIOSSurface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: kIOSPrimaryText,
        ),
        scaffoldBackgroundColor: kIOSBackground,
        useMaterial3: true,
        brightness: Brightness.light,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: kIOSSurface,
          foregroundColor: kIOSPrimaryText,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: kIOSPrimaryText,
          ),
        ),
        cardTheme: CardThemeData(
          color: kIOSSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kIOSSurface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: kIOSBlue, size: 24);
            }
            return const IconThemeData(color: kIOSSecondaryText, size: 24);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.inter(
                color: kIOSBlue,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              );
            }
            return GoogleFonts.inter(
              color: kIOSSecondaryText,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            );
          }),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kIOSBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kIOSBlue,
            side: const BorderSide(color: kIOSSeparator),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kIOSBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kIOSSeparator),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kIOSSeparator),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kIOSBlue),
          ),
          labelStyle: GoogleFonts.inter(color: kIOSSecondaryText),
          hintStyle: GoogleFonts.inter(color: kIOSSecondaryText),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: kIOSSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: kIOSPrimaryText,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1C1C1E),
          contentTextStyle: GoogleFonts.inter(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
                color: kIOSSeparator,
                width: 0.5,
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
              color: kIOSSurface,
              child: _DesktopSidebar(),
            ),
          ),
          Container(width: 1, color: kIOSSeparator),
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
              const Icon(Icons.electric_bike, color: kIOSBlue, size: 28),
              const SizedBox(width: 10),
              Text(
                'eBike Planner',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kIOSPrimaryText,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: kIOSSeparator),
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
          borderRadius: BorderRadius.circular(14),
        ),
        child: SizedBox(
          width: 420,
          height: 520,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
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
          borderRadius: BorderRadius.circular(14),
        ),
        child: SizedBox(
          width: 420,
          height: 600,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
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
        const Divider(height: 1, color: kIOSSeparator),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              const Icon(Icons.directions, size: 18, color: kIOSBlue),
              const SizedBox(width: 8),
              Text(
                'Directions',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kIOSPrimaryText,
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
                  size: 20, color: kIOSBlue),
              title: Text(
                m.instruction,
                style: GoogleFonts.inter(
                    fontSize: 13, color: kIOSPrimaryText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: m.streetName.isNotEmpty
                  ? Text(m.streetName,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: kIOSSecondaryText))
                  : null,
              trailing: Text(
                m.distanceKm < 1
                    ? '${(m.distanceKm * 1000).toStringAsFixed(0)}m'
                    : '${m.distanceKm.toStringAsFixed(1)}km',
                style: GoogleFonts.inter(
                    fontSize: 12, color: kIOSSecondaryText),
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
