import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({required this.child, super.key});

  final Widget child;

  static const _tabs = [
    ('/plan', Icons.calendar_today_outlined, 'Plan'),
    ('/devotion', Icons.menu_book_outlined, 'Devotion'),
    ('/reader', Icons.auto_stories_outlined, 'Reader'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _tabs.indexWhere((t) => location.startsWith(t.$1));
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        destinations: [
          for (final t in _tabs)
            NavigationDestination(icon: Icon(t.$2), label: t.$3),
        ],
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
      ),
    );
  }
}
