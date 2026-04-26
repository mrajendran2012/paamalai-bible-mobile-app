import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/devotion/devotion_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/reader/chapter_view.dart';
import '../features/reader/reader_screen.dart';
import '../shared/widgets/home_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/plan', builder: (_, __) => const PlanScreen()),
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
