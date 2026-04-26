import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../data/bible/book.dart';
import '../../data/prefs/reader_prefs_repository.dart';
import 'reader_providers.dart';

/// Browse books grouped OT / NT in the current reading language.
/// Tap a book → modal sheet with chapter numbers → navigate to chapter view.
///
/// Implements FR-BR-01.
class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(readerPrefsProvider).language;
    final asyncBooks = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('Reader', 'வாசிப்பு')),
        actions: [
          _LanguageToggle(current: lang),
          IconButton(
            tooltip: lang.t('Display settings', 'காட்சி அமைப்புகள்'),
            icon: const Icon(Icons.tune),
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
      ),
      body: asyncBooks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(message: '$e'),
        data: (books) => _BookList(books: books, lang: lang),
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  const _BookList({required this.books, required this.lang});
  final List<Book> books;
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    final ot = books.where((b) => b.testament == 'OT').toList();
    final nt = books.where((b) => b.testament == 'NT').toList();
    return ListView(
      children: [
        _SectionHeader(label: lang.t('Old Testament', 'பழைய ஏற்பாடு')),
        for (final b in ot) _BookTile(book: b, lang: lang),
        _SectionHeader(label: lang.t('New Testament', 'புதிய ஏற்பாடு')),
        for (final b in nt) _BookTile(book: b, lang: lang),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

class _BookTile extends ConsumerWidget {
  const _BookTile({required this.book, required this.lang});
  final Book book;
  final Lang lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCount = ref.watch(
      chapterCountProvider(
        ChapterCountRequest(bookId: book.id, lang: lang),
      ),
    );
    return ListTile(
      title: Text(book.displayName(lang)),
      trailing: asyncCount.when(
        loading: () => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, __) => const Icon(Icons.error_outline, size: 18),
        data: (count) =>
            Text('$count', style: Theme.of(context).textTheme.bodySmall),
      ),
      onTap: () => _showChaptersSheet(context, book, lang),
    );
  }
}

void _showChaptersSheet(BuildContext context, Book book, Lang lang) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetCtx) => Consumer(
      builder: (ctx, ref, _) {
        final asyncCount = ref.watch(
          chapterCountProvider(
            ChapterCountRequest(bookId: book.id, lang: lang),
          ),
        );
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      book.displayName(lang),
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: asyncCount.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (count) => GridView.count(
                    controller: scrollController,
                    crossAxisCount: 5,
                    padding: const EdgeInsets.all(12),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      for (var c = 1; c <= count; c++)
                        _ChapterChip(
                          number: c,
                          onTap: () {
                            Navigator.of(sheetCtx).pop();
                            ctx.go('/reader/${book.code}/$c');
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _ChapterChip extends StatelessWidget {
  const _ChapterChip({required this.number, required this.onTap});
  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Text(
            '$number',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        ),
      ),
    );
  }
}

class _LanguageToggle extends ConsumerWidget {
  const _LanguageToggle({required this.current});
  final Lang current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(bibleRepositoryProvider).maybeWhen(
          data: (r) => r,
          orElse: () => null,
        );
    final canSwitchToTamil = repo?.hasTamil ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: SegmentedButton<Lang>(
          segments: [
            const ButtonSegment(value: Lang.en, label: Text('EN')),
            ButtonSegment(
              value: Lang.ta,
              label: const Text('TA'),
              enabled: canSwitchToTamil,
            ),
          ],
          selected: {current},
          showSelectedIcon: false,
          onSelectionChanged: (s) =>
              ref.read(readerPrefsProvider.notifier).setLanguage(s.first),
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}

void _showSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(readerPrefsProvider);
    final notifier = ref.read(readerPrefsProvider.notifier);
    final lang = prefs.language;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.t('Display', 'காட்சி'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              lang.t('Font size', 'எழுத்து அளவு'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<FontSize>(
              segments: const [
                ButtonSegment(value: FontSize.s, label: Text('S')),
                ButtonSegment(value: FontSize.m, label: Text('M')),
                ButtonSegment(value: FontSize.l, label: Text('L')),
                ButtonSegment(value: FontSize.xl, label: Text('XL')),
              ],
              selected: {prefs.fontSize},
              onSelectionChanged: (s) => notifier.setFontSize(s.first),
            ),
            const SizedBox(height: 16),
            Text(
              lang.t('Theme', 'தீம்'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(lang.t('System', 'கணினி')),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(lang.t('Light', 'வெளிச்சம்')),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(lang.t('Dark', 'இருள்')),
                ),
              ],
              selected: {prefs.themeMode},
              onSelectionChanged: (s) => notifier.setThemeMode(s.first),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
