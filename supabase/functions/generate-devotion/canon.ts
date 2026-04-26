// Mirror of app/lib/data/plan/canon.dart and yearly_plan.dart, in TypeScript.
// Keep these two files in sync — see specs/0002-yearly-plan/spec.md FR-YP-01.

export const canonOrder: readonly string[] = [
  'GEN','EXO','LEV','NUM','DEU',
  'JOS','JDG','RUT','1SA','2SA',
  '1KI','2KI','1CH','2CH','EZR',
  'NEH','EST','JOB','PSA','PRO',
  'ECC','SNG','ISA','JER','LAM',
  'EZK','DAN','HOS','JOL','AMO',
  'OBA','JON','MIC','NAM','HAB',
  'ZEP','HAG','ZEC','MAL',
  'MAT','MRK','LUK','JHN','ACT',
  'ROM','1CO','2CO','GAL','EPH',
  'PHP','COL','1TH','2TH','1TI',
  '2TI','TIT','PHM','HEB','JAS',
  '1PE','2PE','1JN','2JN','3JN',
  'JUD','REV',
];

export const canonChapterCounts: Readonly<Record<string, number>> = {
  GEN:50,EXO:40,LEV:27,NUM:36,DEU:34,JOS:24,JDG:21,RUT:4,'1SA':31,'2SA':24,
  '1KI':22,'2KI':25,'1CH':29,'2CH':36,EZR:10,NEH:13,EST:10,JOB:42,PSA:150,PRO:31,
  ECC:12,SNG:8,ISA:66,JER:52,LAM:5,EZK:48,DAN:12,HOS:14,JOL:3,AMO:9,
  OBA:1,JON:4,MIC:7,NAM:3,HAB:3,ZEP:3,HAG:2,ZEC:14,MAL:4,
  MAT:28,MRK:16,LUK:24,JHN:21,ACT:28,ROM:16,'1CO':16,'2CO':13,GAL:6,EPH:6,
  PHP:4,COL:4,'1TH':5,'2TH':3,'1TI':6,'2TI':4,TIT:3,PHM:1,HEB:13,JAS:5,
  '1PE':5,'2PE':3,'1JN':5,'2JN':1,'3JN':1,JUD:1,REV:22,
};

export const TOTAL_CHAPTERS = 1189;
export const PLAN_LENGTH = 365;
const BIG_DAYS = TOTAL_CHAPTERS - 3 * PLAN_LENGTH; // 94

export interface ChapterRef {
  bookCode: string;
  chapter: number;
}

/** Returns the list of chapters for `dayIndex` (1..365) of the canonical plan. */
export function chaptersForDay(dayIndex: number): ChapterRef[] {
  if (dayIndex < 1 || dayIndex > PLAN_LENGTH) {
    throw new Error(`dayIndex out of range: ${dayIndex}`);
  }
  // Cumulative chapter count up to and including dayIndex.
  const upto = (i: number): number =>
    3 * i + Math.floor((i * BIG_DAYS) / PLAN_LENGTH);
  const start = upto(dayIndex - 1); // inclusive of previous days
  const end = upto(dayIndex);
  return flatChapters().slice(start, end);
}

let _flatCache: ChapterRef[] | null = null;
function flatChapters(): ChapterRef[] {
  if (_flatCache) return _flatCache;
  const out: ChapterRef[] = [];
  for (const code of canonOrder) {
    const n = canonChapterCounts[code];
    for (let c = 1; c <= n; c++) out.push({ bookCode: code, chapter: c });
  }
  if (out.length !== TOTAL_CHAPTERS) {
    throw new Error(`expected ${TOTAL_CHAPTERS} chapters, got ${out.length}`);
  }
  _flatCache = out;
  return out;
}

/** Day index for `date` within a plan started on `startDate`, or null if outside. */
export function planDayIndex(startDate: Date, date: Date): number | null {
  const start = Date.UTC(startDate.getUTCFullYear(), startDate.getUTCMonth(), startDate.getUTCDate());
  const d = Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
  const diff = Math.round((d - start) / 86_400_000);
  if (diff < 0 || diff >= PLAN_LENGTH) return null;
  return diff + 1;
}

export const bookNamesEn: Readonly<Record<string, string>> = {
  GEN:'Genesis',EXO:'Exodus',LEV:'Leviticus',NUM:'Numbers',DEU:'Deuteronomy',
  JOS:'Joshua',JDG:'Judges',RUT:'Ruth','1SA':'1 Samuel','2SA':'2 Samuel',
  '1KI':'1 Kings','2KI':'2 Kings','1CH':'1 Chronicles','2CH':'2 Chronicles',
  EZR:'Ezra',NEH:'Nehemiah',EST:'Esther',JOB:'Job',PSA:'Psalms',PRO:'Proverbs',
  ECC:'Ecclesiastes',SNG:'Song of Solomon',ISA:'Isaiah',JER:'Jeremiah',
  LAM:'Lamentations',EZK:'Ezekiel',DAN:'Daniel',HOS:'Hosea',JOL:'Joel',
  AMO:'Amos',OBA:'Obadiah',JON:'Jonah',MIC:'Micah',NAM:'Nahum',HAB:'Habakkuk',
  ZEP:'Zephaniah',HAG:'Haggai',ZEC:'Zechariah',MAL:'Malachi',
  MAT:'Matthew',MRK:'Mark',LUK:'Luke',JHN:'John',ACT:'Acts',ROM:'Romans',
  '1CO':'1 Corinthians','2CO':'2 Corinthians',GAL:'Galatians',EPH:'Ephesians',
  PHP:'Philippians',COL:'Colossians','1TH':'1 Thessalonians','2TH':'2 Thessalonians',
  '1TI':'1 Timothy','2TI':'2 Timothy',TIT:'Titus',PHM:'Philemon',HEB:'Hebrews',
  JAS:'James','1PE':'1 Peter','2PE':'2 Peter','1JN':'1 John','2JN':'2 John',
  '3JN':'3 John',JUD:'Jude',REV:'Revelation',
};
