# Tamil font fallback

`pubspec.yaml` declares a `NotoSansTamil` font family that points to two files
in this directory:

- `NotoSansTamil-Regular.ttf`
- `NotoSansTamil-Bold.ttf`

These are intentionally **not** committed (they're Google Noto fonts, OFL
licensed but ~1 MB each). Fetch once before your first `flutter run`:

```bash
# from repo root
mkdir -p app/assets/fonts
curl -L -o app/assets/fonts/NotoSansTamil-Regular.ttf \
  https://github.com/notofonts/tamil/raw/main/fonts/NotoSansTamil/hinted/ttf/NotoSansTamil-Regular.ttf
curl -L -o app/assets/fonts/NotoSansTamil-Bold.ttf \
  https://github.com/notofonts/tamil/raw/main/fonts/NotoSansTamil/hinted/ttf/NotoSansTamil-Bold.ttf
```

The reader uses these as a `fontFamilyFallback` so Tamil verses always render
even on devices missing a system Tamil font (see
`specs/0001-bible-reader/design.md` §"Tamil fonts").
