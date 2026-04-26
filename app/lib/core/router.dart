import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/onboarding/onboarding_repository.dart';
import '../features/about/about_screen.dart';
import '../features/devotion/devotion_screen.dart';
import '../features/onboarding/onboarding_providers.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/plan/catch_up_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/reader/chapter_view.dart';
import '../features/reader/reader_screen.dart';
import '../shared/widgets/home_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final repo = ref.read(onboardingRepositoryProvider);
      final goingTo = state.matchedLocation;
      final completed = repo.isCompleted;

      if (!completed && goingTo != '/onboarding') {
        return '/onboarding';
      }
      if (completed && goingTo == '/onboarding') {
        return _homeRouteFor(repo.personas);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/plan',
            builder: (_, __) => const PlanScreen(),
            routes: [
              GoRoute(
                path: 'catch-up',
                builder: (_, __) => const CatchUpScreen(),
              ),
            ],
          ),
          GoRoute(path: '/devotion', builder: (_, __) => const DevotionScreen()),
          GoRoute(
            path: '/reader',
            builder: (_, __) => const ReaderScreen(),
            routes: [
              GoRoute(
                path: ':bookCode/:chapter',
                builder: (_, state) => ChapterView(
                  bookCode: state.pathParameters['bookCode']!.toUpperCase(),
                  chapter: int.parse(state.pathParameters['chapter']!),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Mirror of [OnboardingDraftNotifier.homeRoute] for the post-completion
/// redirect. Yearly wins, then devotion, then reader as a final fallback.
String _homeRouteFor(Set<Persona> personas) {
  if (personas.contains(Persona.yearly)) return '/plan';
  if (personas.contains(Persona.devotion)) return '/devotion';
  return '/reader';
}
