# Deep Personality Comparison UX Fixes

## Issues to Fix
1. AI report not loading from cache when selecting previously connected profile
2. Unwanted green/teal border around profile card in comparison mode
3. Confusing "Compare Profiles" modal with duplicate entries
4. Confusing "vs Zoe" header indicator

---

## Fix 1: AI Report Cache Not Loading

**Root Cause:** A `useEffect` at line ~1860 resets `aiResponse` when profiles change, running AFTER `applyComparison` sets the cached analysis.

**File:** `components/Dashboard.tsx`

**Changes:**
1. Add state flag `skipAnalysisReset` (~line 392)
2. In `applyComparison` (~line 976), set flag before loading cached analysis:
   ```typescript
   if (comparison.analysis && comparison.analysis.length > 100) {
     setSkipAnalysisReset(true);  // Prevent effect from clearing
     setAiResponse(comparison.analysis);
     setIsSavedAnalysis(true);
   }
   ```
3. Modify the profile change effect (~line 1860) to check the flag:
   ```typescript
   useEffect(() => {
     if (skipAnalysisReset) {
       setSkipAnalysisReset(false);
       return;
     }
     // ... rest of effect
   }, [profileA, profileB, skipAnalysisReset]);
   ```

---

## Fix 2: Remove Green Border

**File:** `components/Dashboard.tsx` lines 2778-2782

**Change:** Remove the teal border/ring styling when in comparison mode:

```jsx
// Before:
profileB ? 'border-teal-300 dark:border-teal-700 ring-1 ring-teal-200 dark:ring-teal-800' : ...

// After:
'border-slate-200 dark:border-slate-700'  // Same styling regardless of comparison mode
```

---

## Fix 3: Redesign Compare Profiles Modal

**File:** `components/Dashboard.tsx` lines 4220-4436

### Current Structure (Confusing)
- "Linked Comparisons" - badges showing each connected person
- "Your Invite Codes" - shows same people again if linked + pending codes
- "Have a code?" - input field

### New Structure (Clean)
1. **"Your Connections"** - Deduplicated list of connected people
2. **"Connect with Someone"** - Generate code OR enter code sections

**Changes:**
1. Add `unifiedConnections` useMemo to deduplicate people who appear in both directions:
   ```typescript
   const unifiedConnections = useMemo(() => {
     const connectionMap = new Map();
     comparisons.forEach(c => {
       const key = c.otherName.toLowerCase();
       if (!connectionMap.has(key)) {
         connectionMap.set(key, {
           id: c.id, name: c.otherName, comparisonId: c.id,
           hasAnalysis: !!c.analysis
         });
       }
     });
     return Array.from(connectionMap.values());
   }, [comparisons]);
   ```

2. Add `pendingInvites` filter for unused codes:
   ```typescript
   const pendingInvites = useMemo(() =>
     activeInvites.filter(i => i.status === 'active'),
     [activeInvites]
   );
   ```

3. Rewrite modal JSX with two clean sections:
   - **Your Connections:** Card list with avatar, name, "View"/"Compare" button, hover-reveal delete
   - **Connect with Someone:**
     - Pink section for generating invite codes (with compact pending list)
     - Gray section for entering received codes

---

## Fix 4: Redesign Header Comparison Indicator

**File:** `components/Dashboard.tsx` lines 2840-2854

### Current (Confusing)
- "vs" label (hidden on mobile)
- Teal/green avatar
- Name
- Small X button

### New Design (Clear)
Replace with overlapping avatar stack and clearer text:

```jsx
<div className="flex items-center gap-2 pl-2 sm:pl-3">
  {/* Divider */}
  <div className="h-6 w-px bg-slate-200 dark:bg-slate-600" />

  {/* Avatar stack: [A] + [B] */}
  <div className="flex items-center -space-x-2">
    <div className="w-7 h-7 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-lg ...">
      {profileA.name[0]}
    </div>
    <div className="w-5 h-5 bg-white rounded-full flex items-center justify-center z-20">
      <span className="text-xs font-bold text-slate-400">+</span>
    </div>
    <div className="w-7 h-7 bg-gradient-to-br from-pink-500 to-rose-500 rounded-lg ...">
      {profileB.name[0]}
    </div>
  </div>

  {/* Text: "with Zoe" (desktop only) */}
  <span className="text-sm font-medium text-slate-600 hidden sm:block">
    with <span className="text-slate-900">{profileB.name.split(' ')[0]}</span>
  </span>

  {/* Prominent exit button */}
  <button onClick={exitComparisonMode}
    className="p-1.5 text-slate-400 hover:text-white hover:bg-rose-500 rounded-lg">
    <X className="w-4 h-4"/>
  </button>
</div>
```

**Key changes:**
- Changed profileB avatar from teal/green to pink/rose (matches invite theme)
- "with Name" instead of "vs Name" - more friendly
- Prominent exit button with rose hover state
- Avatar stack shows relationship visually

---

## Files to Modify

| File | Changes |
|------|---------|
| `components/Dashboard.tsx` | All 4 fixes - cache flag, border removal, modal redesign, header redesign |

---

## Implementation Order

1. Fix 1 (Cache) - Quick state management fix
2. Fix 2 (Border) - One-line CSS change
3. Fix 4 (Header) - Update comparison indicator design
4. Fix 3 (Modal) - Largest change, add useMemos + rewrite JSX
