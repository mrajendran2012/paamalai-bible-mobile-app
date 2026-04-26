import 'package:flutter_test/flutter_test.dart';
import 'package:paamalai/data/audio/tts_prefs_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TtsPrefsRepository', () {
    late SharedPreferences prefs;
    late TtsPrefsRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = TtsPrefsRepository(prefs);
    });

    test('fresh state returns defaults', () {
      final p = repo.read();
      expect(p.speed, 1.0);
      expect(p.voiceName, isNull);
      expect(p.voiceLocale, isNull);
    });

    test('write + read round-trip preserves voice override', () async {
      await repo.write(
        const TtsPrefs(
          speed: 1.25,
          voiceName: 'en-us-x-tpf-local',
          voiceLocale: 'en-US',
        ),
      );
      final reread = TtsPrefsRepository(prefs).read();
      expect(reread.speed, 1.25);
      expect(reread.voiceName, 'en-us-x-tpf-local');
      expect(reread.voiceLocale, 'en-US');
    });

    test('clearVoice via copyWith removes both name and locale', () async {
      await repo.write(
        const TtsPrefs(
          speed: 1.0,
          voiceName: 'voice-1',
          voiceLocale: 'en-US',
        ),
      );
      final cleared = repo.read().copyWith(clearVoice: true);
      await repo.write(cleared);

      final reread = TtsPrefsRepository(prefs).read();
      expect(reread.voiceName, isNull);
      expect(reread.voiceLocale, isNull);
      expect(reread.speed, 1.0);
    });

    test('copyWith ignores clearVoice when both name and locale are passed',
        () {
      const p = TtsPrefs(
        speed: 1.0,
        voiceName: 'old',
        voiceLocale: 'en-US',
      );
      final next =
          p.copyWith(voiceName: 'new', voiceLocale: 'ta-IN');
      expect(next.voiceName, 'new');
      expect(next.voiceLocale, 'ta-IN');
    });
  });
}
