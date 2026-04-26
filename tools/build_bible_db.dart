// One-shot importer that produces the bundled SQLite Bible files at
// `app/assets/bible/web.sqlite` and `app/assets/bible/ta_uv.sqlite`.
//
// Usage:
//   dart pub get
//   dart run build_bible_db.dart            # use cached source files
//   dart run build_bible_db.dart --fetch    # download missing sources first
//
// Sources (public domain):
//   English  : World English Bible (WEB)            -> https://ebible.org/web/
//   Tamil    : Tamil Union Version 1957 (TAUV)      -> https://ebible.org/tamil1857/
//
// Source files live in `tools/_cache/<translation>/` (gitignored). Each
// translation source can be either a USFM zip or the scrollmapper JSON dump;
// the parser dispatches on extension.
//
// Output schema (must match specs/0001-bible-reader/spec.md §"Data contracts"):
//   books   (id, code, name_en, name_ta, "order", testament)
//   verses  (book_id, chapter, verse, translation, text)
//   index   idx_verses_chapter on verses(book_id, chapter, translation)

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:sqlite3/sqlite3.dart';

const _outDir = '../app/assets/bible';
const _cacheDir = '_cache';

/// Source registry. Keep URLs stable; if eBible reorganises, override here.
///
/// Tamil note (2026-04-25): the Tamil Union 1957 public-domain source assumed
/// in the original spec is NOT hosted at ebible.org/tamil1857. The available
/// Tamil Bibles on eBible are `tamtcv` (Biblica Contemporary, redistributable)
/// and `tam2017` (Indian Revised, redistributable). Neither is public domain;
/// both require a license review before bundling. Until the project owner
/// picks a Tamil source, only WEB is built. See specs/0001-bible-reader/spec.md
/// §Risks.
const _sources = <String, _SourceSpec>{
  'WEB':  _SourceSpec(
    translationCode: 'WEB',
    outFile: 'web.sqlite',
    primaryUrl: 'https://ebible.org/Scriptures/eng-web_usfm.zip',
    expectedVerses: 31102,
  ),
  // 'TAUV': pending license/source decision (see note above).
};

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addFlag('fetch', help: 'Download missing source archives before importing.')
    ..addOption('only', help: 'Comma-separated translation codes to build.');
  final args = parser.parse(argv);
  final only = (args['only'] as String?)?.split(',').map((s) => s.trim()).toSet();

  Directory(_cacheDir).createSync(recursive: true);
  Directory(_outDir).createSync(recursive: true);

  for (final entry in _sources.entries) {
    if (only != null && !only.contains(entry.key)) continue;
    await _buildOne(entry.value, fetchIfMissing: args['fetch'] as bool);
  }
}

Future<void> _buildOne(_SourceSpec spec, {required bool fetchIfMissing}) async {
  stdout.writeln('==> ${spec.translationCode}');

  final cachedZip = File('$_cacheDir/${spec.translationCode}.zip');
  if (!cachedZip.existsSync()) {
    if (!fetchIfMissing) {
      stderr.writeln('Missing source: ${cachedZip.path}');
      stderr.writeln('  Re-run with --fetch, or place the USFM zip there manually.');
      exitCode = 2;
      return;
    }
    stdout.writeln('  fetching ${spec.primaryUrl}');
    final res = await http.get(Uri.parse(spec.primaryUrl));
    if (res.statusCode != 200) {
      stderr.writeln('  fetch failed: HTTP ${res.statusCode}');
      exitCode = 2;
      return;
    }
    cachedZip.writeAsBytesSync(res.bodyBytes);
  }

  // Parse USFM zip to a list of verse rows. Implemented by `_parseUsfmZip`.
  final verses = _parseUsfmZip(cachedZip, translation: spec.translationCode);
  stdout.writeln('  parsed ${verses.length} verses '
      '(expected ~${spec.expectedVerses})');
  if ((verses.length - spec.expectedVerses).abs() > 200) {
    stderr.writeln('  WARNING: verse count differs from expected by '
        '${(verses.length - spec.expectedVerses).abs()}; investigate.');
  }

  // Write the SQLite output.
  final outPath = '$_outDir/${spec.outFile}';
  final outFile = File(outPath);
  if (outFile.existsSync()) outFile.deleteSync();
  final db = sqlite3.open(outPath);
  try {
    _ensureSchema(db);
    _writeBooks(db);
    _insertVerses(db, verses);
  } finally {
    db.dispose();
  }
  stdout.writeln('  wrote $outPath');
}

void _ensureSchema(Database db) {
  db.execute('''
    create table if not exists books (
      id        integer primary key,
      code      text not null unique,
      name_en   text not null,
      name_ta   text not null,
      "order"   integer not null,
      testament text not null check (testament in ('OT','NT'))
    );
    create table if not exists verses (
      book_id     integer not null references books(id),
      chapter     integer not null,
      verse       integer not null,
      translation text    not null,
      text        text    not null,
      primary key (book_id, chapter, verse, translation)
    );
    create index if not exists idx_verses_chapter
      on verses(book_id, chapter, translation);
  ''');
}

void _writeBooks(Database db) {
  // Static metadata; sourced from canon.dart in the app + curated Tamil book names.
  final stmt = db.prepare(
    'insert or replace into books (id, code, name_en, name_ta, "order", testament) '
    'values (?, ?, ?, ?, ?, ?)',
  );
  try {
    var i = 1;
    for (final row in _bookCatalog) {
      stmt.execute([i, row.code, row.nameEn, row.nameTa, i, row.testament]);
      i++;
    }
  } finally {
    stmt.dispose();
  }
}

void _insertVerses(Database db, List<_VerseRow> verses) {
  final bookIdByCode = <String, int>{};
  for (final r in db.select('select id, code from books')) {
    bookIdByCode[r['code'] as String] = r['id'] as int;
  }
  final stmt = db.prepare(
    'insert into verses (book_id, chapter, verse, translation, text) '
    'values (?, ?, ?, ?, ?)',
  );
  db.execute('begin');
  try {
    for (final v in verses) {
      final id = bookIdByCode[v.bookCode];
      if (id == null) continue; // skip apocrypha/etc.
      stmt.execute([id, v.chapter, v.verse, v.translation, v.text]);
    }
    db.execute('commit');
  } catch (_) {
    db.execute('rollback');
    rethrow;
  } finally {
    stmt.dispose();
  }
}

// ---------- USFM parsing ----------
//
// USFM is a markup format used by SIL/eBible. We only care about three markers:
//   \c <n>      -- chapter
//   \v <n> ...  -- verse start
//   text follows on subsequent lines until the next \v or \c
//
// The eBible USFM zip contains one file per book, named like `41-MATeng-web.usfm`
// (book number + 3-letter code). We map the 3-letter code to our canonical code.
//
// For the first cut we assume the single-file-per-book layout. If a future
// source uses one-big-USFM we can branch on that.

List<_VerseRow> _parseUsfmZip(File zipFile, {required String translation}) {
  final bytes = zipFile.readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  final out = <_VerseRow>[];

  // Sort longest-first so '1SA' is tested before any 2-char prefix overlap.
  final codes = _usfmToCanon.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  for (final f in archive) {
    if (!f.isFile) continue;
    final name = f.name;
    if (!name.toLowerCase().endsWith('.usfm')) continue;
    final base = name.split('/').last.split('.').first;

    String? bookCode;
    for (final code in codes) {
      // eBible filenames look like '41-MATeng-web.usfm' or 'MAT.usfm'.
      // The book code is uppercase, preceded by start-of-string or '-',
      // and followed by the lowercase language code or end-of-string.
      final pattern =
          RegExp(r'(?:^|-)' + RegExp.escape(code) + r'(?=[a-z\-]|$)');
      if (pattern.hasMatch(base)) {
        bookCode = _usfmToCanon[code]!;
        break;
      }
    }
    if (bookCode == null) continue;

    final raw = f.content as List<int>;
    final content = utf8
        .decode(raw, allowMalformed: true)
        .replaceFirst('﻿', ''); // strip BOM if present
    out.addAll(_parseUsfmContent(content, bookCode, translation));
  }
  return out;
}

/// Parse a single USFM document into verse rows. Pure: no I/O.
List<_VerseRow> _parseUsfmContent(
  String content,
  String bookCode,
  String translation,
) {
  final out = <_VerseRow>[];
  int? chapter;
  int? verse;
  final buf = StringBuffer();

  void flush() {
    if (chapter != null && verse != null) {
      final text = _cleanMarkers(buf.toString());
      if (text.isNotEmpty) {
        out.add(_VerseRow(bookCode, chapter!, verse!, translation, text));
      }
    }
    buf.clear();
  }

  // \c N or \v N (verse number can have a trailing alpha marker like '\v 16a').
  final re = RegExp(r'\\([cv])\s+(\d+)[a-z]?\s?');
  var cursor = 0;
  for (final m in re.allMatches(content)) {
    if (m.start > cursor) buf.write(content.substring(cursor, m.start));
    final kind = m.group(1)!;
    final n = int.parse(m.group(2)!);
    if (kind == 'c') {
      flush();
      chapter = n;
      verse = null;
    } else {
      flush();
      verse = n;
    }
    cursor = m.end;
  }
  if (cursor < content.length) buf.write(content.substring(cursor));
  flush();
  return out;
}

/// Strip USFM markup, leaving only the textual content of a verse.
String _cleanMarkers(String input) {
  var s = input;

  // 1. Drop footnotes / cross-refs / figures (paired markers, lazy match).
  for (final tag in const ['f', 'fe', 'x', 'fig']) {
    s = s.replaceAll(
      RegExp('\\\\$tag\\b[\\s\\S]*?\\\\$tag\\*'),
      '',
    );
  }

  // 2. Drop heading / metadata lines whose first marker is non-verse content.
  const headingTags = {
    'h', 'toc1', 'toc2', 'toc3',
    'mt', 'mt1', 'mt2', 'mt3', 'mt4',
    'ms', 'ms1', 'ms2', 'mr',
    's', 's1', 's2', 's3', 's4', 'sr',
    'r', 'rq', 'd', 'sp',
    'rem', 'id', 'ide',
    'imt', 'imt1', 'imt2', 'imt3', 'imt4',
    'is', 'is1', 'is2',
    'ip', 'ipi', 'ipq', 'iot',
    'io', 'io1', 'io2',
    'ie', 'iex', 'imte', 'imte1', 'imte2',
    'cp', 'ca', 'va', 'vp', 'cl',
  };
  s = s.split('\n').where((line) {
    final t = line.trimLeft();
    if (!t.startsWith('\\')) return true;
    final m = RegExp(r'\\([a-z]+\d*)').firstMatch(t);
    if (m == null) return true;
    return !headingTags.contains(m.group(1));
  }).join('\n');

  // 3. Strip USFM 3 word attributes: text|attr="val"  -> text
  //    The pipe delimits the attribute block; everything up to the next
  //    backslash (close marker) belongs to attributes, not the rendered text.
  s = s.replaceAll(RegExp(r'\|[^\\\n]*'), '');

  // 4. Strip remaining markers — closes first, then opens.
  //    `\+?` allows nested character markers (USFM 3): \+w ... \+w*.
  s = s.replaceAll(RegExp(r'\\\+?[a-z]+\d*\*'), '');
  s = s.replaceAll(RegExp(r'\\\+?[a-z]+\d*\b\s?'), '');

  // 5. Whitespace normalisation.
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// USFM 3-letter code -> our canonical code.
const _usfmToCanon = <String, String>{
  'GEN':'GEN','EXO':'EXO','LEV':'LEV','NUM':'NUM','DEU':'DEU',
  'JOS':'JOS','JDG':'JDG','RUT':'RUT','1SA':'1SA','2SA':'2SA',
  '1KI':'1KI','2KI':'2KI','1CH':'1CH','2CH':'2CH','EZR':'EZR',
  'NEH':'NEH','EST':'EST','JOB':'JOB','PSA':'PSA','PRO':'PRO',
  'ECC':'ECC','SNG':'SNG','ISA':'ISA','JER':'JER','LAM':'LAM',
  'EZK':'EZK','DAN':'DAN','HOS':'HOS','JOL':'JOL','AMO':'AMO',
  'OBA':'OBA','JON':'JON','MIC':'MIC','NAM':'NAM','HAB':'HAB',
  'ZEP':'ZEP','HAG':'HAG','ZEC':'ZEC','MAL':'MAL',
  'MAT':'MAT','MRK':'MRK','LUK':'LUK','JHN':'JHN','ACT':'ACT',
  'ROM':'ROM','1CO':'1CO','2CO':'2CO','GAL':'GAL','EPH':'EPH',
  'PHP':'PHP','COL':'COL','1TH':'1TH','2TH':'2TH','1TI':'1TI',
  '2TI':'2TI','TIT':'TIT','PHM':'PHM','HEB':'HEB','JAS':'JAS',
  '1PE':'1PE','2PE':'2PE','1JN':'1JN','2JN':'2JN','3JN':'3JN',
  'JUD':'JUD','REV':'REV',
};

// ---------- types ----------

class _SourceSpec {
  final String translationCode;
  final String outFile;
  final String primaryUrl;
  final int expectedVerses;
  const _SourceSpec({
    required this.translationCode,
    required this.outFile,
    required this.primaryUrl,
    required this.expectedVerses,
  });
}

class _VerseRow {
  final String bookCode;
  final int chapter;
  final int verse;
  final String translation;
  final String text;
  const _VerseRow(
    this.bookCode,
    this.chapter,
    this.verse,
    this.translation,
    this.text,
  );
}

class _BookMeta {
  final String code;
  final String nameEn;
  final String nameTa;
  final String testament;
  const _BookMeta(this.code, this.nameEn, this.nameTa, this.testament);
}

const _bookCatalog = <_BookMeta>[
  _BookMeta('GEN','Genesis','ஆதியாகமம்','OT'),
  _BookMeta('EXO','Exodus','யாத்திராகமம்','OT'),
  _BookMeta('LEV','Leviticus','லேவியராகமம்','OT'),
  _BookMeta('NUM','Numbers','எண்ணாகமம்','OT'),
  _BookMeta('DEU','Deuteronomy','உபாகமம்','OT'),
  _BookMeta('JOS','Joshua','யோசுவா','OT'),
  _BookMeta('JDG','Judges','நியாயாதிபதிகள்','OT'),
  _BookMeta('RUT','Ruth','ரூத்','OT'),
  _BookMeta('1SA','1 Samuel','1 சாமுவேல்','OT'),
  _BookMeta('2SA','2 Samuel','2 சாமுவேல்','OT'),
  _BookMeta('1KI','1 Kings','1 இராஜாக்கள்','OT'),
  _BookMeta('2KI','2 Kings','2 இராஜாக்கள்','OT'),
  _BookMeta('1CH','1 Chronicles','1 நாளாகமம்','OT'),
  _BookMeta('2CH','2 Chronicles','2 நாளாகமம்','OT'),
  _BookMeta('EZR','Ezra','எஸ்றா','OT'),
  _BookMeta('NEH','Nehemiah','நெகேமியா','OT'),
  _BookMeta('EST','Esther','எஸ்தர்','OT'),
  _BookMeta('JOB','Job','யோபு','OT'),
  _BookMeta('PSA','Psalms','சங்கீதம்','OT'),
  _BookMeta('PRO','Proverbs','நீதிமொழிகள்','OT'),
  _BookMeta('ECC','Ecclesiastes','பிரசங்கி','OT'),
  _BookMeta('SNG','Song of Solomon','உன்னதப்பாட்டு','OT'),
  _BookMeta('ISA','Isaiah','ஏசாயா','OT'),
  _BookMeta('JER','Jeremiah','எரேமியா','OT'),
  _BookMeta('LAM','Lamentations','புலம்பல்','OT'),
  _BookMeta('EZK','Ezekiel','எசேக்கியேல்','OT'),
  _BookMeta('DAN','Daniel','தானியேல்','OT'),
  _BookMeta('HOS','Hosea','ஓசியா','OT'),
  _BookMeta('JOL','Joel','யோவேல்','OT'),
  _BookMeta('AMO','Amos','ஆமோஸ்','OT'),
  _BookMeta('OBA','Obadiah','ஒபதியா','OT'),
  _BookMeta('JON','Jonah','யோனா','OT'),
  _BookMeta('MIC','Micah','மீகா','OT'),
  _BookMeta('NAM','Nahum','நாகூம்','OT'),
  _BookMeta('HAB','Habakkuk','ஆபகூக்','OT'),
  _BookMeta('ZEP','Zephaniah','செப்பனியா','OT'),
  _BookMeta('HAG','Haggai','ஆகாய்','OT'),
  _BookMeta('ZEC','Zechariah','சகரியா','OT'),
  _BookMeta('MAL','Malachi','மல்கியா','OT'),
  _BookMeta('MAT','Matthew','மத்தேயு','NT'),
  _BookMeta('MRK','Mark','மாற்கு','NT'),
  _BookMeta('LUK','Luke','லூக்கா','NT'),
  _BookMeta('JHN','John','யோவான்','NT'),
  _BookMeta('ACT','Acts','அப்போஸ்தலர்','NT'),
  _BookMeta('ROM','Romans','ரோமர்','NT'),
  _BookMeta('1CO','1 Corinthians','1 கொரிந்தியர்','NT'),
  _BookMeta('2CO','2 Corinthians','2 கொரிந்தியர்','NT'),
  _BookMeta('GAL','Galatians','கலாத்தியர்','NT'),
  _BookMeta('EPH','Ephesians','எபேசியர்','NT'),
  _BookMeta('PHP','Philippians','பிலிப்பியர்','NT'),
  _BookMeta('COL','Colossians','கொலோசெயர்','NT'),
  _BookMeta('1TH','1 Thessalonians','1 தெசலோனிக்கேயர்','NT'),
  _BookMeta('2TH','2 Thessalonians','2 தெசலோனிக்கேயர்','NT'),
  _BookMeta('1TI','1 Timothy','1 தீமோத்தேயு','NT'),
  _BookMeta('2TI','2 Timothy','2 தீமோத்தேயு','NT'),
  _BookMeta('TIT','Titus','தீத்து','NT'),
  _BookMeta('PHM','Philemon','பிலேமோன்','NT'),
  _BookMeta('HEB','Hebrews','எபிரெயர்','NT'),
  _BookMeta('JAS','James','யாக்கோபு','NT'),
  _BookMeta('1PE','1 Peter','1 பேதுரு','NT'),
  _BookMeta('2PE','2 Peter','2 பேதுரு','NT'),
  _BookMeta('1JN','1 John','1 யோவான்','NT'),
  _BookMeta('2JN','2 John','2 யோவான்','NT'),
  _BookMeta('3JN','3 John','3 யோவான்','NT'),
  _BookMeta('JUD','Jude','யூதா','NT'),
  _BookMeta('REV','Revelation','வெளிப்படுத்தின விசேஷம்','NT'),
];
