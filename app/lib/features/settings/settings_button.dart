import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../reader/reader_providers.dart';

/// Reusable gear icon for the AppBar of every top-level screen. Routes to
/// `/settings`. FR-SE-01.
class SettingsButton extends ConsumerWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(readerPrefsProvider.select((p) => p.language));
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: lang.t('Settings', 'அமைப்புகள்'),
      onPressed: () => context.go('/settings'),
    );
  }
}
