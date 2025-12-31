# Dark Triad Visualization - Clarify Clinical Context

## Problem
The Dark Triad visualization shows "gifts" (green checkmarks) and "shadows" (amber warnings) for each trait. Users may interpret these bullet points as direct assessments of themselves rather than understanding they describe characteristics typical of **clinical-level** manifestations of these traits.

## Goal
Make it clear that the gifts/shadows describe what these traits look like at clinical extremes, not personal comments on the individual user.

## File to Modify
- `components/Dashboard.tsx` (lines ~4260-4453)

## Current State

### Existing Disclaimer (bottom of section)
> "Based on the Short Dark Triad (SD3). These traits exist on a spectrum in everyone — they only become problematic at extremes. Self-awareness is the first step to conscious choice."

### Current Gift/Shadow Labels
- Gifts shown with green `✓` - e.g., "Sees through manipulation & hidden agendas"
- Shadows shown with amber `⚠` - e.g., "May manipulate others to get ahead"

## Implementation

### Changes to `components/Dashboard.tsx`

**1. Add header above strengths (gifts) section (~line 4421):**
```tsx
{/* Gifts */}
<p className="text-[9px] text-slate-500 dark:text-slate-500 mb-1 uppercase tracking-wide">
  Research shows high scorers often:
</p>
<div className="space-y-1 mb-2">
  {trait.strengths.map(...)}
</div>
```

**2. Add header above shadows section (~line 4431):**
```tsx
{/* Shadow side */}
<div className="border-t border-slate-200 dark:border-slate-700 pt-2 mt-2">
  <p className="text-[9px] text-slate-500 dark:text-slate-500 mb-1 uppercase tracking-wide">
    At extreme levels, research links to:
  </p>
  <div className="space-y-1">
    {trait.shadows.map(...)}
  </div>
</div>
```

**3. Keep existing disclaimer at bottom (no change needed)**

This research-based framing makes it clear the bullet points describe general findings about people with elevated traits, not a direct assessment of the individual user.
