import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/bible/book.dart';
import '../../data/onboarding/onboarding_repository.dart';
import 'onboarding_providers.dart';
import 'steps/interests_step.dart';
import 'steps/language_step.dart';
import 'steps/persona_step.dart';

/// Multi-step onboarding host. Implements FR-ON-01..04. The interests step is
/// shown only when the user has opted into the daily devotion (FR-ON-03).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Widget> _stepsFor({required bool includeInterests}) => [
        const LanguageStep(),
        const PersonaStep(),
        if (includeInterests) const InterestsStep(),
      ];

  bool _canAdvanceFrom(int index, OnboardingDraft draft) {
    switch (index) {
      case 0:
        return true; // language always has a default selected
      case 1:
        return draft.personasValid;
      case 2:
        return draft.canFinish;
    }
    return false;
  }

  Future<void> _onPrimary(List<Widget> steps) async {
    final draft = ref.read(onboardingDraftProvider);
    if (!_canAdvanceFrom(_index, draft)) return;
    if (_index < steps.length - 1) {
      setState(() => _index += 1);
      await _pageController.animateToPage(
        _index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    // Last step → persist and route home.
    final notifier = ref.read(onboardingDraftProvider.notifier);
    await notifier.finish();
    if (!mounted) return;
    context.go(notifier.homeRoute());
  }

  void _onBack() {
    if (_index == 0) return;
    setState(() => _index -= 1);
    _pageController.animateToPage(
      _index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingDraftProvider);
    final includeInterests = draft.personas.contains(Persona.devotion);
    final steps = _stepsFor(includeInterests: includeInterests);

    // If the user toggled devotion off while sitting on the (now removed)
    // interests page, snap back to the previous step.
    if (_index >= steps.length) {
      _index = steps.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_index);
        }
      });
    }

    final isTa = draft.language == Lang.ta;
    final isLast = _index == steps.length - 1;
    final canAdvance = _canAdvanceFrom(_index, draft);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paamalai'),
        leading: _index == 0
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _onBack),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StepIndicator(current: _index, total: steps.length),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: steps,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canAdvance ? () => _onPrimary(steps) : null,
                  child: Text(
                    isLast
                        ? (isTa ? 'முடிந்தது' : 'Done')
                        : (isTa ? 'தொடரவும்' : 'Continue'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= current
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i != total - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}
