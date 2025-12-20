# UI Polish Fixes for Model Assumptions & Document Upload

## Issues Identified

1. **"Modified" badge showing incorrectly** - Remove it from Model Assumptions header
2. **Input fields too narrow** - Numbers like "20.0" and "4.3" are getting cut off
3. **Yellow highlight looks awkward** - The `var(--accent-light)` background is too prominent
4. **Document Upload Prompt not showing** - Props not being passed from app/page.tsx to AnalysisReport

---

## File 1: `components/AssumptionsEditor.tsx`

### Change 1: Remove "Modified" badge
- Lines 90-94: Remove the `{hasModifications && (...)}` block that shows the "Modified" span
- Also remove the `hasModifications` variable (lines 63-67) since it's no longer used

### Change 2: Widen input fields to prevent text cutoff
- Line 234: Change `w-14` to `w-20` for the number input fields
- Line 136: Ensure the base financials inputs have enough width (currently using `flex-1`, should be fine)

### Change 3: Make yellow highlight more subtle
- For the "Base Year Financials" section (line 113): Change from yellow background to a subtle left border indicator
- For modified rows (lines 205-210): Use a subtle left border instead of full row background

**Before:**
```tsx
<div className="px-6 py-5" style={{ backgroundColor: 'var(--accent-light)', ... }}>
```

**After:**
```tsx
<div className="px-6 py-5" style={{ borderLeft: '3px solid var(--accent)', backgroundColor: 'var(--background-alt)', ... }}>
```

**Before (modified rows):**
```tsx
style={{
  backgroundColor: modified ? 'var(--accent-light)' : 'transparent',
}}
```

**After:**
```tsx
style={{
  borderLeft: modified ? '3px solid var(--accent)' : '3px solid transparent',
  paddingLeft: '8px',
}}
```

---

## File 2: `app/page.tsx`

### Change: Pass document upload props to AnalysisReport

**Before (line 520):**
```tsx
<AnalysisReport result={result} onReset={handleReset} />
```

**After:**
```tsx
<AnalysisReport
  result={result}
  onReset={handleReset}
  uploadedDocuments={files}
  onDocumentsUpload={(docs) => setFiles(docs)}
  onReanalyze={handleReanalyze}
  isAnalyzing={analyzing}
/>
```

### Add `handleReanalyze` function (after `handleReset`):
```typescript
const handleReanalyze = async () => {
  // Re-run analysis with current files
  setStep('analyzing');
  setAnalyzing(true);
  // ... same logic as handleAnalyze but skipping the file upload step
  await handleAnalyze();
};
```

Actually simpler - just call `handleAnalyze()` directly since it uses the current `files` state.

---

## Summary of Changes

| File | Change |
|------|--------|
| `components/AssumptionsEditor.tsx` | Remove "Modified" badge, widen inputs (w-14 → w-20), use left border instead of yellow background |
| `app/page.tsx` | Pass uploadedDocuments, onDocumentsUpload, onReanalyze, isAnalyzing props to AnalysisReport |

---

## Implementation Notes

- The "Reset All" button should still appear when assumptions are modified (keep that logic)
- The left border indicator is more subtle than a full background highlight
- Input width of `w-20` (80px) should comfortably fit numbers like "21.3"
