# Pricing Increase & Copy Redesign Plan

## Overview
Increase pricing from $9/$7/$12 to $19/$19/$29 with new value-anchored copy that emphasizes the $500+ worth of clinical assessments.

---

## New Pricing Structure

| Product | Old Price | New Price |
|---------|-----------|-----------|
| Individual Report | $9 | $19 |
| Comparison Report | $7 | $19 |
| Bundle (Both) | $12 | $29 |

**Bundle savings:** $19 + $19 = $38 → $29 = **Save $9**

---

## Changes Required

### 1. Stripe Dashboard (Manual)
Create 3 new prices in Stripe:
- `Full Report` - $19.00 USD (one-time)
- `Comparison Report` - $19.00 USD (one-time)
- `Bundle` - $29.00 USD (one-time)

Then update `.env.local` with the new price IDs.

### 2. PremiumGate.tsx Updates

**File:** `/Users/andrewwilkinson/Deep-Personality/components/PremiumGate.tsx`

#### A. Update price variables (line ~94)
```tsx
// OLD
const primaryPrice = isComparison ? '$7' : '$9';

// NEW
const primaryPrice = '$19';
```

#### B. Update primary CTA text (line ~96)
```tsx
// OLD
const primaryCTA = isComparison ? 'Unlock Full Compatibility Report' : 'Show Me Everything';

// NEW
const primaryCTA = isComparison ? 'Unlock Compatibility Report' : 'Unlock Your Full Report';
```

#### C. Add value anchor copy (new - after social proof ~line 194)
Add a value proposition line:
```tsx
{/* Value anchor */}
<p className="text-center text-amber-300/90 text-sm font-medium mb-6">
  The same tests psychologists charge $500+ to interpret
</p>
```

#### D. Redesign bundle section (lines ~241-265)

**Changes:**
- Remove `{!isComparison && ...}` condition (show on both pages)
- Update badge: "💎 BEST VALUE — Save $9"
- New CTA: "Unlock Your Report + Relationships — $29"
- New subtext: "See how you match with your partner, crush, or anyone..."

```tsx
{/* Bundle Option - show on BOTH individual and comparison pages */}
<div className="mt-6 relative">
  {/* "Best Value" badge */}
  <div className="absolute -top-3 left-1/2 -translate-x-1/2 z-10">
    <span className="bg-gradient-to-r from-pink-400 to-purple-400 text-white text-xs font-bold px-3 py-1 rounded-full shadow-lg">
      💎 BEST VALUE — Save $9
    </span>
  </div>

  <button
    onClick={() => handleCheckout('bundle')}
    disabled={loading !== null}
    className="w-full py-4 px-6 bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 text-white font-semibold text-base rounded-xl transition-all disabled:opacity-50 shadow-lg hover:shadow-xl border-2 border-indigo-400/30"
  >
    {loading === 'bundle' ? (
      <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin mx-auto" />
    ) : (
      <div className="flex flex-col gap-1">
        <span className="font-bold text-lg">Unlock Your Report + Relationships — $29</span>
        <span className="text-indigo-200 text-sm">See how you match with your partner, crush, or anyone...</span>
      </div>
    )}
  </button>
</div>
```

---

## Final Copy Decisions

**Value Anchor:** "The same tests psychologists charge $500+ to interpret"

**Bundle CTA:** "Unlock Your Report + Relationships — $29"
**Bundle Subtext:** "See how you match with your partner, crush, or anyone..."

**Bundle on Comparison Page:** Yes - show bundle upsell on both individual AND comparison gates

---

## Implementation Steps

1. **Stripe Dashboard** (manual - Andrew does this):
   - Create new price: "Full Report" - $19.00 USD one-time
   - Create new price: "Comparison Report" - $19.00 USD one-time
   - Create new price: "Bundle" - $29.00 USD one-time
   - Copy the 3 new price IDs

2. **Update `.env.local`** with new Stripe price IDs

3. **Update `PremiumGate.tsx`**:
   - Line ~94: Change prices to `$19` for both
   - Line ~96: Update CTA text
   - Line ~194: Add value anchor copy
   - Lines ~241-265: Redesign bundle section, remove `!isComparison` condition
   - Line ~246: Update badge to "Save $9"

4. Test checkout flow locally

5. Deploy to Vercel

---

## Files to Modify

| File | Changes |
|------|---------|
| `.env.local` | Update 3 Stripe price IDs (after creating in Stripe) |
| `components/PremiumGate.tsx` | All copy/pricing updates |
