// Smoke test: the app builds, the router lands on onboarding, and the
// title renders. Does not exercise Supabase (Env.isConfigured guards that).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paamalai/app.dart';

void main() {
  testWidgets('app boots and shows onboarding title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PaamalaiApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Paamalai'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
