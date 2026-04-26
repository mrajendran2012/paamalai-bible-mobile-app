// Quick post-import sanity check.
//   dart run verify_db.dart ../app/assets/bible/web.sqlite

import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main(List<String> argv) {
  if (argv.isEmpty) {
    stderr.writeln('usage: dart run verify_db.dart <path-to.sqlite>');
    exit(64);
  }
  final db = sqlite3.open(argv.first);
  try {
    final books = db.select('select count(*) c from books').first['c'];
    final verses = db.select('select count(*) c from verses').first['c'];
    print('books:  $books');
    print('verses: $verses');

    void show(String code, int chap, int v) {
      final rows = db.select(
        "select v.verse, v.text "
        "from verses v join books b on b.id=v.book_id "
        "where b.code=? and v.chapter=? and v.verse=?",
        [code, chap, v],
      );
      if (rows.isEmpty) {
        print('$code $chap:$v -> NOT FOUND');
      } else {
        final t = rows.first['text'] as String;
        final snip = t.length > 90 ? '${t.substring(0, 90)}…' : t;
        print('$code $chap:$v -> $snip');
      }
    }

    show('GEN', 1, 1);
    show('JHN', 3, 16);
    show('PSA', 23, 1);
    show('REV', 22, 21);
  } finally {
    db.dispose();
  }
}
