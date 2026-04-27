import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../data/audio/tts_providers.dart';
import '../../data/audio/tts_voice.dart';
import '../../data/bible/book.dart';
import 'reader_providers.dart';

/// Voice picker for FR-AR-06. Shows the device's voices for the active
/// reading language with quality + gender tags. Voices are sorted by
/// quality (premium/enhanced first) so "Auto"-leaning users land on the
/// best available option. Tapping *Auto* clears the override.
///
/// "Install higher-quality voices" link opens the platform's TTS settings
/// (FR-AR-05 territory; reused here so users can fix audio quality
/// without leaving the app).
class VoicePicker extends ConsumerWidget {
  const VoicePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(readerPrefsProvider.select((p) => p.language));
    final asyncVoices = ref.watch(voicesForLangProvider(lang));
    final ttsPrefs = ref.watch(ttsPrefsProvider);
    final notifier = ref.read(ttsPrefsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.t('Voice', 'குரல்'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        asyncVoices.when(
          loading: () => const SizedBox(
            height: 32,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, _) => Text(
            lang.t(
              'Could not list voices.',
              'குரல்களை பட்டியலிட முடியவில்லை.',
            ),
            style: TextStyle(color: scheme.error),
          ),
          data: (voices) {
            if (voices.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    lang.t(
                      'No voices installed for this language. Add one from your device’s text-to-speech settings.',
                      'இந்த மொழிக்கு குரல்கள் நிறுவப்படவில்லை. உங்கள் சாதனத்தின் text-to-speech அமைப்புகளில் சேர்க்கவும்.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  _InstallVoicesButton(lang: lang),
                ],
              );
            }
            return Column(
              children: [
                _VoiceTile(
                  title: lang.t('Auto (system default)', 'தானியங்கி'),
                  subtitle: null,
                  selected: ttsPrefs.voiceName == null,
                  onTap: notifier.clearVoice,
                ),
                for (final v in voices)
                  _VoiceTile(
                    title: v.name,
                    subtitle: _voiceSubtitle(v, lang),
                    selected: ttsPrefs.voiceName == v.name &&
                        ttsPrefs.voiceLocale == v.locale,
                    onTap: () => notifier.setVoice(
                      name: v.name,
                      locale: v.locale,
                    ),
                  ),
                const SizedBox(height: 8),
                _InstallVoicesButton(lang: lang),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Combined gender + quality subtitle. Empty pieces are dropped so a
  /// tile with only one piece doesn't show a stray separator.
  static String? _voiceSubtitle(TtsVoice v, Lang lang) {
    final parts = <String>[
      if (_genderLabel(v.gender, lang) case final g?) g,
      if (_qualityLabel(v.quality, lang) case final q?) q,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String? _genderLabel(TtsGender g, Lang lang) {
    switch (g) {
      case TtsGender.female:
        return lang.t('Female', 'பெண்');
      case TtsGender.male:
        return lang.t('Male', 'ஆண்');
      case TtsGender.other:
        return lang.t('Other', 'மற்றவை');
      case TtsGender.unknown:
        return null;
    }
  }

  static String? _qualityLabel(TtsQuality q, Lang lang) {
    switch (q) {
      case TtsQuality.premium:
        return lang.t('Premium', 'உயர்தரம்');
      case TtsQuality.enhanced:
        return lang.t('Enhanced', 'மேம்பட்ட');
      case TtsQuality.network:
        return lang.t('Network', 'நெட்வொர்க்');
      case TtsQuality.standard:
        return lang.t('Standard', 'நிலையான');
      case TtsQuality.lowLatency:
        return lang.t('Compact', 'சிறிய');
      case TtsQuality.unknown:
        return null;
    }
  }
}

class _VoiceTile extends StatelessWidget {
  const _VoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap,
    );
  }
}

class _InstallVoicesButton extends StatelessWidget {
  const _InstallVoicesButton({required this.lang});
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.open_in_new, size: 18),
      label: Text(
        lang.t(
          'Install higher-quality voices',
          'உயர்தர குரல்களை நிறுவவும்',
        ),
      ),
      onPressed: () => AppSettings.openAppSettings(
        type: AppSettingsType.settings,
      ),
    );
  }
}
