# Enhance AI Reports with Extended Thinking

## Overview

Extended thinking allows Claude to reason step-by-step before responding, significantly improving quality for complex analytical tasks like psychological profiling. It's available on all current Claude models.

## Current Implementation

**File:** `/Users/andrewwilkinson/Deep-Personality/app/api/analyze-parallel/route.ts`

```typescript
// Current API call (line 1324-1337)
const resp = await fetch("https://api.anthropic.com/v1/messages", {
  method: "POST",
  headers: {
    "x-api-key": ANTHROPIC_API_KEY!,
    "anthropic-version": "2023-06-01",
    "content-type": "application/json"
  },
  body: JSON.stringify({
    model: MODEL_ID,
    max_tokens: CHUNK_MAX_TOKENS,  // 7000
    system: SYSTEM_PROMPT,
    messages: [{ role: "user", content: prompt }]
  })
});
```

## Extended Thinking API

Simply add a `thinking` parameter to enable:

```typescript
body: JSON.stringify({
  model: "claude-sonnet-4-5-20250929",
  max_tokens: 16000,
  thinking: {
    type: "enabled",
    budget_tokens: 10000  // Min: 1024, recommended: 10k-32k for complex tasks
  },
  system: SYSTEM_PROMPT,
  messages: [{ role: "user", content: prompt }]
})
```

**Response includes thinking blocks:**
```json
{
  "content": [
    {
      "type": "thinking",
      "thinking": "Let me analyze this personality profile step by step...",
      "signature": "..."
    },
    {
      "type": "text",
      "text": "## Your Personality Analysis..."
    }
  ]
}
```

## Benefits for Deep Personality

1. **Better psychological analysis** - Claude can reason through complex trait interactions
2. **More nuanced insights** - Step-by-step thinking catches subtleties in data
3. **Improved clinical sections** - Better reasoning for mental health recommendations
4. **Higher quality comparisons** - More thoughtful relationship compatibility analysis

## Chosen Approach: Selective Thinking Budgets

Different budgets per chunk type (hidden from users):

| Chunk | Content | Thinking Budget | max_tokens |
|-------|---------|-----------------|------------|
| 1 | Executive Summary/TOC | 5,000 | 12,000 |
| 2 | Big Five Analysis | 10,000 | 17,000 |
| 3 | Emotional/Attachment | 15,000 | 22,000 |
| 4 | Values/Motivation/Career | 10,000 | 17,000 |
| 5 | Ideals/Superpowers/Growth | 10,000 | 17,000 |
| 6 | Wellbeing/Clinical | 20,000 | 27,000 |

Note: `max_tokens` must be > `budget_tokens` to leave room for actual output.

## Files to Modify

1. **`/app/api/analyze-parallel/route.ts`**
   - Add `thinking` parameter to `generateChunk()` function
   - Parse response to extract text from thinking blocks
   - Update chunk token budgets

2. **`/app/api/analyze/route.ts`** (if still used)
   - Same changes for non-parallel route

3. **Optional: `/app/api/complete/route.ts`**
   - Admin clinical analysis could benefit from Opus 4.5 + thinking

## Implementation Steps

1. Add thinking configuration constants at top of file
2. Modify `generateChunk()` to accept thinking budget parameter
3. Update response parsing to handle thinking blocks
4. Extract only `text` blocks for the final report
5. Update `max_tokens` to accommodate thinking + output
6. Test with sample profiles
7. Monitor latency and quality improvements

## Response Handling (Thinking Hidden from Users)

Since thinking is hidden, simply extract only `text` blocks from response:

```typescript
// Non-streaming (current parallel approach)
const result = await resp.json();
const textContent = result.content
  .filter((block: any) => block.type === "text")
  .map((block: any) => block.text)
  .join("");

// For streaming, ignore thinking_delta events:
if (event.delta.type === "text_delta") {
  // This is the actual report content - send to client
}
// Skip thinking_delta events entirely
```

## Cost/Latency Tradeoffs

| Scenario | Thinking Budget | Est. Latency | Est. Cost Increase |
|----------|-----------------|--------------|-------------------|
| Light | 5,000/chunk | +30-50% | +20-30% |
| Moderate | 10,000/chunk | +50-100% | +40-60% |
| Heavy | 20,000/chunk | +100-200% | +80-120% |

Recommendation: Start with 10,000 budget, measure quality improvement, adjust.

## Sources
- [Building with extended thinking - Claude Docs](https://docs.claude.com/en/docs/build-with-claude/extended-thinking)
- [Claude's extended thinking announcement](https://www.anthropic.com/news/visible-extended-thinking)
