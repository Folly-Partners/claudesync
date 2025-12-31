# Fix AI Report Section Timeouts

## Problem Statement

AI personality reports are experiencing timeout failures on production:
- `Section "values" could not be generated: Chunk timed out after 90s`
- `Section "ideal-life" could not be generated: Chunk timed out after 90s`
- `Section "ADHD Deep-Dive" could not be generated: Retry failed: Chunk timed out after 0s`

The "0s" timeout is the critical bug - retries are failing immediately.

## Root Cause Analysis

### Bug 1: Retry Timeout Calculation Produces 0 or Negative Values

**Location:** `app/api/analyze-parallel/route.ts` line 1731

```typescript
const remainingTimeout = maxAllowedTimeout ? maxAllowedTimeout - elapsed : undefined;
```

**Problem:** If a chunk times out at its full 90s allocation:
- `elapsed` ≈ 90000ms
- `maxAllowedTimeout` = 90000ms
- `remainingTimeout` = 90000 - 90000 = **0ms**

Then line 1594: `hardTimeout = Math.min(adaptiveTimeout, 0) = 0`

Result: Retry immediately times out with "Chunk timed out after 0s"

### Bug 2: Sequential Retry Has Same Issue

**Location:** Line 2152

```typescript
const chunkRemainingTime = VERCEL_HARD_LIMIT - (Date.now() - startTime) - 5000;
```

If parallel phase consumes most of the 240s budget, remaining time can be very low.

### Bug 3: Activity Timeout Too Aggressive During Extended Thinking

**Location:** Lines 1600-1606

- `ACTIVITY_TIMEOUT = 75000` (75 seconds)
- Extended thinking can take 30-50s with **zero stream output**
- If API connection delays + thinking = 75s, chunk aborts prematurely

### Bug 4: No Minimum Timeout Guarantee

When `maxAllowedTimeout` is passed, there's no floor:
```typescript
const hardTimeout = maxAllowedTimeout ? Math.min(adaptiveTimeout, maxAllowedTimeout) : adaptiveTimeout;
```

If `maxAllowedTimeout` is 5000ms (5s), that's not enough for any meaningful Claude response.

## Fix Plan

### File: `app/api/analyze-parallel/route.ts`

#### Fix 1: Add Minimum Timeout Constants

```typescript
// Add after line 1543
const MIN_CHUNK_TIMEOUT = 30000;   // 30s minimum for any chunk
const MIN_RETRY_TIMEOUT = 45000;  // 45s minimum for retries (need thinking time)
```

#### Fix 2: Fix Inline Retry Timeout Calculation (Line 1731)

**Before:**
```typescript
const remainingTimeout = maxAllowedTimeout ? maxAllowedTimeout - elapsed : undefined;
```

**After:**
```typescript
// Ensure retry has meaningful time - at least MIN_RETRY_TIMEOUT
const calculatedRemaining = maxAllowedTimeout ? maxAllowedTimeout - elapsed : undefined;
const remainingTimeout = calculatedRemaining !== undefined
  ? Math.max(calculatedRemaining, MIN_RETRY_TIMEOUT)
  : undefined;
```

#### Fix 3: Fix hardTimeout Calculation (Line 1594)

**Before:**
```typescript
const hardTimeout = maxAllowedTimeout ? Math.min(adaptiveTimeout, maxAllowedTimeout) : adaptiveTimeout;
```

**After:**
```typescript
// Ensure minimum timeout regardless of constraints
const hardTimeout = maxAllowedTimeout
  ? Math.max(Math.min(adaptiveTimeout, maxAllowedTimeout), MIN_CHUNK_TIMEOUT)
  : adaptiveTimeout;
```

#### Fix 4: Increase Activity Timeout for Extended Thinking

**Before (line 1538):**
```typescript
const ACTIVITY_TIMEOUT = 75000; // 75s
```

**After:**
```typescript
const ACTIVITY_TIMEOUT = 90000; // 90s - must exceed max thinking time (50s) + API latency
```

#### Fix 5: Fix Sequential Retry Minimum Time Check (Lines 2151-2156)

**Before:**
```typescript
const chunkRemainingTime = VERCEL_HARD_LIMIT - (Date.now() - startTime) - 5000;
if (chunkRemainingTime < RETRY_MIN_TIME) {
```

**After:**
```typescript
const rawRemainingTime = VERCEL_HARD_LIMIT - (Date.now() - startTime) - 5000;
// Ensure retry gets meaningful time
const chunkRemainingTime = Math.max(rawRemainingTime, MIN_RETRY_TIMEOUT);
// But skip if we're truly out of time
if (rawRemainingTime < RETRY_MIN_TIME) {
```

#### Fix 6: Add Logging for Timeout Debugging

Add detailed logging when timeouts are calculated:

```typescript
// In callAnthropicChunkCached, after line 1594
if (maxAllowedTimeout && hardTimeout < adaptiveTimeout) {
  logServerEvent(`⚠️ Chunk "${chunkName}" timeout constrained: ${adaptiveTimeout}ms → ${hardTimeout}ms (remaining: ${maxAllowedTimeout}ms)`, 'DEBUG');
}
```

#### Fix 7: Skip Retry If No Meaningful Time (Line 1726-1732)

**Before:**
```typescript
if (retryCount < MAX_RETRIES) {
  // ... retry logic
}
```

**After:**
```typescript
if (retryCount < MAX_RETRIES) {
  const calculatedRemaining = maxAllowedTimeout ? maxAllowedTimeout - elapsed : undefined;
  // Skip retry if we don't have meaningful time left
  if (calculatedRemaining !== undefined && calculatedRemaining < MIN_RETRY_TIMEOUT) {
    logServerEvent(`⏱️ Chunk "${chunkName}" - skipping retry, only ${Math.round(calculatedRemaining/1000)}s remaining (need ${MIN_RETRY_TIMEOUT/1000}s)`, 'WARN');
  } else {
    // ... existing retry logic with fixed timeout
  }
}
```

## Summary of Changes

| Change | Location | Purpose |
|--------|----------|---------|
| Add MIN_CHUNK_TIMEOUT (30s) | Line ~1544 | Floor for any chunk timeout |
| Add MIN_RETRY_TIMEOUT (45s) | Line ~1545 | Floor for retry attempts |
| Fix inline retry calculation | Line 1731 | Prevent 0s retry timeout |
| Fix hardTimeout floor | Line 1594 | Ensure minimum timeout |
| Increase ACTIVITY_TIMEOUT | Line 1538 | Allow extended thinking |
| Fix sequential retry | Lines 2151-2156 | Prevent too-short retries |
| Add skip logic | Lines 1726-1732 | Don't retry if no time |

## Expected Results

- No more "Chunk timed out after 0s" errors
- Retries will either have meaningful time (45s+) or be skipped gracefully
- Extended thinking won't trigger premature activity timeout
- Failed sections will show clear error messages, not cryptic "0s" timeouts

## Testing

1. Generate report for a profile with clinical flags (triggers ADHD Deep-Dive)
2. Monitor logs for timeout calculations
3. Verify no "0s" timeout messages
4. Verify sections complete or fail gracefully
