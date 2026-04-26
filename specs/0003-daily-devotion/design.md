# 0003 — Daily Devotion — Design

## Edge function (`supabase/functions/generate-devotion/`)

```
generate-devotion/
├── index.ts                 # HTTP entry, auth, routing, response shaping
├── anthropic.ts             # Claude client, prompt-caching wrapper
├── passages.ts              # curated fallback rotation
├── prompts.ts               # system prompt (cache target) + per-user user prompt builder
└── deno.json                # imports map
```

### Auth

Decode the Supabase JWT from the `Authorization: Bearer <jwt>` header using the project's JWT secret. Extract `sub` (= `user_id`). Reject if missing/expired.

### Cache check

```sql
select passage_ref, body_md, model
from devotions_cache
where user_id = $1 and for_date = $2 and language = $3;
```

If `force_regenerate=false` and a row exists → return immediately, set `cached: true`.

### Rate limit (FR-DD-03)

```sql
select count(*)
from devotions_cache
where user_id = $1 and for_date = $2;
-- count >= 4 ? return 429.
```

(Each successful regeneration upserts the row, but we additionally insert into a tiny `devotion_regenerations(user_id, for_date, at)` audit table — needed because upsert overwrites the cached row, so we can't count regenerations from `devotions_cache` alone. Add this table to migration 0001.)

### Prompt structure (cost optimization)

**System prompt** (cached): the devotion-writing rubric, the Markdown structure contract, theological tone guidance, language-specific instructions for English and Tamil. **Same across all users** → high cache hit rate.

**User prompt** (not cached, varies per call):
```
Today's date: {for_date}
Language: {language}     // 'en' | 'ta'
Anchor passage: {passage_ref}
Anchor passage text: {3-15 verses, plain text in target language}
Reader's interests: {comma-separated tags}
```

The anchor passage text is fetched from the bundled Bible data — **but the edge function runs on Deno**, not Flutter. Solution: ship a minimal `passages_text.ts` with just the verses for the curated fallback list, plus a Postgres-side function that returns the text for any `(book, chapter, verse_start, verse_end)` from a `bible_verses` table loaded once at deploy time. **Decision: keep verses in Postgres** so the function can resolve any plan-day passage. Add `bible_verses(translation, book_code, chapter, verse, text)` to migration 0001 and a one-shot loader script that uploads the same SQLite content into Postgres.

### Anthropic call

```ts
const res = await anthropic.messages.create({
  model: "claude-haiku-4-5-20251001",
  max_tokens: 700,
  system: [
    { type: "text", text: SYSTEM_PROMPT, cache_control: { type: "ephemeral" } }
  ],
  messages: [{ role: "user", content: userPrompt }],
});
```

`anthropic.ts` wraps retries (max 2, exponential backoff) on 5xx and 429-from-Anthropic; surfaces 503 to the client on final failure.

### Persistence

```sql
insert into devotions_cache (user_id, for_date, language, passage_ref, body_md, model)
values ($1,$2,$3,$4,$5,$6)
on conflict (user_id, for_date, language) do update
  set passage_ref = excluded.passage_ref,
      body_md = excluded.body_md,
      model = excluded.model,
      created_at = now();

insert into devotion_regenerations (user_id, for_date) values ($1, $2);
```

## App (`app/lib/data/devotion/`)

```dart
class DevotionRepository {
  Future<Devotion> getToday({required Lang language});
  Future<Devotion> reroll({required Lang language});
  Future<List<Devotion>> recentHistory({int days = 7});  // local cache only
}
```

- Calls `supabase.functions.invoke('generate-devotion', body: {...})`.
- Mirrors successful responses into local Drift `devotions_local` for FR-DD-04 offline read.
- Recognizes 409 → routes user to interest picker; 429 → toast; 503 → retry CTA.

## UI (`features/devotion/`)

```
devotion_screen.dart       # Today's devotion (Markdown), TTS controls, re-roll button, AI footer
devotion_history.dart      # Last 7 days, read-only
```

Renders Markdown via `flutter_markdown` with custom paragraph styling matching the reader's font-size pref.
