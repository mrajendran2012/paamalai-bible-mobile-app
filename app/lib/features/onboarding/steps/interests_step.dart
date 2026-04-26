import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/bible/book.dart';
import '../../../data/onboarding/interest_tags.dart';
import '../onboarding_providers.dart';

/// FR-ON-03 — multi-select grid of starter interest tags. The host disables
/// *Done* until [OnboardingDraft.interestsValid] is true.
class InterestsStep extends ConsumerWidget {
  const InterestsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);
    final isTa = draft.language == Lang.ta;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Text(
          isTa ? 'உங்களுக்கு என்ன முக்கியம்?' : "What's on your mind?",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          isTa
              ? 'பொருத்தமான தினசரி தியானத்திற்கு குறைந்தது ஒன்றை தேர்ந்தெடுக்கவும்.'
              : 'Pick at least one. We use these to personalize your daily devotion.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in starterInterestTags)
              FilterChip(
                label: Text(tag.labelFor(draft.language)),
                selected: draft.interests.contains(tag.code),
                onSelected: (_) => notifier.toggleInterest(tag.code),
              ),
          ],
        ),
        if (draft.personas.isNotEmpty &&
            !draft.interestsValid) ...[
          const SizedBox(height: 16),
          Text(
            isTa
                ? 'குறைந்தது ஒன்றை தேர்ந்தெடுக்கவும்.'
                : 'Select at least one tag to finish.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
