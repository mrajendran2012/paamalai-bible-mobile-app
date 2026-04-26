import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../reader/reader_providers.dart';

/// About + attributions. Required to satisfy CC-BY-SA 4.0 attribution for the
/// bundled Tamil Bible (`tam2017`); also credits the WEB English source.
///
/// See specs/0001-bible-reader/spec.md §Risks #2.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const _ccBySaUrl = 'https://creativecommons.org/licenses/by-sa/4.0/';
  static const _webSourceUrl = 'https://ebible.org/web/';
  static const _tamSourceUrl = 'https://ebible.org/tam2017/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(readerPrefsProvider.select((p) => p.language));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/reader'),
        ),
        title: Text(lang.t('About', 'பற்றி')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Paamalai',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            lang.t(
              'A Bible reader for English and Tamil.',
              'ஆங்கிலம் மற்றும் தமிழ் வேதாகம வாசிப்பு பயன்பாடு.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            label: lang.t('Bible translations', 'வேதாகம மொழிபெயர்ப்புகள்'),
          ),
          _AttributionCard(
            title: 'World English Bible (WEB)',
            licenseLine: lang.t(
              'Public domain.',
              'பொது களம் (Public Domain).',
            ),
            sourceUrl: _webSourceUrl,
            licenseUrl: null,
          ),
          const SizedBox(height: 12),
          _AttributionCard(
            title: 'Tamil Indian Revised Version (tam2017)',
            licenseLine: lang.t(
              'Licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC-BY-SA 4.0).',
              'Creative Commons Attribution-ShareAlike 4.0 International (CC-BY-SA 4.0) உரிமத்தின் கீழ் வழங்கப்பட்டுள்ளது.',
            ),
            sourceUrl: _tamSourceUrl,
            licenseUrl: _ccBySaUrl,
          ),
          const SizedBox(height: 24),
          Text(
            lang.t(
              'Bible texts are bundled offline. Source archives are downloaded from eBible.org by the importer in tools/build_bible_db.dart.',
              'வேதாகம உரைகள் இணையமின்றி பயன்படுத்தும் வகையில் பயன்பாட்டுடன் இணைக்கப்பட்டுள்ளன. eBible.org-இல் இருந்து tools/build_bible_db.dart மூலம் பதிவிறக்கம் செய்யப்படுகின்றன.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _AttributionCard extends ConsumerWidget {
  const _AttributionCard({
    required this.title,
    required this.licenseLine,
    required this.sourceUrl,
    required this.licenseUrl,
  });

  final String title;
  final String licenseLine;
  final String sourceUrl;
  final String? licenseUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(readerPrefsProvider.select((p) => p.language));
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(licenseLine, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            _CopyableUrl(label: lang.t('Source', 'மூலம்'), url: sourceUrl),
            if (licenseUrl != null) ...[
              const SizedBox(height: 4),
              _CopyableUrl(
                label: lang.t('License', 'உரிமம்'),
                url: licenseUrl!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tappable label-and-URL pair. Tapping copies the URL to the clipboard and
/// shows a snackbar; the URL is also rendered as [SelectableText] so the user
/// can long-press to copy a partial selection. We deliberately don't pull in
/// `url_launcher` for v1 — the attribution requirement is "credit + URL
/// visible," not "tap-to-launch."
class _CopyableUrl extends StatelessWidget {
  const _CopyableUrl({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: url));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copied: $url'), duration: const Duration(seconds: 2)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                text: '$label: ',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: url,
                style: TextStyle(
                  color: scheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
