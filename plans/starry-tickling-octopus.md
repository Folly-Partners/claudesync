# Fix: Ensure All Report Sections Complete (No Partial Results)

## Problem
After implementing streaming + overall timeout, reports can still show:
`[Section "Wellbeing & Recommendations" could not be generated: Overall timeout - section not completed in time]`

The user wants ALL sections to complete - partial results are unacceptable.

## Root Cause
1. **No retry after overall timeout**: When 280s overall timeout hits, failed chunks are NOT retried
2. **Wellbeing-inversions is complex**: Up to 240s timeout, 20k thinking tokens, handles all clinical deep-dives
3. **Parallel execution can exhaust time**: If multiple chunks are slow, overall limit hits before all complete

## Solution: Sequential Retry Phase

Add a **retry phase** after parallel execution to ensure failed chunks get completed.

---

## Implementation Plan

### Phase 1: Add Sequential Retry for Failed Chunks
**File:** `/Users/andrewwilkinson/Deep-Personality/app/api/analyze-parallel/route.ts`

After the parallel phase completes (or times out), retry any failed chunks sequentially:

```typescript
// After Promise.race completes...
const failedChunks = results
  .map((r, i) => ({ result: r, index: i, chunk: chunkPromises[i] }))
  .filter(item => item.result?.error || !item.result?.text);

if (failedChunks.length > 0) {
  const remainingTime = VERCEL_HARD_LIMIT - (Date.now() - startTime);

  if (remainingTime > 30000) { // At least 30s remaining
    await writer.write(encoder.encode(`STATUS:Retrying ${failedChunks.length} section(s)...\n`));

    for (const failed of failedChunks) {
      const chunkRemainingTime = VERCEL_HARD_LIMIT - (Date.now() - startTime) - 5000;
      if (chunkRemainingTime < 20000) break; // Need at least 20s per chunk

      const retryResult = await callAnthropicChunk(
        failed.chunk.prompt,
        failed.chunk.id,
        failed.chunk.name,
        triggeredCount,
        0 // Fresh retry count
      );

      if (retryResult.text && !retryResult.error) {
        results[failed.index] = retryResult;
        await writer.write(encoder.encode(`STATUS:✓ ${failed.chunk.name} recovered\n`));
      }
    }
  }
}
```

### Phase 2: Prioritize Slowest Chunks First
Start the most complex chunks first so they have maximum parallel time:

```typescript
// Sort chunks so slowest start first
const sortedChunks = [...chunks].sort((a, b) => {
  const priorities: Record<string, number> = {
    'wellbeing-inversions': 0,  // Start first (slowest)
    'emotional': 1,
    'deep-insights': 2,
    'personality': 3,
    'values': 4,
    'ideal-life': 5,
    'overview': 6,
    'conclusion': 7,  // Start last (fastest, needs other sections)
  };
  return (priorities[a.id] ?? 5) - (priorities[b.id] ?? 5);
});
```

### Phase 3: Increase Token Budget for Complex Sections
Give max tokens to wellbeing-inversions since it handles clinical deep-dives:

```typescript
const THINKING_BUDGETS: Record<string, number> = {
  'overview': 3000,
  'personality': 6000,
  'emotional': 8000,
  'values': 6000,
  'ideal-life': 6000,
  'wellbeing-inversions': 16000,  // INCREASED from 12000
  'conclusion': 6000,
};

// For retries, use even higher budget
const RETRY_THINKING_BUDGETS: Record<string, number> = {
  'wellbeing-inversions': 24000,  // Max budget on retry
  // ... others same as normal
};
```

### Phase 4: Split Wellbeing Into Two Chunks
Split the complex wellbeing section into smaller, faster chunks:

**Before:** 1 chunk doing everything
- Wellbeing analysis (SWLS, PERMA, UCLA-3)
- Mental health snapshot
- Treatment options
- ALL clinical deep-dives (can be 5+ conditions)
- Resources & recommendations

**After:** 2 chunks running in parallel
1. `wellbeing-base`: Core wellbeing + mental health + treatment options
2. `clinical-deepdives`: All triggered condition deep-dives + resources

```typescript
// New chunk definitions
{
  id: 'wellbeing-base',
  name: 'Wellbeing & Mental Health',
  // Handles: SWLS, PERMA, UCLA-3, mental health snapshot, treatment table
},
{
  id: 'clinical-deepdives',
  name: 'Clinical Deep-Dives',
  // Handles: Each triggered condition's detailed section + resources
}
```

Benefits:
- Each chunk is ~50% smaller
- Both run in parallel (more efficient)
- If one fails, only retry that one
- clinical-deepdives only runs if triggeredCount > 0

---

## Key Changes

### Constants to Add
```typescript
const VERCEL_HARD_LIMIT = 295000; // 295s - absolute max before Vercel kills
const PARALLEL_TIMEOUT = 240000;  // 240s for parallel phase (was 280)
const RETRY_MIN_TIME = 20000;     // Need 20s minimum to retry a chunk
```

### Token Budgets (Updated)
```typescript
const THINKING_BUDGETS: Record<string, number> = {
  'wellbeing-base': 10000,        // Simpler without clinical deep-dives
  'clinical-deepdives': 16000,    // Complex but focused
  // ... other chunks unchanged
};
```

### Timeline Budget
- 0-240s: Parallel execution of all chunks
- 240-290s: Sequential retry of any failed chunks
- 290-295s: Final assembly and response
- 295-300s: Buffer for Vercel

---

## Files to Modify
1. `/Users/andrewwilkinson/Deep-Personality/app/api/analyze-parallel/route.ts`

## Expected Outcome
- Wellbeing split into 2 smaller, faster chunks (8 total instead of 7)
- Higher token budgets ensure complex reasoning completes
- Failed chunks get retried sequentially with remaining time
- Slowest chunks start first, maximizing their parallel window
- Only show partial results if truly impossible to complete (edge case)

## Implementation Order
1. Split wellbeing-inversions into wellbeing-base + clinical-deepdives chunks
2. Update token budgets (16k for clinical-deepdives, 10k for wellbeing-base)
3. Add retry phase after parallel execution
4. Add chunk priority sorting (slowest first)
5. Test with complex profile (demo@deeppersonality.app)
