import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/bible/book.dart';
import '../onboarding_providers.dart';

/// FR-ON-01 — language picker. English is default-highlighted; tapping a card
/// commits the choice through [ReaderPrefsNotifier] so subsequent step screens
/// already render in the chosen language.
class LanguageStep extends ConsumerWidget {
  const LanguageStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(onboardingDraftProvider).language;
    final notifier = ref.read(onboardingDraftProvider.notifier);
    final isTa = lang == Lang.ta;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Text(
          isTa ? 'உங்கள் மொழியை தேர்ந்தெடுங்கள்' : 'Choose your language',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          isTa
              ? 'இதை பின்னர் அமைப்புகளில் மாற்றலாம்.'
              : 'You can change this later in settings.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        _LanguageCard(
          title: 'English',
          subtitle: 'Read in English',
          selected: lang == Lang.en,
          onTap: () => notifier.setLanguage(Lang.en),
        ),
        const SizedBox(height: 12),
        _LanguageCard(
          title: 'தமிழ்',
          subtitle: 'தமிழில் வாசிக்க',
          selected: lang == Lang.ta,
          onTap: () => notifier.setLanguage(Lang.ta),
        ),
      ],
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: selected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: selected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
