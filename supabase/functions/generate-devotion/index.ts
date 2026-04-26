// Deno edge function: generate (or return cached) daily devotion.
//
// Spec: specs/0003-daily-devotion/spec.md  (FR-DD-01..05)
// Design: specs/0003-daily-devotion/design.md
//
// Behavior summary (deterministic order):
//   1. Verify Supabase JWT, extract user_id.
//   2. If !force_regenerate and a cached row exists for (user_id, for_date, language),
//      return it immediately. (FR-DD-02)
//   3. Read interests; empty -> 409 NO_INTERESTS. (FR-DD-01)
//   4. If force_regenerate, check the daily regeneration audit count -> 429 if >=3.
//   5. Resolve today's anchor passage:
//        - if user has an active 'yearly_canonical' plan and today is in range,
//          use the FIRST chapter of that plan-day,
//        - otherwise, pick from the curated rotation by date.
//   6. Load passage_text from public.bible_verses for the requested translation.
//   7. Call Anthropic (Haiku, prompt caching on the system prompt).
//   8. Upsert devotions_cache; if force_regenerate, also insert a row into
//      devotion_regenerations for rate-limit accounting.
//   9. Return the devotion JSON.
//
// Errors are returned as { "error": "<CODE>" } with the HTTP code from the spec.

import { createClient, SupabaseClient } from '@supabase/supabase-js';

import { chaptersForDay, planDayIndex, bookNamesEn } from './canon.ts';
import { pickCuratedFor, type CuratedPassage } from './passages.ts';
import { SYSTEM_PROMPT, buildUserPrompt } from './prompts.ts';
import { DEVOTION_MODEL, generateMessage } from './anthropic.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY')!;

const REROLL_DAILY_CAP = 3;

interface RequestBody {
  for_date: string;            // YYYY-MM-DD
  language: 'en' | 'ta';
  force_regenerate?: boolean;
}

interface AnchorPassage {
  ref: string;                 // e.g. "John 3:16-21"
  bookCode: string;
  chapter: number;
  verseStart: number;          // inclusive
  verseEnd: number;            // inclusive
}

const json = (status: number, body: unknown): Response =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json(405, { error: 'method_not_allowed' });

  const auth = req.headers.get('authorization');
  if (!auth?.startsWith('Bearer ')) return json(401, { error: 'unauthorized' });
  const jwt = auth.slice('Bearer '.length);

  // Use a per-request client bound to the caller's JWT for any RLS-dependent reads.
  const userClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false },
  });
  const userRes = await userClient.auth.getUser(jwt);
  if (userRes.error || !userRes.data.user) {
    return json(401, { error: 'unauthorized' });
  }
  const userId = userRes.data.user.id;

  // Privileged client for inserts that bypass RLS (devotion_regenerations).
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  let body: RequestBody;
  try {
    body = await req.json() as RequestBody;
  } catch {
    return json(400, { error: 'invalid_json' });
  }
  if (!body?.for_date || !body?.language) {
    return json(400, { error: 'missing_fields' });
  }
  if (body.language !== 'en' && body.language !== 'ta') {
    return json(400, { error: 'invalid_language' });
  }
  const forDate = parseDateOrNull(body.for_date);
  if (!forDate) return json(400, { error: 'invalid_for_date' });

  const force = body.force_regenerate === true;

  // 2. Cache check.
  if (!force) {
    const cached = await fetchCachedDevotion(admin, userId, body.for_date, body.language);
    if (cached) {
      return json(200, {
        for_date: body.for_date,
        language: body.language,
        passage_ref: cached.passage_ref,
        body_md: cached.body_md,
        model: cached.model,
        cached: true,
      });
    }
  }

  // 3. Interests.
  const interests = await fetchInterests(admin, userId);
  if (interests.length === 0) return json(409, { error: 'NO_INTERESTS' });

  // 4. Rate limit (only when re-rolling).
  if (force) {
    const used = await countRegenerationsToday(admin, userId, body.for_date);
    if (used >= REROLL_DAILY_CAP) return json(429, { error: 'RATE_LIMITED' });
  }

  // 5. Anchor passage.
  const anchor = await resolveAnchor(admin, userId, forDate);

  // 6. Load passage text.
  const translation = body.language === 'en' ? 'WEB' : 'TAUV';
  const passageText = await loadPassageText(admin, translation, anchor);
  if (!passageText) {
    return json(503, { error: 'UPSTREAM', detail: 'passage_text_missing' });
  }

  // 7. Anthropic call.
  let result;
  try {
    result = await generateMessage({
      model: DEVOTION_MODEL,
      systemPrompt: SYSTEM_PROMPT,
      userPrompt: buildUserPrompt({
        language: body.language,
        forDate: body.for_date,
        passageRef: anchor.ref,
        passageText,
        interests,
      }),
      maxTokens: 700,
    }, ANTHROPIC_API_KEY);
  } catch (e) {
    console.error('anthropic_failed', e);
    return json(503, { error: 'UPSTREAM' });
  }

  // 8. Persist.
  const upsertErr = (await admin.from('devotions_cache').upsert({
    user_id: userId,
    for_date: body.for_date,
    language: body.language,
    passage_ref: anchor.ref,
    body_md: result.text,
    model: result.model,
    created_at: new Date().toISOString(),
  })).error;
  if (upsertErr) {
    console.error('cache_upsert_failed', upsertErr);
    return json(500, { error: 'persist_failed' });
  }
  if (force) {
    await admin.from('devotion_regenerations').insert({
      user_id: userId,
      for_date: body.for_date,
    });
  }

  // 9. Respond.
  return json(200, {
    for_date: body.for_date,
    language: body.language,
    passage_ref: anchor.ref,
    body_md: result.text,
    model: result.model,
    cached: false,
  });
});

// ---------- helpers ----------

function parseDateOrNull(s: string): Date | null {
  // Accept strict YYYY-MM-DD only.
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) return null;
  const d = new Date(`${s}T00:00:00Z`);
  return isNaN(d.getTime()) ? null : d;
}

async function fetchCachedDevotion(
  admin: SupabaseClient,
  userId: string,
  forDate: string,
  language: string,
) {
  const { data, error } = await admin
    .from('devotions_cache')
    .select('passage_ref, body_md, model')
    .eq('user_id', userId)
    .eq('for_date', forDate)
    .eq('language', language)
    .maybeSingle();
  if (error) {
    console.error('cache_lookup_failed', error);
    return null;
  }
  return data;
}

async function fetchInterests(admin: SupabaseClient, userId: string): Promise<string[]> {
  const { data, error } = await admin
    .from('interests')
    .select('tag')
    .eq('user_id', userId);
  if (error) {
    console.error('interests_lookup_failed', error);
    return [];
  }
  return (data ?? []).map((r) => r.tag as string);
}

async function countRegenerationsToday(
  admin: SupabaseClient,
  userId: string,
  forDate: string,
): Promise<number> {
  const { count, error } = await admin
    .from('devotion_regenerations')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .eq('for_date', forDate);
  if (error) {
    console.error('regen_count_failed', error);
    return 0;
  }
  return count ?? 0;
}

async function resolveAnchor(
  admin: SupabaseClient,
  userId: string,
  forDate: Date,
): Promise<AnchorPassage> {
  // Look for an active yearly plan; if today is within day 1..365, use today's first chapter.
  const { data: plans } = await admin
    .from('reading_plans')
    .select('started_on')
    .eq('user_id', userId)
    .eq('kind', 'yearly_canonical')
    .order('created_at', { ascending: false })
    .limit(1);

  if (plans && plans.length > 0) {
    const start = new Date(`${plans[0].started_on}T00:00:00Z`);
    const idx = planDayIndex(start, forDate);
    if (idx) {
      const first = chaptersForDay(idx)[0];
      return await fullChapterAnchor(admin, first.bookCode, first.chapter);
    }
  }

  // Fallback: curated rotation.
  const c: CuratedPassage = pickCuratedFor(forDate);
  return {
    ref: c.ref,
    bookCode: c.bookCode,
    chapter: c.chapter,
    verseStart: c.verseStart,
    verseEnd: c.verseEnd,
  };
}

async function fullChapterAnchor(
  admin: SupabaseClient,
  bookCode: string,
  chapter: number,
): Promise<AnchorPassage> {
  // Use the WEB translation just for the verse-count bound (translations have
  // identical numbering by §0001 design.md).
  const { data, error } = await admin
    .from('bible_verses')
    .select('verse')
    .eq('translation', 'WEB')
    .eq('book_code', bookCode)
    .eq('chapter', chapter)
    .order('verse', { ascending: false })
    .limit(1);
  const last = (!error && data && data.length > 0) ? (data[0].verse as number) : 1;
  // Cap to 15 verses for prompt size; pick verses 1..min(last,15).
  const end = Math.min(last, 15);
  const name = bookNamesEn[bookCode] ?? bookCode;
  return {
    ref: end < last ? `${name} ${chapter}:1-${end}` : `${name} ${chapter}`,
    bookCode,
    chapter,
    verseStart: 1,
    verseEnd: end,
  };
}

async function loadPassageText(
  admin: SupabaseClient,
  translation: 'WEB' | 'TAUV',
  a: AnchorPassage,
): Promise<string | null> {
  const { data, error } = await admin
    .from('bible_verses')
    .select('verse, text')
    .eq('translation', translation)
    .eq('book_code', a.bookCode)
    .eq('chapter', a.chapter)
    .gte('verse', a.verseStart)
    .lte('verse', a.verseEnd)
    .order('verse', { ascending: true });
  if (error) {
    console.error('passage_text_failed', error);
    return null;
  }
  if (!data || data.length === 0) return null;
  return data.map((r) => `${r.verse} ${r.text}`).join(' ');
}
