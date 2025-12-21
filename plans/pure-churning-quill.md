# Saved Analyses Feature - localStorage Implementation

## Overview

Add the ability to save, load, and manage previous company analyses with a dashboard interface. All data stored in browser localStorage (no backend changes).

## User Requirements

- **Storage**: localStorage (browser-only, simple)
- **Save scope**: Full analysis results + user's assumption edits + uploaded documents + metadata
- **Update behavior**: Replace on save (no version history)
- **Access pattern**: List of past analyses with search/filter, click to load and continue editing

## Implementation Plan

### Phase 1: Storage Service Layer

**File: `lib/analysisStorage.ts` (NEW)**

Create localStorage service with:
- `save(analysis)` - Save or update analysis
- `load(id)` - Retrieve specific analysis
- `list()` - Get all saved analyses with metadata
- `delete(id)` - Remove analysis
- `getStorageInfo()` - Check quota usage

**Key structure:**
```typescript
// Index of all analyses
localStorage['dealhunter:analyses:index'] = {
  analyses: [{ id, companyName, location, createdAt, updatedAt, hasDocuments }]
}

// Individual analyses
localStorage['dealhunter:analysis:{id}'] = SavedAnalysis
```

**Data model:**
```typescript
interface SavedAnalysis {
  id: string;                    // UUID
  version: number;               // Schema version
  createdAt: number;
  updatedAt: number;

  // Input
  companyName: string;
  location: string;
  documents: UploadedDocument[];

  // Results
  result: AnalysisResult;

  // User edits
  assumptions: EditableAssumptions;
  debtConfig: DebtConfiguration;
  birdInHandInputs: BirdInHandInputs;
  twoInBushInputs: TwoInBushInputs;
}
```

**Error handling:**
- Quota exceeded detection
- Size warnings (>2MB per analysis)
- Corrupted data recovery

### Phase 2: Save Integration

**File: `app/page.tsx` (UPDATE)**

Add save logic after analysis completes:
```typescript
const handleAnalyze = async () => {
  // ... existing analysis code ...

  // Save immediately after analysis
  const saved = await analysisStorage.save({
    companyName,
    location,
    documents: files,
    result: analysisResult,
    assumptions: DEFAULT_ASSUMPTIONS,
    debtConfig: DEFAULT_DEBT_CONFIG,
    birdInHandInputs: DEFAULT_BIRD_IN_HAND_INPUTS,
    twoInBushInputs: DEFAULT_TWO_IN_BUSH_INPUTS,
  });

  setCurrentAnalysisId(saved.id);
};
```

**File: `components/AnalysisReport.tsx` (UPDATE)**

Add debounced auto-save for assumption changes:
```typescript
useEffect(() => {
  const timeoutId = setTimeout(() => {
    if (currentAnalysisId) {
      analysisStorage.save({
        id: currentAnalysisId,
        assumptions,
        debtConfig,
        birdInHandInputs,
        twoInBushInputs,
      });
    }
  }, 1000); // 1 second debounce

  return () => clearTimeout(timeoutId);
}, [assumptions, debtConfig, birdInHandInputs, twoInBushInputs]);
```

### Phase 3: Dashboard UI

**File: `app/dashboard/page.tsx` (NEW)**

Create dashboard as landing page after login:
- Grid of saved analysis cards
- Search bar (fuzzy search on company name, location)
- Sort options (Most Recent, Name A-Z, Valuation)
- Empty state with "Analyze your first company" CTA

**File: `components/AnalysisCard.tsx` (NEW)**

Card showing:
- Company name & location
- Valuation range badge (e.g., "$50M - $70M")
- Creation date
- Document count icon
- Actions: Load, Delete

Card hover: Subtle shadow, scale 1.02

**File: `components/SaveButton.tsx` (NEW)**

Save indicator in AnalysisReport header:
- Unsaved: Orange "Save Analysis" button
- Saved: Green "Saved ✓" with checkmark
- Saving: Spinner

### Phase 4: Load Flow

**File: `app/page.tsx` (UPDATE)**

Add load handler:
```typescript
const handleLoadAnalysis = async (id: string) => {
  const analysis = await analysisStorage.load(id);
  if (!analysis) return;

  setCompanyName(analysis.companyName);
  setLocation(analysis.location);
  setFiles(analysis.documents);
  setResult(analysis.result);
  setCurrentAnalysisId(id);
  setStep('results');

  // AnalysisReport will load assumptions from result prop
};
```

Support URL pattern: `/?load={analysisId}`

### Phase 5: Navigation

**Header changes:**
- Add "Dashboard" link (left side)
- Add "New Analysis" button (right side)

**Confirmation prompt:**
- Show when clicking "New Analysis" with unsaved changes
- "You have unsaved changes. Save before starting new analysis?"

**Browser navigation:**
- `beforeunload` event listener if unsaved changes
- "Are you sure you want to leave?"

## File Changes Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `lib/analysisStorage.ts` | NEW | localStorage service with CRUD operations |
| `lib/types.ts` | UPDATE | Add SavedAnalysis, AnalysisMetadata interfaces |
| `app/dashboard/page.tsx` | NEW | Main dashboard with list of saved analyses |
| `components/AnalysisCard.tsx` | NEW | Card component for each saved analysis |
| `components/SaveButton.tsx` | NEW | Save indicator component |
| `app/page.tsx` | UPDATE | Add save after analysis, load handler, URL param support |
| `components/AnalysisReport.tsx` | UPDATE | Add auto-save on assumption changes |
| `package.json` | UPDATE | Add `uuid` dependency for ID generation |

## Implementation Sequence

1. **Storage layer** - Create `lib/analysisStorage.ts` with full CRUD
2. **Type definitions** - Update `lib/types.ts` with SavedAnalysis
3. **Save on analysis** - Add save in `app/page.tsx` after analysis completes
4. **Auto-save** - Add debounced auto-save in `AnalysisReport.tsx`
5. **Dashboard** - Create `app/dashboard/page.tsx` and `AnalysisCard.tsx`
6. **Load flow** - Add load handler and URL param support
7. **Save button** - Add `SaveButton.tsx` to AnalysisReport header
8. **Navigation** - Update header with Dashboard link and New Analysis button

## Size Estimation

**Typical Analysis:**
- AnalysisResult: ~20KB
- 3 uploaded documents (parsed): ~150KB
- Assumptions/config: ~2KB
- **Total: ~172KB per analysis**
- **Capacity: ~45 analyses** in 8MB localStorage

## Edge Cases

- **Quota exceeded**: Show modal with storage info + delete UI
- **Analysis too large**: Warning with option to save without documents
- **Corrupted data**: Skip and continue loading list
- **No localStorage**: Hide save UI, show warning
- **Incognito mode**: Warn that saves won't persist across sessions

## Testing Checklist

- [ ] Save analysis with documents
- [ ] Save analysis without documents
- [ ] Load saved analysis
- [ ] Edit assumptions and verify auto-save
- [ ] Fill localStorage to quota and verify error
- [ ] Delete analysis
- [ ] Browser refresh maintains persistence
- [ ] Search filters analyses correctly
- [ ] URL load parameter works
