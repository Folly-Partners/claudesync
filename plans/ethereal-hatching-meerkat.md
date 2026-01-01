# Bug Fix: Saved report not restored when exiting comparison mode (v2)

## Problem

When clicking the X to exit comparison mode, the app shows "Generate My Analysis" instead of the saved individual report.

## Previous Fix (Incomplete)

The first fix set `skipAnalysisReset = true` before clearing `profileB`, but it relied on looking up the analysis from `pastAssessments` or localStorage. These lookups can fail (ID mismatch, empty data), causing `analysisToRestore` to be null, which means `skipAnalysisReset` is never set.

## Root Cause

`applyComparison` overwrites `aiResponse` with the comparison analysis (or null) WITHOUT first saving the individual analysis anywhere. When exiting, there's no reliable way to restore it.

## Solution

Add a ref to store the individual analysis BEFORE entering comparison mode, then restore from it when exiting. This is more reliable than lookups.

## File to Modify

`/Users/andrewwilkinson/Deep-Personality/components/Dashboard.tsx`

## Implementation

### Step 1: Add a ref to store individual analysis

Near the other refs (around line 1960):

```tsx
// Ref to store individual analysis when entering comparison mode
const savedIndividualAnalysisRef = useRef<{
  analysis: string | null;
  isSaved: boolean;
  profileId: string | null;
} | null>(null);
```

### Step 2: Save individual analysis in `applyComparison` (around line 1060)

At the START of `applyComparison`, BEFORE any state changes:

```tsx
const applyComparison = (comparison: {...}, role: 'sender' | 'recipient') => {
  // FIRST: Save current individual analysis if we're not already in comparison mode
  if (!profileB && aiResponse) {
    savedIndividualAnalysisRef.current = {
      analysis: aiResponse,
      isSaved: isSavedAnalysis,
      profileId: profileA?.id || null
    };
  }

  // ... rest of existing code
};
```

### Step 3: Restore from ref in `exitComparisonMode` (around line 2591)

Replace the current lookup logic with ref restoration:

```tsx
const exitComparisonMode = () => {
  // Get saved individual analysis from ref
  const savedIndividual = savedIndividualAnalysisRef.current;
  const analysisToRestore = savedIndividual?.analysis && savedIndividual.analysis.length > 100
    ? savedIndividual.analysis
    : null;
  const isCachedSaved = savedIndividual?.isSaved ?? false;

  // Set skip flag BEFORE clearing profileB if we have analysis to restore
  if (analysisToRestore) {
    setSkipAnalysisReset(true);
  }

  // Clear comparison state
  setProfileB(null);
  setActiveComparisonId(null);
  setActiveComparisonRole(null);
  setRelationshipType('everything');
  setAiError(null);
  setShouldAutoAnalyze(false);

  // Restore the analysis
  if (analysisToRestore) {
    setAiResponse(analysisToRestore);
    setIsSavedAnalysis(isCachedSaved);
  } else {
    // Fallback to pastAssessments/localStorage if ref is empty
    const savedProfile = pastAssessments.find(p => p.id === profileA?.id);
    if (savedProfile?.ai_analysis && savedProfile.ai_analysis.length > 100) {
      setSkipAnalysisReset(true);
      setAiResponse(savedProfile.ai_analysis);
      setIsSavedAnalysis(true);
    } else {
      const cachedProfile = readIndividualCache();
      const cachedAnalysis = cachedProfile?.profileA?.id === profileA?.id
        ? cachedProfile?.aiResponse
        : null;
      if (cachedAnalysis && cachedAnalysis.length > 100) {
        setSkipAnalysisReset(true);
        setAiResponse(cachedAnalysis);
        setIsSavedAnalysis(!!cachedProfile?.isSavedAnalysis);
      } else {
        setAiResponse(null);
        setIsSavedAnalysis(false);
      }
    }
  }

  // Clear the ref after restoration
  savedIndividualAnalysisRef.current = null;
};
```

## Why This Works

1. **Direct storage**: The exact `aiResponse` value is stored in a ref before any state changes
2. **No lookups needed**: Doesn't rely on `pastAssessments` ID matching or localStorage cache
3. **Fallback preserved**: Still falls back to `pastAssessments`/localStorage if ref is empty
4. **Clean lifecycle**: Ref is cleared after restoration

## Testing

1. Generate an individual analysis and ensure it displays
2. Enter comparison mode (click Compare, select a connection)
3. Exit comparison mode (click X)
4. Verify: Individual analysis should display, not "Generate My Analysis"
5. Also test: Enter comparison mode WITHOUT an individual analysis, exit - should show Generate button
