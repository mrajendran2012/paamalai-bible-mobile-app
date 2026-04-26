import 'bible_database.dart';
import 'book.dart';

/// Read-only access to the bundled Bible SQLite databases.
///
/// English is required (always bundled); Tamil is optional until the project
/// owner picks a v1 Tamil source — see specs/0001-bible-reader/spec.md §Risks.
/// When [tamil] is null, [getChapter] silently falls back to English so the
/// reader still works.
class BibleRepository {
  BibleRepository({required this.web, this.tamil});

  final BibleDatabase web;
  final BibleDatabase? tamil;

  bool get hasTamil => tamil != null;

  BibleDatabase _dbFor(Lang lang) {
    if (lang == Lang.ta && tamil != null) return tamil!;
    return web;
  }

  /// All 66 books in canonical order.
  Future<List<Book>> listBooks() async {
    final rows = await web.select(
      'SELECT id, code, name_en, name_ta, "order", testament '
      'FROM books ORDER BY "order"',
    );
    return rows.map(Book.fromRow).toList();
  }

  /// Maximum chapter number for [bookId] in the active translation.
  Future<int> chapterCount(int bookId, Lang lang) async {
    final db = _dbFor(lang);
    final rows = await db.select(
      'SELECT MAX(chapter) AS c FROM verses WHERE book_id = ?',
      [bookId],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// Returns every verse in [bookId]:[chapter] in [lang], sorted by verse.
  Future<List<Verse>> getChapter(int bookId, int chapter, Lang lang) async {
    final db = _dbFor(lang);
    final rows = await db.select(
      'SELECT verse, text FROM verses '
      'WHERE book_id = ? AND chapter = ? ORDER BY verse',
      [bookId, chapter],
    );
    return rows.map(Verse.fromRow).toList();
  }
}
