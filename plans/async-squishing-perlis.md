# Fix Stripe Payment & Dark Mode Styling

## Problem 1: Stripe Payment Error

**Error:** "Payment system not configured. Please contact support."

**Root Cause:** The `.next/` build cache was created BEFORE the Stripe environment variables were added to `.env.local`. Next.js baked the old (empty) env vars into the build artifacts. Even though `.env.local` now has valid credentials, the stale build doesn't see them.

**Solution:**
```bash
rm -rf .next/
npm run dev
```

This forces Next.js to rebuild with the current environment variables.

---

## Problem 2: Dark Mode Styling Issues

Multiple cards/sections have white/cream backgrounds that are jarring in dark mode. They use `bg-white`, `bg-amber-50`, `bg-slate-50`, etc. without corresponding `dark:` variants.

### Files to Modify

| File | Locations |
|------|-----------|
| `components/Dashboard.tsx` | ~12 locations |
| `components/Visualizations.tsx` | ~15 locations |

---

## Dashboard.tsx Dark Mode Fixes

### 1. Dark Triad Section Note Box (~line 3724)
```diff
- bg-amber-50 border border-amber-200
+ bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800
```

### 2. Dark Triad Cards (Machiavellianism, Narcissism, Psychopathy) (~lines 3769, 3787, 3805)
```diff
- bg-white border border-slate-200
+ bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700

- text-slate-800
+ text-slate-800 dark:text-slate-200

- text-slate-600
+ text-slate-600 dark:text-slate-400

- text-slate-700
+ text-slate-700 dark:text-slate-300
```

### 3. Form Select Dropdowns (~lines 2656, 2700)
```diff
- bg-white
+ bg-white dark:bg-slate-800
```

### 4. Button Elements (~lines 2811, 2818, 3067, 3074)
```diff
- bg-white
+ bg-white dark:bg-slate-800
```

---

## Visualizations.tsx Dark Mode Fixes

### 1. Attachment Style Quadrant Boxes (~lines 322-378, 436-475)

**Secure box:**
```diff
- bg-green-50
+ bg-green-50 dark:bg-green-900/20
```

**Dismissive box:**
```diff
- bg-blue-50
+ bg-blue-50 dark:bg-blue-900/20
```

**Preoccupied box:**
```diff
- bg-amber-50
+ bg-amber-50 dark:bg-amber-900/20
```

**Fearful box:**
```diff
- bg-red-50
+ bg-red-50 dark:bg-red-900/20
```

**Note boxes:**
```diff
- bg-slate-50 border border-slate-200
+ bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700
```

### 2. Personality Style Clusters (~lines 1427, 1443, 1462)

**Explanation box:**
```diff
- bg-slate-50 border-slate-200
+ bg-slate-50 dark:bg-slate-800 border-slate-200 dark:border-slate-700
```

**Cluster cards (A, B, C) - fix inline background colors or className:**
```diff
- bg-white
+ bg-white dark:bg-slate-800
```

### 3. ADHD Gauges (~lines 854, 873)

**Warning/Result boxes:**
```diff
- bg-amber-50 border-amber-200
+ bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800

- bg-green-50 border-green-200
+ bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800
```

### 4. ACE Display & Other Sections (~lines 1329, 1380, 1791, 1861)

**Amber boxes:**
```diff
- bg-amber-50 border-amber-200
+ bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800
```

**Blue info boxes:**
```diff
- bg-blue-50 border-blue-200
+ bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800
```

---

## Implementation Order

### Phase 1: Fix Stripe (Critical - 1 min)
1. Delete `.next/` directory
2. Restart dev server with `npm run dev`
3. Test checkout button

### Phase 2: Fix Dark Mode in Dashboard.tsx
1. Search for `bg-white` without `dark:` → add `dark:bg-slate-800`
2. Search for `bg-amber-50` without `dark:` → add `dark:bg-amber-900/20`
3. Search for `border-slate-200` without `dark:` → add `dark:border-slate-700`
4. Fix text colors that need dark variants

### Phase 3: Fix Dark Mode in Visualizations.tsx
1. Fix AttachmentPlot quadrant boxes (green, blue, amber, red backgrounds)
2. Fix PersonalityStyleClusters explanation and card backgrounds
3. Fix ADHDGauges warning/result boxes
4. Fix ACE Display and other info boxes
5. Fix all `bg-slate-50` → add `dark:bg-slate-800`

### Phase 4: Test
1. Verify checkout works
2. Verify all sections render properly in dark mode
3. Check text readability on dark backgrounds

---

## Color Mapping Reference

| Light Mode | Dark Mode |
|------------|-----------|
| `bg-white` | `dark:bg-slate-800` |
| `bg-slate-50` | `dark:bg-slate-800` or `dark:bg-slate-900/50` |
| `bg-amber-50` | `dark:bg-amber-900/20` |
| `bg-green-50` | `dark:bg-green-900/20` |
| `bg-blue-50` | `dark:bg-blue-900/20` |
| `bg-red-50` | `dark:bg-red-900/20` |
| `border-slate-200` | `dark:border-slate-700` |
| `border-amber-200` | `dark:border-amber-800` |
| `text-slate-600` | `dark:text-slate-400` |
| `text-slate-700` | `dark:text-slate-300` |
| `text-slate-800` | `dark:text-slate-200` |
