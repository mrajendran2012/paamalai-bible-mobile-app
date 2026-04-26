/// Canonical Protestant Bible book codes in reading order, with chapter counts.
///
/// Sum of [canonChapterCounts] values must equal 1189. Asserted in
/// `test/yearly_plan_test.dart`.
const List<String> canonOrder = [
  // Old Testament — 39 books, 929 chapters
  'GEN', 'EXO', 'LEV', 'NUM', 'DEU',
  'JOS', 'JDG', 'RUT', '1SA', '2SA',
  '1KI', '2KI', '1CH', '2CH', 'EZR',
  'NEH', 'EST', 'JOB', 'PSA', 'PRO',
  'ECC', 'SNG', 'ISA', 'JER', 'LAM',
  'EZK', 'DAN', 'HOS', 'JOL', 'AMO',
  'OBA', 'JON', 'MIC', 'NAM', 'HAB',
  'ZEP', 'HAG', 'ZEC', 'MAL',
  // New Testament — 27 books, 260 chapters
  'MAT', 'MRK', 'LUK', 'JHN', 'ACT',
  'ROM', '1CO', '2CO', 'GAL', 'EPH',
  'PHP', 'COL', '1TH', '2TH', '1TI',
  '2TI', 'TIT', 'PHM', 'HEB', 'JAS',
  '1PE', '2PE', '1JN', '2JN', '3JN',
  'JUD', 'REV',
];

const Map<String, int> canonChapterCounts = {
  // Old Testament
  'GEN': 50, 'EXO': 40, 'LEV': 27, 'NUM': 36, 'DEU': 34,
  'JOS': 24, 'JDG': 21, 'RUT': 4,  '1SA': 31, '2SA': 24,
  '1KI': 22, '2KI': 25, '1CH': 29, '2CH': 36, 'EZR': 10,
  'NEH': 13, 'EST': 10, 'JOB': 42, 'PSA': 150, 'PRO': 31,
  'ECC': 12, 'SNG': 8,  'ISA': 66, 'JER': 52, 'LAM': 5,
  'EZK': 48, 'DAN': 12, 'HOS': 14, 'JOL': 3,  'AMO': 9,
  'OBA': 1,  'JON': 4,  'MIC': 7,  'NAM': 3,  'HAB': 3,
  'ZEP': 3,  'HAG': 2,  'ZEC': 14, 'MAL': 4,
  // New Testament
  'MAT': 28, 'MRK': 16, 'LUK': 24, 'JHN': 21, 'ACT': 28,
  'ROM': 16, '1CO': 16, '2CO': 13, 'GAL': 6,  'EPH': 6,
  'PHP': 4,  'COL': 4,  '1TH': 5,  '2TH': 3,  '1TI': 6,
  '2TI': 4,  'TIT': 3,  'PHM': 1,  'HEB': 13, 'JAS': 5,
  '1PE': 5,  '2PE': 3,  '1JN': 5,  '2JN': 1,  '3JN': 1,
  'JUD': 1,  'REV': 22,
};

const int totalChapters = 1189;

/// English display names. The reader UI uses the bundled SQLite `books` table
/// for localized names where it has a [Book] in hand; this map is the fallback
/// for screens (Plan, Catch-up) that hold only a `bookCode` + chapter.
const Map<String, String> bookNamesEn = {
  'GEN': 'Genesis', 'EXO': 'Exodus', 'LEV': 'Leviticus', 'NUM': 'Numbers',
  'DEU': 'Deuteronomy', 'JOS': 'Joshua', 'JDG': 'Judges', 'RUT': 'Ruth',
  '1SA': '1 Samuel', '2SA': '2 Samuel', '1KI': '1 Kings', '2KI': '2 Kings',
  '1CH': '1 Chronicles', '2CH': '2 Chronicles', 'EZR': 'Ezra',
  'NEH': 'Nehemiah', 'EST': 'Esther', 'JOB': 'Job', 'PSA': 'Psalms',
  'PRO': 'Proverbs', 'ECC': 'Ecclesiastes', 'SNG': 'Song of Solomon',
  'ISA': 'Isaiah', 'JER': 'Jeremiah', 'LAM': 'Lamentations', 'EZK': 'Ezekiel',
  'DAN': 'Daniel', 'HOS': 'Hosea', 'JOL': 'Joel', 'AMO': 'Amos',
  'OBA': 'Obadiah', 'JON': 'Jonah', 'MIC': 'Micah', 'NAM': 'Nahum',
  'HAB': 'Habakkuk', 'ZEP': 'Zephaniah', 'HAG': 'Haggai', 'ZEC': 'Zechariah',
  'MAL': 'Malachi', 'MAT': 'Matthew', 'MRK': 'Mark', 'LUK': 'Luke',
  'JHN': 'John', 'ACT': 'Acts', 'ROM': 'Romans', '1CO': '1 Corinthians',
  '2CO': '2 Corinthians', 'GAL': 'Galatians', 'EPH': 'Ephesians',
  'PHP': 'Philippians', 'COL': 'Colossians', '1TH': '1 Thessalonians',
  '2TH': '2 Thessalonians', '1TI': '1 Timothy', '2TI': '2 Timothy',
  'TIT': 'Titus', 'PHM': 'Philemon', 'HEB': 'Hebrews', 'JAS': 'James',
  '1PE': '1 Peter', '2PE': '2 Peter', '1JN': '1 John', '2JN': '2 John',
  '3JN': '3 John', 'JUD': 'Jude', 'REV': 'Revelation',
};

/// Tamil display names. Mirrors [bookNamesEn]. Sourced from the same Tamil
/// book-name set used by `tools/build_bible_db.dart` to populate the SQLite
/// `books.name_ta` column, so a `book.displayName(Lang.ta)` lookup and a
/// `bookNamesTa[code]` lookup return the same string for the same book.
///
/// TODO: native-speaker review pass before launch (specs/0001-bible-reader
/// §Risks).
const Map<String, String> bookNamesTa = {
  // Old Testament
  'GEN': 'ஆதியாகமம்', 'EXO': 'யாத்திராகமம்', 'LEV': 'லேவியராகமம்',
  'NUM': 'எண்ணாகமம்', 'DEU': 'உபாகமம்', 'JOS': 'யோசுவா',
  'JDG': 'நியாயாதிபதிகள்', 'RUT': 'ரூத்', '1SA': '1 சாமுவேல்',
  '2SA': '2 சாமுவேல்', '1KI': '1 இராஜாக்கள்', '2KI': '2 இராஜாக்கள்',
  '1CH': '1 நாளாகமம்', '2CH': '2 நாளாகமம்', 'EZR': 'எஸ்றா',
  'NEH': 'நெகேமியா', 'EST': 'எஸ்தர்', 'JOB': 'யோபு',
  'PSA': 'சங்கீதம்', 'PRO': 'நீதிமொழிகள்', 'ECC': 'பிரசங்கி',
  'SNG': 'உன்னதப்பாட்டு', 'ISA': 'ஏசாயா', 'JER': 'எரேமியா',
  'LAM': 'புலம்பல்', 'EZK': 'எசேக்கியேல்', 'DAN': 'தானியேல்',
  'HOS': 'ஓசியா', 'JOL': 'யோவேல்', 'AMO': 'ஆமோஸ்', 'OBA': 'ஒபதியா',
  'JON': 'யோனா', 'MIC': 'மீகா', 'NAM': 'நாகூம்', 'HAB': 'ஆபகூக்',
  'ZEP': 'செப்பனியா', 'HAG': 'ஆகாய்', 'ZEC': 'சகரியா', 'MAL': 'மல்கியா',
  // New Testament
  'MAT': 'மத்தேயு', 'MRK': 'மாற்கு', 'LUK': 'லூக்கா', 'JHN': 'யோவான்',
  'ACT': 'அப்போஸ்தலர்', 'ROM': 'ரோமர்', '1CO': '1 கொரிந்தியர்',
  '2CO': '2 கொரிந்தியர்', 'GAL': 'கலாத்தியர்', 'EPH': 'எபேசியர்',
  'PHP': 'பிலிப்பியர்', 'COL': 'கொலோசெயர்', '1TH': '1 தெசலோனிக்கேயர்',
  '2TH': '2 தெசலோனிக்கேயர்', '1TI': '1 தீமோத்தேயு', '2TI': '2 தீமோத்தேயு',
  'TIT': 'தீத்து', 'PHM': 'பிலேமோன்', 'HEB': 'எபிரெயர்', 'JAS': 'யாக்கோபு',
  '1PE': '1 பேதுரு', '2PE': '2 பேதுரு', '1JN': '1 யோவான்',
  '2JN': '2 யோவான்', '3JN': '3 யோவான்', 'JUD': 'யூதா',
  'REV': 'வெளிப்படுத்தின விசேஷம்',
};

/// Language-aware book-name helper for screens that hold only a `bookCode`.
/// Falls back to the code itself if neither map has the entry (defensive
/// against typos).
String bookNameFor(String code, bool tamil) {
  final map = tamil ? bookNamesTa : bookNamesEn;
  return map[code] ?? code;
}
