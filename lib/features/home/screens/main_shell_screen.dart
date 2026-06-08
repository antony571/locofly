// lib/features/home/screens/main_shell_screen.dart
//
// This is the "shell" — the persistent bottom navigation bar that wraps
// the main app screens (Home, List, Bids, Bookings, Profile).
//
// How ShellRoute works:
//   - The shell (this widget) is ALWAYS visible
//   - `child` changes based on the active route
//   - Tapping a bottom nav item calls context.go() which updates `child`

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';

class MainShellScreen extends StatelessWidget {
  final Widget child; // The currently active inner screen

  const MainShellScreen({super.key, required this.child});

  // ─── Which bottom nav item is currently selected? ─────────────────────────
  // go_router doesn't give us an index, so we derive it from the current path.
  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/flights')) return 1;
    if (location.startsWith('/bids')) return 2;
    if (location.startsWith('/bookings')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // `child` is the active screen — go_router swaps it automatically
      body: child,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex(context),

        // When a tab is tapped, navigate to its root path.
        // go_router handles restoring the tab's scroll position etc.
        onTap: (index) {
          switch (index) {
            case 0: context.go(AppRoutes.home); break;
            case 1: context.go(AppRoutes.flightList); break;
            case 2: context.go(AppRoutes.bids); break;
            case 3: context.go(AppRoutes.bookings); break;
            case 4: context.go(AppRoutes.profile); break;
          }
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_outlined),
            activeIcon: Icon(Icons.list),
            label: 'List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel_outlined),
            activeIcon: Icon(Icons.gavel),
            label: 'Bids',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_num_outlined),
            activeIcon: Icon(Icons.confirmation_num),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}
