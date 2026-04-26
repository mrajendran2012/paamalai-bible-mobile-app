import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../reader/reader_providers.dart';

/// Stub. Real implementation: see specs/0003-daily-devotion/.
class DevotionScreen extends ConsumerWidget {
  const DevotionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(readerPrefsProvider.select((p) => p.language));
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('Today’s Devotion', 'இன்றைய தியானம்')),
      ),
      body: const Center(
        child: Text('Daily devotion UI goes here (FR-DD-01..05).'),
      ),
    );
  }
}
