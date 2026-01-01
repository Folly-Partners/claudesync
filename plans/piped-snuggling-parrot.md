# Plan: Fix Loading State Gap for Saved Reports

## Problem
The spinner shows, then disappears for 2-3 seconds showing the "Generate" CTA, then the saved report loads. This happens because:

1. `loadingInitialProfiles` = `false` in the `finally` block (line 896) after profile LIST fetch
2. But the profile DETAIL fetch (which populates `aiResponse`) is still running
3. Gap: `loadingInitialProfiles` is false, `aiResponse` is still null → CTA shows

## Root Cause (Dashboard.tsx)
```
Line 858-862: Fetch profile list
Line 868-889: Fetch profile detail (INNER try/catch)
  Line 879: setAiResponse(aiAnalysis) ← THIS is when saved analysis loads
Line 896: finally { setLoadingInitialProfiles(false) } ← TOO EARLY
```

The `finally` block executes when the outer try completes, but the inner profile detail fetch may still be running.

## Solution
Move `setLoadingInitialProfiles(false)` to AFTER `aiResponse` is set, not in the `finally` block.

## File to Modify

### `components/Dashboard.tsx`

#### 1. Remove premature `setLoadingInitialProfiles(false)` from finally blocks

**Line ~896** - Remove from first finally block:
```tsx
// Remove: setLoadingInitialProfiles(false);
```

**Line ~955** - Remove from auth handler finally block:
```tsx
// Remove: setLoadingInitialProfiles(false);
```

#### 2. Set `loadingInitialProfiles = false` at the right times:

**After setting aiResponse from saved analysis (line ~879-880):**
```tsx
setAiResponse(profile.aiAnalysis);
setIsSavedAnalysis(true);
setLoadingInitialProfiles(false);  // ADD HERE - after aiResponse is set
```

**When there's NO saved analysis (line ~882-884):**
```tsx
setShouldAutoAnalyze(true);
setLoadingInitialProfiles(false);  // ADD HERE - no saved analysis to wait for
```

**When no profiles found (line ~864-866):**
```tsx
// No profiles - stop loading
setLoadingInitialProfiles(false);  // ADD HERE
```

**When user not authenticated (line ~900):**
```tsx
setLoadingInitialProfiles(false);  // KEEP - no user means nothing to load
```

**When user logs out (line ~964):**
```tsx
setLoadingInitialProfiles(false);  // KEEP - clearing state
```

## Logic
Instead of: "Stop loading spinner when fetch completes"
Do: "Stop loading spinner when either:
  - Saved analysis is loaded into `aiResponse`, OR
  - We determine there's no saved analysis (trigger auto-analyze), OR
  - No profiles exist, OR
  - User not authenticated"

## Result
Spinner stays visible until `aiResponse` is populated → no gap → no CTA flash
