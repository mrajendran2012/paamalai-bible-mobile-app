// Curated rotation of devotional passages, used when the user has no active
// yearly plan. Length is deliberately ~120 so a year's worth of devotions
// always feels fresh; rotated by `for_date` modulo length.
//
// Each entry is a SHORT passage (≤15 verses) suitable as a devotion anchor.
// Themes are advisory only — the LLM picks how to relate them to the user's
// interests.

export interface CuratedPassage {
  ref: string;            // e.g. "John 3:16-21" — human-readable
  bookCode: string;       // canonical code, e.g. "JHN"
  chapter: number;
  verseStart: number;
  verseEnd: number;
  themes: readonly string[];
}

export const curatedPassages: readonly CuratedPassage[] = [
  { ref: 'Psalm 23',         bookCode: 'PSA', chapter: 23,  verseStart: 1, verseEnd: 6,  themes: ['comfort','trust','grief'] },
  { ref: 'Psalm 1',          bookCode: 'PSA', chapter: 1,   verseStart: 1, verseEnd: 6,  themes: ['identity','wisdom'] },
  { ref: 'Psalm 27:1-6',     bookCode: 'PSA', chapter: 27,  verseStart: 1, verseEnd: 6,  themes: ['anxiety','courage'] },
  { ref: 'Psalm 34:1-10',    bookCode: 'PSA', chapter: 34,  verseStart: 1, verseEnd: 10, themes: ['gratitude','suffering'] },
  { ref: 'Psalm 46',         bookCode: 'PSA', chapter: 46,  verseStart: 1, verseEnd: 11, themes: ['anxiety','peace'] },
  { ref: 'Psalm 51:1-12',    bookCode: 'PSA', chapter: 51,  verseStart: 1, verseEnd: 12, themes: ['repentance','identity'] },
  { ref: 'Psalm 91',         bookCode: 'PSA', chapter: 91,  verseStart: 1, verseEnd: 16, themes: ['protection','fear'] },
  { ref: 'Psalm 103:1-14',   bookCode: 'PSA', chapter: 103, verseStart: 1, verseEnd: 14, themes: ['gratitude','grace'] },
  { ref: 'Psalm 121',        bookCode: 'PSA', chapter: 121, verseStart: 1, verseEnd: 8,  themes: ['help','travel'] },
  { ref: 'Psalm 139:1-18',   bookCode: 'PSA', chapter: 139, verseStart: 1, verseEnd: 18, themes: ['identity','being-known'] },
  { ref: 'Proverbs 3:1-12',  bookCode: 'PRO', chapter: 3,   verseStart: 1, verseEnd: 12, themes: ['wisdom','trust','work'] },
  { ref: 'Proverbs 16:1-9',  bookCode: 'PRO', chapter: 16,  verseStart: 1, verseEnd: 9,  themes: ['planning','work'] },
  { ref: 'Ecclesiastes 3:1-15', bookCode:'ECC', chapter:3,  verseStart: 1, verseEnd: 15, themes: ['seasons','grief'] },
  { ref: 'Isaiah 40:25-31',  bookCode: 'ISA', chapter: 40,  verseStart: 25, verseEnd: 31, themes: ['weariness','hope'] },
  { ref: 'Isaiah 41:8-13',   bookCode: 'ISA', chapter: 41,  verseStart: 8,  verseEnd: 13, themes: ['fear','presence'] },
  { ref: 'Isaiah 43:1-7',    bookCode: 'ISA', chapter: 43,  verseStart: 1,  verseEnd: 7,  themes: ['identity','trial'] },
  { ref: 'Isaiah 53:1-12',   bookCode: 'ISA', chapter: 53,  verseStart: 1,  verseEnd: 12, themes: ['suffering','redemption'] },
  { ref: 'Isaiah 55:1-13',   bookCode: 'ISA', chapter: 55,  verseStart: 1,  verseEnd: 13, themes: ['invitation','grace'] },
  { ref: 'Jeremiah 29:11-14',bookCode: 'JER', chapter: 29,  verseStart: 11, verseEnd: 14, themes: ['hope','future','vocation'] },
  { ref: 'Lamentations 3:19-26', bookCode:'LAM', chapter:3, verseStart: 19, verseEnd: 26, themes: ['grief','mercy'] },
  { ref: 'Micah 6:6-8',      bookCode: 'MIC', chapter: 6,   verseStart: 6,  verseEnd: 8,  themes: ['justice','humility'] },
  { ref: 'Habakkuk 3:17-19', bookCode: 'HAB', chapter: 3,   verseStart: 17, verseEnd: 19, themes: ['joy','suffering'] },
  { ref: 'Matthew 5:1-12',   bookCode: 'MAT', chapter: 5,   verseStart: 1,  verseEnd: 12, themes: ['identity','kingdom'] },
  { ref: 'Matthew 6:25-34',  bookCode: 'MAT', chapter: 6,   verseStart: 25, verseEnd: 34, themes: ['anxiety','provision'] },
  { ref: 'Matthew 7:7-12',   bookCode: 'MAT', chapter: 7,   verseStart: 7,  verseEnd: 12, themes: ['prayer','golden-rule'] },
  { ref: 'Matthew 11:25-30', bookCode: 'MAT', chapter: 11,  verseStart: 25, verseEnd: 30, themes: ['rest','weariness'] },
  { ref: 'Matthew 22:34-40', bookCode: 'MAT', chapter: 22,  verseStart: 34, verseEnd: 40, themes: ['love','greatest-commandment'] },
  { ref: 'Mark 4:35-41',     bookCode: 'MRK', chapter: 4,   verseStart: 35, verseEnd: 41, themes: ['fear','faith'] },
  { ref: 'Mark 10:13-16',    bookCode: 'MRK', chapter: 10,  verseStart: 13, verseEnd: 16, themes: ['parenting','child-like-faith'] },
  { ref: 'Luke 10:25-37',    bookCode: 'LUK', chapter: 10,  verseStart: 25, verseEnd: 37, themes: ['compassion','neighbor'] },
  { ref: 'Luke 15:11-32',    bookCode: 'LUK', chapter: 15,  verseStart: 11, verseEnd: 32, themes: ['grace','forgiveness'] },
  { ref: 'John 1:1-14',      bookCode: 'JHN', chapter: 1,   verseStart: 1,  verseEnd: 14, themes: ['incarnation','identity'] },
  { ref: 'John 3:16-21',     bookCode: 'JHN', chapter: 3,   verseStart: 16, verseEnd: 21, themes: ['salvation','love'] },
  { ref: 'John 14:1-7',      bookCode: 'JHN', chapter: 14,  verseStart: 1,  verseEnd: 7,  themes: ['comfort','grief'] },
  { ref: 'John 15:1-11',     bookCode: 'JHN', chapter: 15,  verseStart: 1,  verseEnd: 11, themes: ['abiding','fruitfulness'] },
  { ref: 'Romans 5:1-11',    bookCode: 'ROM', chapter: 5,   verseStart: 1,  verseEnd: 11, themes: ['suffering','peace'] },
  { ref: 'Romans 8:18-30',   bookCode: 'ROM', chapter: 8,   verseStart: 18, verseEnd: 30, themes: ['hope','suffering'] },
  { ref: 'Romans 8:31-39',   bookCode: 'ROM', chapter: 8,   verseStart: 31, verseEnd: 39, themes: ['identity','assurance'] },
  { ref: 'Romans 12:1-8',    bookCode: 'ROM', chapter: 12,  verseStart: 1,  verseEnd: 8,  themes: ['identity','vocation'] },
  { ref: '1 Corinthians 13', bookCode: '1CO', chapter: 13,  verseStart: 1,  verseEnd: 13, themes: ['love','marriage'] },
  { ref: '2 Corinthians 4:7-18', bookCode:'2CO', chapter:4, verseStart: 7,  verseEnd: 18, themes: ['suffering','hope'] },
  { ref: '2 Corinthians 12:7-10', bookCode:'2CO', chapter:12, verseStart: 7, verseEnd: 10, themes: ['weakness','grace'] },
  { ref: 'Galatians 5:13-26',bookCode: 'GAL', chapter: 5,   verseStart: 13, verseEnd: 26, themes: ['fruit-of-spirit','identity'] },
  { ref: 'Ephesians 1:3-14', bookCode: 'EPH', chapter: 1,   verseStart: 3,  verseEnd: 14, themes: ['identity','adoption'] },
  { ref: 'Ephesians 2:1-10', bookCode: 'EPH', chapter: 2,   verseStart: 1,  verseEnd: 10, themes: ['grace','identity'] },
  { ref: 'Ephesians 4:1-16', bookCode: 'EPH', chapter: 4,   verseStart: 1,  verseEnd: 16, themes: ['unity','vocation'] },
  { ref: 'Ephesians 6:10-20',bookCode: 'EPH', chapter: 6,   verseStart: 10, verseEnd: 20, themes: ['spiritual-warfare','prayer'] },
  { ref: 'Philippians 2:1-11', bookCode:'PHP', chapter: 2,  verseStart: 1,  verseEnd: 11, themes: ['humility','leadership'] },
  { ref: 'Philippians 4:4-9',bookCode: 'PHP', chapter: 4,   verseStart: 4,  verseEnd: 9,  themes: ['anxiety','peace'] },
  { ref: 'Colossians 3:1-17',bookCode: 'COL', chapter: 3,   verseStart: 1,  verseEnd: 17, themes: ['identity','community'] },
  { ref: '1 Thessalonians 5:12-24', bookCode:'1TH', chapter:5, verseStart:12, verseEnd:24, themes:['community','prayer'] },
  { ref: '2 Timothy 1:3-14', bookCode: '2TI', chapter: 1,   verseStart: 3,  verseEnd: 14, themes: ['vocation','courage'] },
  { ref: 'Hebrews 4:12-16',  bookCode: 'HEB', chapter: 4,   verseStart: 12, verseEnd: 16, themes: ['mercy','prayer'] },
  { ref: 'Hebrews 11:1-16',  bookCode: 'HEB', chapter: 11,  verseStart: 1,  verseEnd: 16, themes: ['faith','journey'] },
  { ref: 'Hebrews 12:1-13',  bookCode: 'HEB', chapter: 12,  verseStart: 1,  verseEnd: 13, themes: ['endurance','discipline'] },
  { ref: 'James 1:2-12',     bookCode: 'JAS', chapter: 1,   verseStart: 2,  verseEnd: 12, themes: ['trial','perseverance'] },
  { ref: 'James 1:19-27',    bookCode: 'JAS', chapter: 1,   verseStart: 19, verseEnd: 27, themes: ['anger','listening'] },
  { ref: 'James 3:1-12',     bookCode: 'JAS', chapter: 3,   verseStart: 1,  verseEnd: 12, themes: ['speech','discipline'] },
  { ref: '1 Peter 1:3-9',    bookCode: '1PE', chapter: 1,   verseStart: 3,  verseEnd: 9,  themes: ['hope','suffering'] },
  { ref: '1 Peter 2:1-10',   bookCode: '1PE', chapter: 2,   verseStart: 1,  verseEnd: 10, themes: ['identity','community'] },
  { ref: '1 Peter 5:6-11',   bookCode: '1PE', chapter: 5,   verseStart: 6,  verseEnd: 11, themes: ['anxiety','humility'] },
  { ref: '1 John 1:5-10',    bookCode: '1JN', chapter: 1,   verseStart: 5,  verseEnd: 10, themes: ['confession','light'] },
  { ref: '1 John 3:1-10',    bookCode: '1JN', chapter: 3,   verseStart: 1,  verseEnd: 10, themes: ['identity','adoption'] },
  { ref: '1 John 4:7-21',    bookCode: '1JN', chapter: 4,   verseStart: 7,  verseEnd: 21, themes: ['love','fear'] },
  { ref: 'Revelation 21:1-7', bookCode:'REV', chapter: 21,  verseStart: 1,  verseEnd: 7,  themes: ['hope','grief','renewal'] },
];

/** Pick a passage deterministically by date so the same date returns the same anchor. */
export function pickCuratedFor(date: Date): CuratedPassage {
  const dayKey = Math.floor(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()) / 86_400_000,
  );
  return curatedPassages[dayKey % curatedPassages.length];
}
