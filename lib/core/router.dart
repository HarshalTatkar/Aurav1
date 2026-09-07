import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/health_screen.dart';
import '../screens/environment_screen.dart';
import '../screens/risk_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/devices_screen.dart';
import '../screens/emergency_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/bluetooth_connect_screen.dart'; // 👈 ADD THIS IMPORT
import 'theme.dart';

// ─── Shell with Bottom Navigation ────────────────────────────────────────────
class _ShellScaffold extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const _ShellScaffold({required this.child, required this.state});

  int _currentIndex(String location) {
    if (location.startsWith('/health')) return 1;
    if (location.startsWith('/environment')) return 2;
    if (location.startsWith('/risk')) return 3;
    if (location.startsWith('/alerts')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(state.uri.path);
    final isWide = MediaQuery.of(context).size.width >= 800;

    final List<NavigationDestination> destinations = const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.favorite_outline_rounded),
        selectedIcon: Icon(Icons.favorite_rounded),
        label: 'Health',
      ),
      NavigationDestination(
        icon: Icon(Icons.eco_outlined),
        selectedIcon: Icon(Icons.eco_rounded),
        label: 'Environ',
      ),
      NavigationDestination(
        icon: Icon(Icons.psychology_outlined),
        selectedIcon: Icon(Icons.psychology_rounded),
        label: 'AI Risk',
      ),
      NavigationDestination(
        icon: Icon(Icons.notifications_outlined),
        selectedIcon: Icon(Icons.notifications_rounded),
        label: 'Alerts',
      ),
    ];

    void onNavigate(int i) {
      switch (i) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/health');
          break;
        case 2:
          context.go('/environment');
          break;
        case 3:
          context.go('/risk');
          break;
        case 4:
          context.go('/alerts');
          break;
      }
    }

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: idx,
              onDestinationSelected: onNavigate,
              labelType: NavigationRailLabelType.all,
              backgroundColor: AuraColors.surface,
              indicatorColor: AuraColors.healthy.withValues(alpha: 0.12),
              indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              selectedIconTheme: const IconThemeData(color: AuraColors.healthy),
              unselectedIconTheme: const IconThemeData(color: AuraColors.textTertiary),
              selectedLabelTextStyle: const TextStyle(color: AuraColors.healthy, fontWeight: FontWeight.w600, fontSize: 11),
              unselectedLabelTextStyle: const TextStyle(color: AuraColors.textTertiary, fontSize: 11),
              destinations: destinations.map((d) => NavigationRailDestination(
                icon: d.icon,
                selectedIcon: d.selectedIcon,
                label: Text(d.label),
              )).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1, color: AuraColors.glassBorder),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AuraColors.glassBorder, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: onNavigate,
          destinations: destinations,
          backgroundColor: AuraColors.surface,
          indicatorColor: AuraColors.healthy.withValues(alpha: 0.12),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─── Router Configuration ────────────────────────────────────────────────────
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Onboarding
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    // Auth
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    // Main shell with bottom navigation
    ShellRoute(
      builder: (context, state, child) =>
          _ShellScaffold(state: state, child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const HomeScreen(),
            transitionsBuilder: (context, animation, _, child) =>
                FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.0, 0.02), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                ),
          ),
        ),
        GoRoute(
          path: '/health',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const HealthScreen(),
            transitionsBuilder: (context, animation, _, child) =>
                FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.0, 0.02), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                ),
          ),
        ),
        GoRoute(
          path: '/environment',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const EnvironmentScreen(),
            transitionsBuilder: (context, animation, _, child) =>
                FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.0, 0.02), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                ),
          ),
        ),
        GoRoute(
          path: '/risk',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const RiskScreen(),
            transitionsBuilder: (context, animation, _, child) =>
                FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.0, 0.02), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                ),
          ),
        ),
        GoRoute(
          path: '/alerts',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const AlertsScreen(),
            transitionsBuilder: (context, animation, _, child) =>
                FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.0, 0.02), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                ),
          ),
        ),
      ],
    ),
    // Secondary screens (no bottom nav)
    GoRoute(
      path: '/devices',
      builder: (context, state) => const DevicesScreen(),
    ),
    GoRoute(
      path: '/emergency',
      builder: (context, state) => const EmergencyScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    // 👇 ADD THIS NEW ROUTE (after settings or before the closing bracket)
    GoRoute(
      path: '/bluetooth',
      builder: (context, state) => const BluetoothConnectScreen(),
    ),
  ],
);