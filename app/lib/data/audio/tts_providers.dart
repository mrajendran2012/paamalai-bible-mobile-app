import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../bible/book.dart';
import 'tts_controller.dart';
import 'tts_prefs_repository.dart';
import 'tts_voice.dart';

final ttsPrefsRepositoryProvider = Provider<TtsPrefsRepository>((ref) {
  return TtsPrefsRepository(ref.watch(sharedPreferencesProvider));
});

/// One [TtsController] per app session. Disposed when the provider container
/// goes away. Built lazily so the platform plugin isn't initialised on first
/// frame.
final ttsControllerProvider = Provider<TtsController>((ref) {
  final ctrl = TtsController();
  ref.onDispose(ctrl.dispose);
  return ctrl;
});

/// Current playback state (idle / playing / paused), reactive.
final ttsStateProvider = StreamProvider<TtsPlaybackState>((ref) {
  final ctrl = ref.watch(ttsControllerProvider);
  return ctrl.stateStream;
});

/// Available voices for [Lang]. Refreshes when the user switches language.
final voicesForLangProvider =
    FutureProvider.family<List<TtsVoice>, Lang>((ref, lang) async {
  final ctrl = ref.watch(ttsControllerProvider);
  return ctrl.voicesFor(localeFor(lang));
});

/// Persisted TTS prefs as a notifier so the settings sheet can react to
/// updates. Defaults from the repo on first read.
class TtsPrefsNotifier extends Notifier<TtsPrefs> {
  @override
  TtsPrefs build() {
    return ref.watch(ttsPrefsRepositoryProvider).read();
  }

  Future<void> setVoice({required String name, required String locale}) async {
    state = state.copyWith(voiceName: name, voiceLocale: locale);
    await ref.read(ttsPrefsRepositoryProvider).write(state);
  }

  Future<void> clearVoice() async {
    state = state.copyWith(clearVoice: true);
    await ref.read(ttsPrefsRepositoryProvider).write(state);
  }

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    await ref.read(ttsPrefsRepositoryProvider).write(state);
  }
}

final ttsPrefsProvider =
    NotifierProvider<TtsPrefsNotifier, TtsPrefs>(TtsPrefsNotifier.new);
