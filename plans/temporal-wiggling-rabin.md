# Deep Personality Dashboard UI Fixes

## Issues to Fix

### 1. ADHD Section Circles Show Red When Scores Are Missing/Low
**Problem**: When ADHD scores are undefined/null, the color functions fall through to RED instead of GREEN.

In JavaScript, `undefined < 18` returns `false`, so all conditions fail and the function returns red.

Additionally, CircularGauge renders a full red circle when value is undefined because NaN strokeDashoffset defaults to 0.

**Files to modify**:
- `components/visualizations/ADHDGauges.tsx` (lines 14-24)

**Fix**:
```typescript
const getInattentionColor = (score: number | undefined) => {
  if (score === undefined || score === null) return '#10b981'; // Green - no data
  if (score < 18) return '#10b981'; // Green - Low
  if (score < 27) return '#f59e0b'; // Amber - Moderate
  return '#ef4444'; // Red - High
};
```

Also consider handling undefined in CircularGauge to show "N/A" or 0.

---

### 2. Early Experiences Section Looks Lost
**Problem**: The ACE card has no explicit `lg:col-span-*` class in the 3-column grid, causing it to sit alone in one column.

**File to modify**:
- `components/Dashboard.tsx` (lines 3438-3443)

**Fix**: Add `lg:col-span-1` explicitly and consider grouping it with another single-column item, OR restructure the grid layout so items flow naturally.

---

### 3. Career Interests Empty for Demo User
**Problem**: The Career Interests section always renders without checking if `onet_mini_ip` data exists.

**File to modify**:
- `components/Dashboard.tsx` (lines 3360-3364)

**Fix**: Add conditional rendering like other sections:
```jsx
{profileA.assessments.onet_mini_ip && (
  <div className="...">
    <h4>Career Interests</h4>
    <ValueBars ... />
  </div>
)}
```

---

### 4. Personal Values Section Looks Lost
**Problem**: The 2-column grid renders even when only one or zero items exist, creating awkward whitespace.

**File to modify**:
- `components/Dashboard.tsx` (lines 3366-3383)

**Fix**: When only one item exists in a row, make it span full width.
- Check if both `pvq_21` and `weims` exist
- If only one exists, render it outside the grid OR add dynamic col-span
- Hide the grid entirely if neither exists

---

## Implementation Order

1. **Fix ADHD color logic** - `ADHDGauges.tsx`
   - Handle undefined/null scores in `getInattentionColor` and `getHyperactivityColor`
   - Return green for missing data (no ADHD concerns when no data)

2. **Add conditional rendering to Career Interests** - `Dashboard.tsx:3360-3364`
   - Wrap in `{profileA.assessments.onet_mini_ip && ...}`

3. **Improve Values & Motivation layout** - `Dashboard.tsx:3366-3383`
   - If only one of pvq_21/weims exists, make that card full width
   - Remove empty grid when neither exists

4. **Improve Wellbeing section layout** - `Dashboard.tsx:3437-3443`
   - Give ACE card explicit `lg:col-span-1`
   - Consider pairing it with another 1-column element or adjusting preceding col-spans
