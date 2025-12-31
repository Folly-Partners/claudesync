# Plan: Hide Analyze Button When Analysis Exists

## Summary
Conditionally hide the purple "Analyze" button in the toolbar when an AI analysis already exists, since users can use the "Regenerate" button inside the analysis section.

## File to Modify
`/Users/andrewwilkinson/Deep-Personality/components/Dashboard.tsx`

## Change
**Location:** Lines 2651-2659 (the Analyze button in the right side of toolbar)

**Current code:**
```tsx
{/* Analyze Button - always visible in minimized bar */}
<button
  onClick={() => handleAiAnalysis()}
  disabled={aiLoading}
  className="..."
>
  {aiLoading ? <Loader2 ... /> : <Zap ... />}
  {aiLoading ? 'Analyzing...' : 'Analyze'}
</button>
```

**New code:**
```tsx
{/* Analyze Button - hidden when analysis exists */}
{!aiResponse && (
  <button
    onClick={() => handleAiAnalysis()}
    disabled={aiLoading}
    className="..."
  >
    {aiLoading ? <Loader2 ... /> : <Zap ... />}
    {aiLoading ? 'Analyzing...' : 'Analyze'}
  </button>
)}
```

## Behavior
- **No analysis yet:** Purple "Analyze" button shows in toolbar
- **Analysis exists (`aiResponse` is set):** Button is hidden
- **During loading (`aiLoading`):** Button stays hidden (since it won't be shown anyway once aiResponse gets set)
- **Want to regenerate?** Use the "Regenerate" button inside the AI Personality Analysis section

## Edge Case: Loading State
One consideration: if the user clicks Analyze, `aiLoading` becomes true but `aiResponse` is still null until streaming completes. The button remains visible during loading, showing "Analyzing...". Once complete, `aiResponse` is set and button hides. This is the correct behavior.
