# Plan: Comparison Revocation & Analysis Auto-Display

## Requirements

1. **Unilateral Revocation**: Either party (sender OR recipient) can revoke a comparison, which hides it from BOTH users
2. **Auto-Display Analysis**: When loading a comparison that already has an analysis saved, display it immediately (no button click)

---

## Implementation

### Part 1: Unilateral Revocation (Hide for Both)

#### 1.1 Backend: `app/api/comparisons/revoke/route.ts`

Current behavior (line 32-41):
- Only sender can revoke
- Only revokes recipient's access

**Changes:**
```typescript
// Change authorization from sender-only to either party:
const isSender = comparison.sender_id === user.id;
const isRecipient = comparison.recipient_id === user.id;
if (!isSender && !isRecipient) {
  return NextResponse.json({ error: 'Access denied' }, { status: 403 });
}

// Revoke BOTH access rows (hide for everyone):
const { error: revokeError } = await supabase
  .from('comparison_access')
  .update({ revoked_at: new Date().toISOString() })
  .eq('comparison_id', comparisonId);  // Removed .eq('user_id', ...) to revoke ALL
```

#### 1.2 Frontend: `components/Dashboard.tsx`

**Add a function to revoke comparison:**
```typescript
const revokeComparison = async (comparisonId: string) => {
  try {
    const res = await fetch('/api/comparisons/revoke', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ comparisonId })
    });
    if (res.ok) {
      // Refresh comparisons list
      await fetchComparisons();
      // If this was the active comparison, clear it
      if (activeComparisonId === comparisonId) {
        setProfileB(null);
        setActiveComparisonId(null);
        setActiveComparisonRole(null);
        setAiResponse(null);
      }
    }
  } catch (err) {
    console.error('Failed to remove comparison:', err);
  }
};
```

**Add remove button to Linked Comparisons (line ~4234-4247):**
```tsx
{comparisons.slice(0, 6).map((comparison) => (
  <div key={comparison.id} className="group relative">
    <button
      onClick={() => loadComparison(comparison.id)}
      // ... existing styles
    >
      {/* existing content */}
    </button>
    {/* Add X button on hover */}
    <button
      onClick={(e) => { e.stopPropagation(); revokeComparison(comparison.id); }}
      className="absolute -top-1 -right-1 w-5 h-5 bg-rose-500 text-white rounded-full opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center"
      title="Remove comparison"
    >
      <X className="w-3 h-3" />
    </button>
  </div>
))}
```

**Add remove option to used invites View section (line ~4314-4324):**
- Add a "Remove" button next to "View" button for used invites

---

### Part 2: Auto-Display Saved Analysis

**Investigation Result:** The current code in `applyComparison()` (lines 976-982) DOES set `aiResponse` when `comparison.analysis` exists:

```typescript
if (comparison.analysis && comparison.analysis.length > 100) {
  setAiResponse(comparison.analysis);
  setIsSavedAnalysis(true);
}
```

And the UI shows analysis when `aiResponse` exists (line 3282):
```tsx
{isAiAnalysisExpanded && aiResponse && (
  <div className="relative z-10 bg-white...">
    {/* Analysis content */}
  </div>
)}
```

**The logic appears correct.** However, need to verify:
1. The API returns `analysis` field (confirmed: line 77 in `[id]/route.ts`)
2. `isAiAnalysisExpanded` defaults to true (confirmed: line 437)

**Possible issue:** The "Generate" CTA might still show alongside the analysis. Check line 3132:
```tsx
{!aiLoading && !aiResponse && !aiError && (
  // Generate button shows here
)}
```

This condition is correct - Generate only shows when NO aiResponse. If user sees Generate button when analysis exists, it's a data issue (analysis not saved) not a code issue.

**Action:** Add console logging during implementation to verify data flow, but no code changes should be needed for this requirement.

---

## Files to Modify

| File | Change |
|------|--------|
| `app/api/comparisons/revoke/route.ts` | Allow either party to revoke; revoke ALL access rows |
| `components/Dashboard.tsx` | Add `revokeComparison()` function; add remove buttons to comparison list |

---

## Testing Checklist

### Revocation
- [ ] Sender can click "Remove" on comparison → hides for both
- [ ] Recipient can click "Remove" on comparison → hides for both
- [ ] After removal, comparison disappears from both dashboards
- [ ] Data still exists in DB (check `comparison_access.revoked_at` is set)
- [ ] Active comparison view clears if viewing comparison that gets removed

### Analysis Auto-Display
- [ ] Create comparison, generate analysis as User A
- [ ] Log in as User B, open comparison
- [ ] Analysis displays immediately (no "Generate" button)
- [ ] "Saved" badge appears in header
- [ ] "Regenerate" button available if user wants fresh analysis
