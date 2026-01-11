# Analysis: Partial Assessment Data Compatibility

## Summary

After the soft reset we performed, most users are now in a clean state (0 answers, step 0). However, there are a few users with potential compatibility issues that need attention.

## Users with Potential Issues

### 1. Mike Shaw (mike@mikeshawski.com)
**Status:** NEEDS ATTENTION
- **62 answers** stored with OLD question ID format
- Uses `A1_`, `C1_`, `E1_`, `N1_`, `O1_`, `DT_*` prefixes (old IPIP-50 format)
- Current code expects `IPIP_*` prefix format
- **Impact:** His answers won't be recognized by the current scoring system
- **Recommendation:** Reset his profile - his data is incompatible

### 2. Andrew Plohy (andrew.plokhii@gmail.com)
**Status:** Minor issue
- Only 1 answer stored (N1_* format)
- Marked as `partial` but essentially hasn't started
- **Recommendation:** Could reset, but only 1 answer lost

### 3. Elise Brieanne (elise.brieanne@gmail.com)
**Status:** Minor issue
- Only 1 answer stored
- No basic info filled in
- **Recommendation:** Could reset, minimal data lost

### 4. Ellen Last (ellen.casper@gmail.com)
**Status:** Data inconsistency
- Has assessment scores populated but marked as `started`
- 0 answers in partial_responses
- **Issue:** May see completed results when they should be starting fresh
- **Recommendation:** Clear the `assessments` field to force fresh start

### 5. René Gauthier (renejeangauthier@gmail.com)
**Status:** Data inconsistency
- Has assessment scores populated but marked as `started`
- 0 answers in partial_responses
- **Issue:** Same as Ellen - completed data but incomplete status
- **Recommendation:** Clear the `assessments` field to force fresh start

### 6. Test User (test@example.com) & Andrew Wilkinson (awilkinson@gmail.com)
**Status:** Minor technical debt
- `total_steps = 27` (old value from before OCI sections were added)
- 0 answers, so functionally fine
- **Impact:** None - total_steps is recalculated dynamically
- **Recommendation:** No action needed

## Root Cause Analysis

The **major refactoring changes** that could cause issues:

1. **Question ID format change** (Most critical)
   - Old format: `A1_`, `C1_`, `E1_`, `N1_`, `O1_` for Big Five
   - New format: `IPIP_1` through `IPIP_50`
   - Impact: Old answers won't map to new question IDs

2. **Server-first progress architecture** (Jan 5, 2026)
   - Old data in localStorage is now ignored
   - Some users may have had progress only in localStorage

3. **OCI-6/OCI-R sections added** (Jan 4, 2026)
   - Changed section ordering and total steps
   - Users mid-assessment may be at wrong step index

4. **Batch progress saving** (Jan 5, 2026)
   - Changed from per-answer to per-section saves
   - Could cause partial data if user abandoned mid-section

## Recommended Actions

### Option A: Conservative Cleanup (Recommended)
1. Reset Mike Shaw's profile (incompatible data format)
2. Clear `assessments` field for Ellen Last and René Gauthier
3. Leave others as-is (they're already reset to clean state)

### Option B: Complete Reset
1. Reset all 34 profiles to clean state (clear assessments field too)
2. Everyone starts fresh with no compatibility concerns

### Option C: No Further Action
1. Trust that the soft reset already handled most issues
2. Mike Shaw will simply re-answer questions (wizard will show them as unanswered)
3. Ellen/René may see old results but can retake

## Verification

After any cleanup:
1. Run `npx tsx scripts/review-accounts.ts` to verify final state
2. Test login for a sample user to confirm wizard loads correctly
3. Verify no users have `assessments` data without `status = 'complete'`
