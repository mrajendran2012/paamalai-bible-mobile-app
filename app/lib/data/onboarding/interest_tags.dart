import '../bible/book.dart';

/// Canonical interest tag for the daily devotion personalization.
///
/// [code] is a stable English snake_case identifier and is what gets persisted
/// (and later sent to Supabase). Display labels are looked up by [labelFor].
class InterestTag {
  const InterestTag({
    required this.code,
    required this.labelEn,
    required this.labelTa,
  });

  final String code;
  final String labelEn;
  final String labelTa;

  String labelFor(Lang lang) => lang == Lang.ta ? labelTa : labelEn;
}

/// Starter interest set for FR-ON-03. ≥20 entries required by the spec.
///
/// Order is the order shown in the picker — keep semantically related tags
/// adjacent so the grid scans naturally.
///
/// TODO: Tamil labels are seeded best-effort by the project owner and need a
/// native-speaker review pass before launch (specs/0005-onboarding/spec.md
/// §Risks #1).
const List<InterestTag> starterInterestTags = [
  InterestTag(code: 'anxiety',     labelEn: 'Anxiety',      labelTa: 'கவலை'),
  InterestTag(code: 'hope',        labelEn: 'Hope',         labelTa: 'நம்பிக்கை'),
  InterestTag(code: 'gratitude',   labelEn: 'Gratitude',    labelTa: 'நன்றியுணர்வு'),
  InterestTag(code: 'doubt',       labelEn: 'Doubt',        labelTa: 'சந்தேகம்'),
  InterestTag(code: 'suffering',   labelEn: 'Suffering',    labelTa: 'துன்பம்'),
  InterestTag(code: 'grief',       labelEn: 'Grief',        labelTa: 'துக்கம்'),
  InterestTag(code: 'forgiveness', labelEn: 'Forgiveness',  labelTa: 'மன்னிப்பு'),
  InterestTag(code: 'anger',       labelEn: 'Anger',        labelTa: 'கோபம்'),
  InterestTag(code: 'loneliness',  labelEn: 'Loneliness',   labelTa: 'தனிமை'),
  InterestTag(code: 'identity',    labelEn: 'Identity',     labelTa: 'அடையாளம்'),
  InterestTag(code: 'purpose',     labelEn: 'Purpose',      labelTa: 'நோக்கம்'),
  InterestTag(code: 'marriage',    labelEn: 'Marriage',     labelTa: 'திருமணம்'),
  InterestTag(code: 'parenting',   labelEn: 'Parenting',    labelTa: 'பெற்றோர்மை'),
  InterestTag(code: 'friendship',  labelEn: 'Friendship',   labelTa: 'நட்பு'),
  InterestTag(code: 'work',        labelEn: 'Work',         labelTa: 'வேலை'),
  InterestTag(code: 'leadership',  labelEn: 'Leadership',   labelTa: 'தலைமை'),
  InterestTag(code: 'finances',    labelEn: 'Finances',     labelTa: 'நிதி'),
  InterestTag(code: 'sickness',    labelEn: 'Sickness',     labelTa: 'நோய்'),
  InterestTag(code: 'addiction',   labelEn: 'Addiction',    labelTa: 'அடிமைத்தனம்'),
  InterestTag(code: 'justice',     labelEn: 'Justice',      labelTa: 'நீதி'),
  InterestTag(code: 'prayer',      labelEn: 'Prayer',       labelTa: 'ஜெபம்'),
  InterestTag(code: 'fasting',     labelEn: 'Fasting',      labelTa: 'உபவாசம்'),
];

/// Lookup helper — returns null if [code] is unknown (e.g. removed from the
/// starter set after a user already saved it).
InterestTag? interestTagByCode(String code) {
  for (final t in starterInterestTags) {
    if (t.code == code) return t;
  }
  return null;
}
