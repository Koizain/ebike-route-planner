import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/map_screen.dart';
import 'screens/range_screen.dart';
import 'screens/saved_routes_screen.dart';
import 'services/app_state.dart';

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
