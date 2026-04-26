// Minimal Anthropic Messages API client with prompt caching on the system
// prompt and bounded retries. We avoid the npm SDK to keep cold-start fast on
// Supabase Edge.

const ANTHROPIC_VERSION = '2023-06-01';
const ENDPOINT = 'https://api.anthropic.com/v1/messages';

export const DEVOTION_MODEL = 'claude-haiku-4-5-20251001';

export interface AnthropicMessageInput {
  model: string;
  systemPrompt: string;       // cached
  userPrompt: string;         // not cached
  maxTokens: number;
}

export interface AnthropicResult {
  text: string;
  model: string;
  usage: {
    inputTokens: number;
    outputTokens: number;
    cacheReadInputTokens?: number;
    cacheCreationInputTokens?: number;
  };
}

export async function generateMessage(
  input: AnthropicMessageInput,
  apiKey: string,
): Promise<AnthropicResult> {
  const body = {
    model: input.model,
    max_tokens: input.maxTokens,
    system: [
      {
        type: 'text',
        text: input.systemPrompt,
        cache_control: { type: 'ephemeral' },
      },
    ],
    messages: [{ role: 'user', content: input.userPrompt }],
  };

  let lastError: unknown;
  for (let attempt = 0; attempt < 3; attempt++) {
    if (attempt > 0) {
      // Exponential backoff: 500 ms, 1500 ms.
      await new Promise((r) => setTimeout(r, 500 * Math.pow(3, attempt - 1)));
    }
    try {
      const res = await fetch(ENDPOINT, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': ANTHROPIC_VERSION,
        },
        body: JSON.stringify(body),
      });

      if (res.status === 429 || res.status >= 500) {
        lastError = new Error(`anthropic ${res.status}: ${await res.text()}`);
        continue; // retry
      }
      if (!res.ok) {
        // 4xx other than 429 — non-retriable.
        throw new Error(`anthropic ${res.status}: ${await res.text()}`);
      }

      const json = await res.json() as {
        content: Array<{ type: string; text?: string }>;
        model: string;
        usage: {
          input_tokens: number;
          output_tokens: number;
          cache_read_input_tokens?: number;
          cache_creation_input_tokens?: number;
        };
      };

      const text = json.content
        .filter((b) => b.type === 'text' && typeof b.text === 'string')
        .map((b) => b.text!)
        .join('')
        .trim();

      if (!text) throw new Error('anthropic returned empty content');

      return {
        text,
        model: json.model,
        usage: {
          inputTokens: json.usage.input_tokens,
          outputTokens: json.usage.output_tokens,
          cacheReadInputTokens: json.usage.cache_read_input_tokens,
          cacheCreationInputTokens: json.usage.cache_creation_input_tokens,
        },
      };
    } catch (e) {
      lastError = e;
    }
  }
  throw new Error(`anthropic failed after retries: ${lastError}`);
}
