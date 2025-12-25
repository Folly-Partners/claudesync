# Fix: Restore Individual Analysis When Exiting Comparison View

## Problem

When viewing individual analysis → comparing with partner → clicking X to exit comparison, the individual AI analysis is not restored from storage. User must regenerate it.

## Root Cause

In `Dashboard.tsx`, the X buttons only call `setProfileB(null)` without restoring the saved individual analysis:
- **Line 2283**: `onClick={() => setProfileB(null)}` (minimized header)
- **Line 2686**: `onClick={() => setProfileB(null)}` (expanded section)

The individual analysis exists in `profileA.ai_analysis` but isn't loaded when exiting comparison.

## File to Modify

`/Users/andrewwilkinson/Deep-Personality/components/Dashboard.tsx`

## Fix

Create a helper function and update both X button handlers:

```tsx
// Helper function to exit comparison and restore individual analysis
const exitComparisonMode = () => {
  setProfileB(null);
  if (profileA?.ai_analysis) {
    setAiResponse(profileA.ai_analysis);
    setIsSavedAnalysis(true);
    setSavedAnalysisPartnerId(null);
  }
};
```

Update X buttons:
- **Line 2283**: `onClick={exitComparisonMode}`
- **Line 2686**: `onClick={exitComparisonMode}`

## Implementation Steps

1. Add `exitComparisonMode` helper function near other handlers
2. Update X button at line 2283 to use `exitComparisonMode`
3. Update X button at line 2686 to use `exitComparisonMode`
4. Test: view analysis → compare → click X → verify individual analysis loads
