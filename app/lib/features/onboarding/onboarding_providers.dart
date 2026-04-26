import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/bible/book.dart';
import '../../data/onboarding/onboarding_repository.dart';
import '../reader/reader_providers.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(sharedPreferencesProvider));
});

/// In-progress selections during the onboarding flow. Seeded from the
/// already-loaded [ReaderPrefs] so the language card on step 1 reflects the
/// stored value (English on a fresh install).
class OnboardingDraft {
  const OnboardingDraft({
    required this.language,
    required this.personas,
    required this.interests,
  });

  final Lang language;
  final Set<Persona> personas;
  final Set<String> interests;

  bool get personasValid => personas.isNotEmpty;

  /// FR-ON-03: if the user opted into devotion, they must pick ≥1 interest.
  bool get interestsValid =>
      !personas.contains(Persona.devotion) || interests.isNotEmpty;

  bool get canFinish => personasValid && interestsValid;

  OnboardingDraft copyWith({
    Lang? language,
    Set<Persona>? personas,
    Set<String>? interests,
  }) =>
      OnboardingDraft(
        language: language ?? this.language,
        personas: personas ?? this.personas,
        interests: interests ?? this.interests,
      );
}

class OnboardingDraftNotifier extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() {
    final lang = ref.watch(readerPrefsProvider.select((p) => p.language));
    return OnboardingDraft(
      language: lang,
      personas: const {Persona.yearly, Persona.devotion},
      interests: const {},
    );
  }

  void setLanguage(Lang lang) {
    // Mirror straight to ReaderPrefs so the rest of the app sees it
    // immediately (FR-ON-01).
    ref.read(readerPrefsProvider.notifier).setLanguage(lang);
    state = state.copyWith(language: lang);
  }

  void togglePersona(Persona p) {
    final next = {...state.personas};
    if (next.contains(p)) {
      next.remove(p);
    } else {
      next.add(p);
    }
    var interests = state.interests;
    // If devotion was just turned off, drop any interests so an offline
    // user doesn't carry stale tags.
    if (!next.contains(Persona.devotion) && interests.isNotEmpty) {
      interests = const {};
    }
    state = state.copyWith(personas: next, interests: interests);
  }

  void toggleInterest(String code) {
    final next = {...state.interests};
    if (next.contains(code)) {
      next.remove(code);
    } else {
      next.add(code);
    }
    state = state.copyWith(interests: next);
  }

  /// Routes to the correct home tab after FR-ON-04 finishes.
  String homeRoute() {
    if (state.personas.contains(Persona.yearly)) return '/plan';
    if (state.personas.contains(Persona.devotion)) return '/devotion';
    return '/reader';
  }

  /// Persists the draft and flips the completed flag.
  Future<void> finish() async {
    await ref.read(onboardingRepositoryProvider).finish(
          personas: state.personas,
          interests: state.interests,
        );
  }
}

final onboardingDraftProvider =
    NotifierProvider<OnboardingDraftNotifier, OnboardingDraft>(
  OnboardingDraftNotifier.new,
);
