import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' as material show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bible/bible_database.dart';
import '../../data/bible/bible_repository.dart';
import '../../data/bible/book.dart';
import '../../data/prefs/reader_prefs_repository.dart';

/// Bound at app start in `main.dart` after `SharedPreferences.getInstance`.
final prefsRepositoryProvider = Provider<ReaderPrefsRepository>(
  (_) => throw StateError('prefsRepositoryProvider not initialised'),
);

/// Initial prefs read at app start. The notifier seeds its state from this.
final initialReaderPrefsProvider = Provider<ReaderPrefs>(
  (_) => throw StateError('initialReaderPrefsProvider not initialised'),
);

class ReaderPrefsNotifier extends Notifier<ReaderPrefs> {
  @override
  ReaderPrefs build() => ref.read(initialReaderPrefsProvider);

  void setFontSize(FontSize v) {
    state = state.copyWith(fontSize: v);
    _persist();
  }

  void setThemeMode(material.ThemeMode v) {
    state = state.copyWith(themeMode: v);
    _persist();
  }

  void setLanguage(Lang v) {
    state = state.copyWith(language: v);
    _persist();
  }

  void _persist() => ref.read(prefsRepositoryProvider).write(state);
}

final readerPrefsProvider =
    NotifierProvider<ReaderPrefsNotifier, ReaderPrefs>(ReaderPrefsNotifier.new);

/// Opens both bundled SQLite databases on first read; English is required,
/// Tamil is optional (returns null until a Tamil source is bundled).
final bibleRepositoryProvider = FutureProvider<BibleRepository>((ref) async {
  final web = await BibleDatabase.openFromAsset('assets/bible/web.sqlite');
  if (web == null) {
    if (kIsWeb) {
      throw StateError(
        'The Bible reader needs a native SQLite runtime, which is not '
        'available in the browser. Run on Android, iOS, or Windows desktop.',
      );
    }
    throw StateError(
      'Bundled WEB SQLite missing. Run `dart run build_bible_db.dart --fetch` '
      'in tools/ to produce app/assets/bible/web.sqlite.',
    );
  }
  // Tamil Indian Revised Version (tam2017) — CC-BY-SA 4.0; attribution
  // surfaced in the About screen (specs/0001-bible-reader/spec.md §Risks #2).
  final tamil =
      await BibleDatabase.openFromAsset('assets/bible/ta_irv.sqlite');
  return BibleRepository(web: web, tamil: tamil);
});

final booksProvider = FutureProvider<List<Book>>((ref) async {
  final repo = await ref.watch(bibleRepositoryProvider.future);
  return repo.listBooks();
});

class ChapterRequest {
  const ChapterRequest({
    required this.bookId,
    required this.chapter,
    required this.lang,
  });
  final int bookId;
  final int chapter;
  final Lang lang;

  @override
  bool operator ==(Object other) =>
      other is ChapterRequest &&
      other.bookId == bookId &&
      other.chapter == chapter &&
      other.lang == lang;

  @override
  int get hashCode => Object.hash(bookId, chapter, lang);
}

final chapterProvider = FutureProvider.family.autoDispose(
  (ref, ChapterRequest req) async {
    final repo = await ref.watch(bibleRepositoryProvider.future);
    return repo.getChapter(req.bookId, req.chapter, req.lang);
  },
);

class ChapterCountRequest {
  const ChapterCountRequest({required this.bookId, required this.lang});
  final int bookId;
  final Lang lang;

  @override
  bool operator ==(Object other) =>
      other is ChapterCountRequest &&
      other.bookId == bookId &&
      other.lang == lang;

  @override
  int get hashCode => Object.hash(bookId, lang);
}

final chapterCountProvider = FutureProvider.family.autoDispose(
  (ref, ChapterCountRequest req) async {
    final repo = await ref.watch(bibleRepositoryProvider.future);
    return repo.chapterCount(req.bookId, req.lang);
  },
);
