# Deep Personality: Eager Analysis + Model Routing

## Goal
Reduce AI analysis wait time from 5-10 minutes by:
1. Starting analysis immediately when test completes (before user clicks "Analyze")
2. Routing simple chunks to faster Haiku model

---

## Feature 1: Server-side Eager Analysis Trigger

### Changes to `/app/api/complete/route.ts`

After profile saves successfully (~line 421), add fire-and-forget call:

```typescript
import { after } from 'next/server';

// After: if (savedProfileId) { ... }
if (savedProfileId) {
  logServerEvent(`Profile saved: ${savedProfileId}`);

  // Fire-and-forget eager analysis
  after(async () => {
    try {
      const baseUrl = process.env.VERCEL_URL
        ? `https://${process.env.VERCEL_URL}`
        : 'http://localhost:3000';

      await fetch(`${baseUrl}/api/analyze-parallel`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': API_SECRET_KEY!,
        },
        body: JSON.stringify({
          profileA: { ...profile, id: savedProfileId, darkTriad },
          profileB: null,
          mode: 'individual',
          relationshipType: 'everything',
          eagerTrigger: true,
        }),
      });
      logServerEvent(`[EAGER] Analysis started for ${savedProfileId}`);
    } catch (e: any) {
      logServerEvent(`[EAGER] Trigger failed: ${e.message}`, 'WARN');
    }
  });
}
```

### How it works
- `after()` runs callback after response is sent (Next.js 15 feature)
- Uses existing `API_SECRET_KEY` for server-to-server auth
- Dashboard will get cached result or in-flight deduplication
- Falls back gracefully if trigger fails

---

## Feature 2: Model Routing for Speed

### Changes to `/app/api/analyze-parallel/route.ts`

**Add model constants (~line 34):**
```typescript
const SONNET_MODEL_ID = "claude-sonnet-4-5-20250929";
const HAIKU_MODEL_ID = "claude-haiku-4-5-20251001";

const CHUNK_MODEL_ROUTING: Record<string, 'sonnet' | 'haiku'> = {
  // Simple chunks -> Haiku (5-10x faster)
  'overview': 'haiku',
  'resources': 'haiku',
  'conclusion': 'haiku',
  // Complex chunks -> Sonnet (keep quality)
  'personality': 'sonnet',
  'emotional': 'sonnet',
  'values': 'sonnet',
  'ideal-life': 'sonnet',
  'wellbeing-base': 'sonnet',
};

function getChunkModel(chunkId: string): string {
  if (chunkId.startsWith('clinical-')) return SONNET_MODEL_ID;
  return CHUNK_MODEL_ROUTING[chunkId] === 'haiku' ? HAIKU_MODEL_ID : SONNET_MODEL_ID;
}

// Reduced thinking budgets for Haiku chunks
const HAIKU_THINKING_BUDGETS: Record<string, number> = {
  'overview': 5000,
  'resources': 5000,
  'conclusion': 8000,
};
```

**Modify `callAnthropicChunkCached` (~line 1522):**
- Add `modelId` parameter to function signature
- Use `model: modelId` in fetch body instead of hardcoded `MODEL_ID`
- Update logging to show which model was used

**Update chunk processing (~line 2070):**
- Call `getChunkModel(chunk.id)` and pass to `callAnthropicChunkCached`

### Expected savings
- 3 chunks moved to Haiku: overview, resources, conclusion
- ~20-35 seconds saved per analysis
- Total: ~10-15% faster overall

---

## Files to Modify

| File | Changes |
|------|---------|
| `app/api/complete/route.ts` | Add `after()` eager trigger after save |
| `app/api/analyze-parallel/route.ts` | Add model routing config + pass model to API calls |

---

## Testing Plan

1. **Local testing**: Verify eager trigger fires, check logs
2. **Quality check**: Compare Haiku output for overview/resources/conclusion vs Sonnet
3. **E2E test**: Complete full assessment, verify:
   - ALL chunks load properly (no missing sections)
   - No errors in the report generation
   - Dashboard loads faster with eager trigger
4. **Monitor**: Check Anthropic dashboard for cost/latency changes

---

## Rollback

- **Feature 1**: Remove `after()` block - Dashboard still works on-demand
- **Feature 2**: Change routing to return 'sonnet' for all chunks
- Both changes are isolated to 1-2 files
