# Bundled Bible SQLite files

`web.sqlite` and `ta_uv.sqlite` are produced by `tools/build_bible_db.dart`
from public-domain USFM source archives. They are **not** committed to git
(too large + reproducible).

To produce them on a fresh checkout:

```bash
cd tools
dart pub get
dart run build_bible_db.dart --fetch
```

After running, this directory should contain:

- `web.sqlite`     (~3 MB) — World English Bible, public domain
- `ta_uv.sqlite`   (~6 MB) — Tamil Union Version 1957, public domain

Schema is documented in `specs/0001-bible-reader/spec.md` §"Data contracts".

If `flutter run` fails with "asset not found" for these files, re-run the
importer.
