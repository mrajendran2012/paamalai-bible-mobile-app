import 'package:flutter_test/flutter_test.dart';
import 'package:paamalai/data/onboarding/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingRepository', () {
    late SharedPreferences prefs;
    late OnboardingRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = OnboardingRepository(prefs);
    });

    test('fresh state: not completed, no personas, no interests', () {
      expect(repo.isCompleted, isFalse);
      expect(repo.personas, isEmpty);
      expect(repo.interests, isEmpty);
    });

    test('finish() persists personas, interests, and completed flag', () async {
      await repo.finish(
        personas: {Persona.yearly, Persona.devotion},
        interests: {'anxiety', 'work'},
      );

      expect(repo.isCompleted, isTrue);
      expect(repo.personas, {Persona.yearly, Persona.devotion});
      expect(repo.interests, {'anxiety', 'work'});
    });

    test('reads back through a fresh repo (round-trip)', () async {
      await repo.finish(
        personas: {Persona.yearly},
        interests: {'hope'},
      );

      final reread = OnboardingRepository(prefs);
      expect(reread.isCompleted, isTrue);
      expect(reread.personas, {Persona.yearly});
      expect(reread.interests, {'hope'});
    });

    test('reset() wipes all keys', () async {
      await repo.finish(
        personas: {Persona.devotion},
        interests: {'anxiety'},
      );
      await repo.reset();

      expect(repo.isCompleted, isFalse);
      expect(repo.personas, isEmpty);
      expect(repo.interests, isEmpty);
    });

    test('unknown persona codes in storage are ignored', () async {
      await prefs.setStringList('onboarding.personas', ['yearly', 'bogus']);
      expect(repo.personas, {Persona.yearly});
    });
  });
}
