# 0001 — Bible Reader — Design

## Layering

```
features/reader/                       # UI, Riverpod providers
   reader_screen.dart
   chapter_view.dart
   verse_widget.dart
   reader_providers.dart               # currentBook, currentChapter, etc.

data/bible/
   bible_database.dart                 # Drift schema (read-only)
   bible_repository.dart               # listBooks, getChapter, search (later)
   book.dart, verse.dart               # plain Dart models

data/prefs/
   reader_prefs_repository.dart        # font size, theme, current language
```

`features/reader/` depends on `data/bible/` and `data/prefs/`. Nothing in `data/` depends on Flutter UI.

## Drift setup

- Two **separate** read-only Drift databases (one per translation) registered at app start under fixed asset paths:
  - `assets/bible/web.sqlite` → `WebBibleDatabase`
  - `assets/bible/ta_uv.sqlite` → `TamilBibleDatabase`
- Both are opened via `LazyDatabase` over `sqlite3_flutter_libs`, copied from assets to the app's documents dir on first launch (Drift's `LazyDatabase` + `_loadFromAsset` pattern).
- `BibleRepository` is constructed with both DB handles and a `currentLanguage` provider; it routes reads to the right DB.

## API surface (`BibleRepository`)

```dart
class BibleRepository {
  Future<List<Book>> listBooks(Lang lang);
  Future<List<int>> chapterCounts(int bookId);          // [50, 40, ...] for nav
  Future<List<Verse>> getChapter(int bookId, int chapter, Lang lang);
}
```

`Verse` is `(int verse, String text)`. `Book` exposes `displayName(Lang)`.

## Translation toggle (FR-BR-03)

The reader screen tracks `currentVerseInView` (a Riverpod state derived from a scroll listener that picks the topmost fully-visible verse). On language toggle:

1. Read `(bookId, chapter, currentVerseInView)`.
2. Switch `currentLanguage` provider → triggers `getChapter` for the new translation.
3. After the rebuild, scroll the new list to the same verse number via a `GlobalKey`-keyed `ScrollablePositionedList`.

Verse numbers map 1:1 across translations because the importer normalizes both to Protestant numbering.

## Display preferences (FR-BR-04)

`reader_prefs_repository.dart` reads/writes `shared_preferences`:

```dart
enum FontSize { s, m, l, xl }
enum ThemeMode { system, light, dark }
```

`features/reader/` consumes these via Riverpod providers; `MaterialApp` consumes `ThemeMode` for app-wide theming.

## Tamil fonts

Bundle `Noto Sans Tamil` as a fallback in `pubspec.yaml`'s `fonts:` section. `TextStyle(fontFamilyFallback: ['Noto Sans Tamil'])` on every verse widget.

## Performance (NFR-PERF-02)

- Drift queries on `(book_id, chapter, translation)` use the `idx_verses_chapter` index; benchmark on a Pixel 6a should be <100 ms.
- `ListView.builder` for the verse list; no eager loading of more than the current chapter.
- Asset SQLite files are uncompressed in the APK to allow `mmap` reads (Android `noCompress` for `.sqlite`).
