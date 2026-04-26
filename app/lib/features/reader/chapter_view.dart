import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../data/bible/book.dart';
import '../../data/prefs/reader_prefs_repository.dart';
import 'reader_providers.dart';
import 'verse_widget.dart';

/// Renders one chapter as a scrollable list of verses with verse-anchored
/// language toggle (FR-BR-02, FR-BR-03).
class ChapterView extends ConsumerStatefulWidget {
  const ChapterView({required this.bookCode, required this.chapter, super.key});

  final String bookCode;
  final int chapter;

  @override
  ConsumerState<ChapterView> createState() => _ChapterViewState();
}

class _ChapterViewState extends ConsumerState<ChapterView> {
  final _itemScrollController = ItemScrollController();
  final _itemPositionsListener = ItemPositionsListener.create();

  /// The verse number currently anchoring the viewport (used to preserve
  /// scroll on language toggle).
  int _anchorVerse = 1;

  Stopwatch? _openTimer;

  @override
  void initState() {
    super.initState();
    _openTimer = Stopwatch()..start();
    _itemPositionsListener.itemPositions.addListener(_onScroll);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    // Pick the topmost item whose leading edge is at or below the viewport top.
    final visible = positions
        .where((p) => p.itemLeadingEdge >= 0)
        .toList()
      ..sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    if (visible.isEmpty) return;
    final v = visible.first.index + 1;
    if (v != _anchorVerse) _anchorVerse = v;
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(readerPrefsProvider);
    final asyncBooks = ref.watch(booksProvider);
    final asyncRepo = ref.watch(bibleRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/reader'),
        ),
        title: asyncBooks.when(
          loading: () => const Text(''),
          error: (_, __) => Text('${widget.bookCode} ${widget.chapter}'),
          data: (books) {
            final book = books.firstWhere(
              (b) => b.code == widget.bookCode,
              orElse: () => Book(
                id: 0,
                code: widget.bookCode,
                nameEn: widget.bookCode,
                nameTa: widget.bookCode,
                order: 0,
                testament: 'OT',
              ),
            );
            return Text('${book.displayName(prefs.language)} ${widget.chapter}');
          },
        ),
        actions: [
          _LangPill(
            current: prefs.language,
            tamilEnabled: asyncRepo.maybeWhen(
              data: (r) => r.hasTamil,
              orElse: () => false,
            ),
            onChanged: (lang) =>
                ref.read(readerPrefsProvider.notifier).setLanguage(lang),
          ),
          PopupMenuButton<_MenuAction>(
            icon: const Icon(Icons.more_vert),
            onSelected: (a) => _onMenu(a, context, ref),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _MenuAction.settings, child: Text('Display settings')),
            ],
          ),
        ],
      ),
      body: asyncBooks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (books) {
          final book = books.firstWhere(
            (b) => b.code == widget.bookCode,
            orElse: () => throw StateError('unknown book ${widget.bookCode}'),
          );
          final asyncVerses = ref.watch(
            chapterProvider(
              ChapterRequest(
                bookId: book.id,
                chapter: widget.chapter,
                lang: prefs.language,
              ),
            ),
          );
          return asyncVerses.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (verses) {
              _logFirstFrame(verses.length);
              if (verses.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No verses for this chapter in the selected translation.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              // After a language toggle, jump back to the previous anchor verse.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_itemScrollController.isAttached) return;
                if (_anchorVerse <= 1) return;
                _itemScrollController.jumpTo(index: _anchorVerse - 1);
              });
              return ScrollablePositionedList.builder(
                itemCount: verses.length,
                itemScrollController: _itemScrollController,
                itemPositionsListener: _itemPositionsListener,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemBuilder: (_, i) {
                  final v = verses[i];
                  return VerseWidget(
                    verse: v.verse,
                    text: v.text,
                    fontSize: prefs.fontSize,
                    lang: prefs.language,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _logFirstFrame(int verseCount) {
    if (_openTimer == null) return;
    final t = _openTimer!.elapsedMilliseconds;
    _openTimer = null;
    if (kDebugMode) {
      // ignore: avoid_print
      print('[reader] chapter open in ${t}ms ($verseCount verses) — NFR-PERF-02 target ≤500ms');
    }
  }

  void _onMenu(_MenuAction action, BuildContext context, WidgetRef ref) {
    switch (action) {
      case _MenuAction.settings:
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) => const _ChapterSettingsSheet(),
        );
    }
  }
}

enum _MenuAction { settings }

class _LangPill extends StatelessWidget {
  const _LangPill({
    required this.current,
    required this.tamilEnabled,
    required this.onChanged,
  });
  final Lang current;
  final bool tamilEnabled;
  final ValueChanged<Lang> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: SegmentedButton<Lang>(
          segments: [
            const ButtonSegment(value: Lang.en, label: Text('EN')),
            ButtonSegment(
              value: Lang.ta,
              label: const Text('TA'),
              enabled: tamilEnabled,
            ),
          ],
          selected: {current},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onChanged(s.first),
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}

class _ChapterSettingsSheet extends ConsumerWidget {
  const _ChapterSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(readerPrefsProvider);
    final notifier = ref.read(readerPrefsProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Font size', style: Theme.of(context).textTheme.labelLarge),
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
            Text('Theme', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
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
