import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Stub. Real implementation: language picker -> persona -> interests -> anonymous sign-in.
/// See specs/0000-master-v1.md FR-ON-01..04.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Paamalai',
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                const Text('Onboarding goes here (FR-ON-01..04).'),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/plan'),
                  child: const Text('Continue (stub)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
