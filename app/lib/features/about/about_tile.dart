import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../reader/reader_providers.dart';

/// Reusable settings-sheet entry that pops the sheet and navigates to
/// `/about`. Used from both the Reader and the Chapter view settings sheets.
class AboutTile extends ConsumerWidget {
  const AboutTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(readerPrefsProvider.select((p) => p.language));
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.info_outline),
      title: Text(lang.t('About & attributions', 'பற்றி & ஒப்புதல்')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).maybePop();
        GoRouter.of(context).go('/about');
      },
    );
  }
}
