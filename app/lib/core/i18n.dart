import '../data/bible/book.dart';

/// Tiny bilingual helper. v1 keeps app-shell strings inline as `(en, ta)`
/// pairs; we'll migrate to ARB once a third language is added (master spec
/// NFR-I18N).
///
/// Usage:
///   final t = lang.t;
///   AppBar(title: Text(t('Reader', 'வாசிப்பு')));
///
/// Tamil strings authored in this file and at call sites are best-effort and
/// flagged for native-speaker review before launch.
extension LangText on Lang {
  /// Pick the [ta] string when this language is Tamil, otherwise [en].
  String t(String en, String ta) => this == Lang.ta ? ta : en;
}

/// Shorthand date-format locale tag (`'en'` or `'ta'`) for `intl`'s
/// [DateFormat] constructor.
String dateLocaleFor(Lang lang) => lang == Lang.ta ? 'ta' : 'en';
