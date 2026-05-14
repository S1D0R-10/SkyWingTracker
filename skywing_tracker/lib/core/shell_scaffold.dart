import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/pigeons')) return 1;
    if (location.startsWith('/flights')) return 2;
    if (location.startsWith('/analytics')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0; // dashboard
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/dashboard');
            case 1:
              context.go('/pigeons');
            case 2:
              context.go('/flights');
            case 3:
              context.go('/analytics');
            case 4:
              context.go('/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_outlined),
            activeIcon: Icon(Icons.pets),
            label: 'Pigeons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight_outlined),
            activeIcon: Icon(Icons.flight),
            label: 'Flights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
