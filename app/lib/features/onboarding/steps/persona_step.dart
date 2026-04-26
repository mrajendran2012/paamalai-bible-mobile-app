import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/bible/book.dart';
import '../../../data/onboarding/onboarding_repository.dart';
import '../onboarding_providers.dart';

/// FR-ON-02 — persona/intent selection. Both toggles are on by default; the
/// host disables *Continue* while [OnboardingDraft.personasValid] is false.
class PersonaStep extends ConsumerWidget {
  const PersonaStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);
    final isTa = draft.language == Lang.ta;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Text(
          isTa ? 'நீங்கள் என்ன விரும்புகிறீர்கள்?' : 'What would you like to do?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          isTa
              ? 'இரண்டையும் தேர்ந்தெடுக்கலாம். குறைந்தது ஒன்றை வைத்திருக்கவும்.'
              : 'Pick either or both. Keep at least one selected.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        _PersonaTile(
          title: isTa ? 'வருடாந்திர திட்டம்' : 'Yearly plan',
          subtitle: isTa
              ? '365 நாட்களில் முழு வேதாகமத்தை வாசியுங்கள்.'
              : 'Read the whole Bible in 365 days.',
          icon: Icons.calendar_today_outlined,
          value: draft.personas.contains(Persona.yearly),
          onChanged: (_) => notifier.togglePersona(Persona.yearly),
        ),
        const SizedBox(height: 12),
        _PersonaTile(
          title: isTa ? 'தினசரி தியானம்' : 'Daily devotion',
          subtitle: isTa
              ? 'உங்கள் வாழ்க்கைக்கு பொருத்தமான குறுகிய தியானம்.'
              : 'A short reflection tuned to your interests.',
          icon: Icons.menu_book_outlined,
          value: draft.personas.contains(Persona.devotion),
          onChanged: (_) => notifier.togglePersona(Persona.devotion),
        ),
        if (!draft.personasValid) ...[
          const SizedBox(height: 16),
          Text(
            isTa
                ? 'தொடர குறைந்தது ஒன்றை தேர்ந்தெடுக்கவும்.'
                : 'Select at least one to continue.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _PersonaTile extends StatelessWidget {
  const _PersonaTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: value ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    value ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: value
                                ? scheme.onPrimaryContainer
                                : scheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: value
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
