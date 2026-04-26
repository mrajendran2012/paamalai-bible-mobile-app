/// Reading language toggle. Persisted via [ReaderPrefsRepository].
enum Lang { en, ta }

/// One row from the bundled `books` table.
class Book {
  const Book({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameTa,
    required this.order,
    required this.testament,
  });

  final int id;
  final String code; // 'GEN' .. 'REV'
  final String nameEn;
  final String nameTa;
  final int order; // 1..66
  final String testament; // 'OT' | 'NT'

  String displayName(Lang lang) => lang == Lang.ta ? nameTa : nameEn;

  factory Book.fromRow(Map<String, Object?> row) => Book(
        id: row['id'] as int,
        code: row['code'] as String,
        nameEn: row['name_en'] as String,
        nameTa: row['name_ta'] as String,
        order: row['order'] as int,
        testament: row['testament'] as String,
      );
}

/// One verse from the bundled `verses` table.
class Verse {
  const Verse({required this.verse, required this.text});

  final int verse;
  final String text;

  factory Verse.fromRow(Map<String, Object?> row) => Verse(
        verse: row['verse'] as int,
        text: row['text'] as String,
      );
}
