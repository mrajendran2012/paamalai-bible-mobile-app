import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../features/reader/reader_providers.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({required this.child, super.key});

  final Widget child;

  static const _routes = ['/plan', '/devotion', '/reader'];
  static const _icons = [
    Icons.calendar_today_outlined,
    Icons.menu_book_outlined,
    Icons.auto_stories_outlined,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(readerPrefsProvider.select((p) => p.language));
    final labels = [
      lang.t('Plan', 'திட்டம்'),
      lang.t('Devotion', 'தியானம்'),
      lang.t('Reader', 'வாசிப்பு'),
    ];
    final location = GoRouterState.of(context).uri.toString();
    final index = _routes.indexWhere(location.startsWith);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        destinations: [
          for (var i = 0; i < _routes.length; i++)
            NavigationDestination(icon: Icon(_icons[i]), label: labels[i]),
        ],
        onDestinationSelected: (i) => context.go(_routes[i]),
      ),
    );
  }
}
