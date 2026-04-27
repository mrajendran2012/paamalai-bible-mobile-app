import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../data/bible/book.dart';
import '../reader/reader_providers.dart';

/// App-wide settings home (FR-SE-01..03). Sectioned ListView; v0 ships the
/// Language section and a footer entry that routes to /about. Future feature
/// PRs add their own sections here (interests, account, …).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(readerPrefsProvider.select((p) => p.language));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/plan'),
        ),
        title: Text(lang.t('Settings', 'அமைப்புகள்')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SectionHeader(label: lang.t('Language', 'மொழி')),
          const _LanguageCard(),
          const SizedBox(height: 24),
          _SectionHeader(label: lang.t('About', 'பற்றி')),
          _AboutLinkCard(lang: lang),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _LanguageCard extends ConsumerWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(readerPrefsProvider.select((p) => p.language));
    final notifier = ref.read(readerPrefsProvider.notifier);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _LanguageRow(
            title: 'English',
            selected: lang == Lang.en,
            onTap: () => notifier.setLanguage(Lang.en),
          ),
          const Divider(height: 1, indent: 56),
          _LanguageRow(
            title: 'தமிழ்',
            selected: lang == Lang.ta,
            onTap: () => notifier.setLanguage(Lang.ta),
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      onTap: onTap,
    );
  }
}

class _AboutLinkCard extends StatelessWidget {
  const _AboutLinkCard({required this.lang});
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(lang.t('About & attributions', 'பற்றி & ஒப்புதல்')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/about'),
      ),
    );
  }
}
