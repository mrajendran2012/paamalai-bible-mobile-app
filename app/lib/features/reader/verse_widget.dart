import 'package:flutter/material.dart';

import '../../data/bible/book.dart';
import '../../data/prefs/reader_prefs_repository.dart';

/// Renders a single verse: a small superscript number followed by the text.
/// Font size and Tamil fallback are applied from [ReaderPrefs].
class VerseWidget extends StatelessWidget {
  const VerseWidget({
    required this.verse,
    required this.text,
    required this.fontSize,
    required this.lang,
    super.key,
  });

  final int verse;
  final String text;
  final FontSize fontSize;
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    final scaled = base.copyWith(
      fontSize: (base.fontSize ?? 16) * fontSize.scale,
      height: 1.55,
      fontFamilyFallback: const ['NotoSansTamil'],
    );
    final number = scaled.copyWith(
      fontSize: (scaled.fontSize ?? 16) * 0.7,
      color: theme.colorScheme.primary,
      fontFeatures: const [FontFeature.superscripts()],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$verse  ', style: number),
            TextSpan(text: text, style: scaled),
          ],
        ),
      ),
    );
  }
}
