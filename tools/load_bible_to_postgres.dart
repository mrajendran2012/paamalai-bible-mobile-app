// One-shot script that uploads the bundled SQLite Bible files into the
// Supabase Postgres `public.bible_verses` table so the `generate-devotion`
// edge function can resolve any plan-day passage.
//
// Run after `build_bible_db.dart` has produced app/assets/bible/*.sqlite, and
// after `supabase db reset` (locally) or `supabase db push` (prod) has applied
// migration 0001.
//
// Usage:
//   dart pub get
//   dart run load_bible_to_postgres.dart \
//       --pg-url=postgres://postgres:postgres@localhost:54322/postgres
//
// For prod, supply the project's transaction-pooler URL (find in Supabase
// dashboard -> Settings -> Database).

import 'dart:io';
import 'package:args/args.dart';
import 'package:postgres/postgres.dart';
import 'package:sqlite3/sqlite3.dart';

const _bibles = <_Source>[
  _Source(translation: 'WEB',  path: '../app/assets/bible/web.sqlite'),
  _Source(translation: 'TAUV', path: '../app/assets/bible/ta_uv.sqlite'),
];

Future<void> main(List<String> argv) async {
  final args = (ArgParser()
    ..addOption('pg-url', help: 'Postgres connection URL', mandatory: true))
    .parse(argv);

  final uri = Uri.parse(args['pg-url'] as String);
  final conn = await Connection.open(
    Endpoint(
      host: uri.host,
      port: uri.port == 0 ? 5432 : uri.port,
      database: uri.path.replaceFirst('/', ''),
      username: uri.userInfo.split(':').first,
      password: Uri.decodeComponent(uri.userInfo.split(':').last),
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    for (final src in _bibles) {
      stdout.writeln('==> ${src.translation}');
      final file = File(src.path);
      if (!file.existsSync()) {
        stderr.writeln('  missing ${src.path} — run build_bible_db.dart first');
        exitCode = 2;
        continue;
      }
      final db = sqlite3.open(src.path);
      try {
        // Wipe existing rows for this translation to keep the script idempotent.
        await conn.execute(
          Sql.named('delete from public.bible_verses where translation = @t'),
          parameters: {'t': src.translation},
        );

        // Stream + batch insert.
        final rows = db.select('''
          select b.code as book_code, v.chapter, v.verse, v.text
          from verses v
          join books b on b.id = v.book_id
          where v.translation = ?
          order by b.id, v.chapter, v.verse
        ''', [src.translation]);

        var batch = <Map<String, Object?>>[];
        var inserted = 0;
        const batchSize = 500;

        for (final row in rows) {
          batch.add({
            't': src.translation,
            'b': row['book_code'],
            'c': row['chapter'],
            'v': row['verse'],
            'x': row['text'],
          });
          if (batch.length == batchSize) {
            inserted += await _flush(conn, batch);
            batch = [];
          }
        }
        if (batch.isNotEmpty) inserted += await _flush(conn, batch);
        stdout.writeln('  uploaded $inserted verses');
      } finally {
        db.dispose();
      }
    }
  } finally {
    await conn.close();
  }
}

Future<int> _flush(Connection conn, List<Map<String, Object?>> batch) async {
  // Multi-row insert built dynamically because postgres dart driver doesn't
  // support array-of-rows binding directly.
  final placeholders = <String>[];
  final params = <String, Object?>{};
  for (var i = 0; i < batch.length; i++) {
    placeholders.add('(@t$i, @b$i, @c$i, @v$i, @x$i)');
    params['t$i'] = batch[i]['t'];
    params['b$i'] = batch[i]['b'];
    params['c$i'] = batch[i]['c'];
    params['v$i'] = batch[i]['v'];
    params['x$i'] = batch[i]['x'];
  }
  final sql = 'insert into public.bible_verses '
      '(translation, book_code, chapter, verse, text) values '
      '${placeholders.join(',')}';
  await conn.execute(Sql.named(sql), parameters: params);
  return batch.length;
}

class _Source {
  final String translation;
  final String path;
  const _Source({required this.translation, required this.path});
}
