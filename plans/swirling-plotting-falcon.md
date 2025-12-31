# Plan: Remove Relationship Type Selector in Comparison Mode

## Goal
Always analyze for "everything" in comparison mode - remove the dropdown selector entirely.

## File to Modify
`/Users/andrewwilkinson/Deep-Personality/components/Dashboard.tsx`

## Changes

### 1. Simplify the UI (lines 3227-3272)
Remove the dropdown and label, keep just the Analyze button with the "Saved" indicator.

**Before:**
```tsx
<div className="bg-slate-50 border border-slate-200 rounded-xl p-4">
  <label>Analyze this relationship for:</label>
  <div className="flex gap-2">
    <select>...</select>
    <button>Analyze</button>
  </div>
  <p>Select context and click Analyze...</p>
</div>
```

**After:**
```tsx
<div className="flex items-center justify-between">
  <button onClick={() => handleAiAnalysis()}>
    ⚡ Analyze Compatibility
  </button>
  {/* Keep the Saved indicator */}
</div>
```

### 2. Force 'everything' in API call
In `handleAiAnalysis()` (line ~2421), always send `relationshipType: 'everything'` for comparison mode.
