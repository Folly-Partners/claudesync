# Dealhunter UI/UX Improvements Plan

## Issues Identified

### 1. Leadership Photos Missing
- `photoUrl` field exists in `LeaderProfile` type but AI rarely provides URLs
- Component already handles photo display with initials fallback
- Need to improve photo sourcing

### 2. Assumptions Editor Design Issues
- Currently hidden/collapsible by default
- Slider-based design is awkward
- User wants it visible and better designed

### 3. Financial Summary Needs Tables
- Currently parsing markdown to text sections
- Historical performance shown as bullet points
- Need elegant tables for historical data and management forecasts

### 4. CRITICAL BUG: 5-Year Projections Wrong EBITDA
**Root Cause**: `ebitdaMargin` defaults to 15% instead of actual company margin (39%)
- `generateProjectionYears()` line 69 calculates: `ebitda = currentRevenue * (assumptions.ebitdaMargin / 100)`
- This ignores the actual `baseEbitda` and uses default 15% margin
- Result: Year 1 shows $12.3M EBITDA instead of ~$28M (39% of $72M revenue)

---

## Implementation Plan

### Fix 1: Leadership Photos

**Files:** `lib/prompts.ts`

1. Update AI prompt to actively search for photo URLs during analysis:
   - Instruct Claude to search LinkedIn profiles, company "About/Team" pages
   - Use web search tools (Tavily/Firecrawl if needed) to find headshots
   - If no photo found, return null and component uses initials fallback (already works)

2. No UI changes needed - existing fallback to initials is acceptable

---

### Fix 2: Assumptions Editor Redesign

**File:** `components/AssumptionsEditor.tsx`

Changes:
1. Remove collapsible behavior - always visible
2. Replace awkward slider design with clean table layout:
   ```
   | Assumption          | Value  | Range      |
   |---------------------|--------|------------|
   | Revenue Growth      | 5%     | -10% - 30% |
   | EBITDA Margin       | 39%    | 5% - 60%   |
   | Tax Rate            | 25%    | 15% - 40%  |
   ```
3. Use inline editable inputs (click to edit)
4. Keep category grouping but as horizontal sections, not tabs
5. Show "AI Suggested" vs "Custom" badges inline
6. Add subtle background color for modified values

---

### Fix 3: Financial Summary Tables

**File:** `components/FinancialSummary.tsx`

1. Create elegant historical performance table:
   ```
   | Year  | Revenue  | EBITDA   | Margin | YoY Growth |
   |-------|----------|----------|--------|------------|
   | 2020A | $45.3M   | $22.5M   | 49.7%  | -          |
   | 2021A | $53.2M   | $22.6M   | 42.5%  | +17.4%     |
   | ...   |          |          |        |            |
   ```

2. Add Management Forecast section if estimate years exist:
   - Separate table for "E" (estimate) years
   - Clear "Management Forecast" header
   - Visual distinction from historical (lighter background)

3. Keep existing charts but move tables above them

---

### Fix 4: CRITICAL - Fix Projection EBITDA Bug

**Files:** `components/AnalysisReport.tsx`, `lib/calculations.ts`

**Step 1:** Calculate actual base margin in AnalysisReport.tsx
```typescript
const baseMargin = (ebitda / revenue) * 100; // e.g., 39%
```

**Step 2:** Initialize assumptions with actual company metrics
```typescript
const [assumptions, setAssumptions] = useState<EditableAssumptions>(() => ({
  ...DEFAULT_ASSUMPTIONS,
  ebitdaMargin: baseMargin, // Use actual margin, not default 15%
}));
```

**Step 3:** Update useEffect to recalculate when financials change
```typescript
useEffect(() => {
  const actualMargin = (ebitda / revenue) * 100;
  setAssumptions(prev => ({
    ...prev,
    ebitdaMargin: actualMargin,
  }));
}, [ebitda, revenue]);
```

**Step 4:** Update scenario config in calculations.ts
- Instead of adding fixed margin deltas (+2%, 0%, -3%, -8%)
- Apply percentage changes to the BASE margin
- Good: baseMargin * 1.05 (5% improvement)
- Mediocre: baseMargin (no change)
- Bad: baseMargin * 0.92 (8% decline)
- Worst: baseMargin * 0.80 (20% decline)

---

## File Summary

| File | Changes |
|------|---------|
| `lib/prompts.ts` | Improve photo URL instructions |
| `components/LeadershipSection.tsx` | Add photo URL edit capability |
| `components/AssumptionsEditor.tsx` | Complete redesign - table layout, always visible |
| `components/FinancialSummary.tsx` | Add historical/forecast tables |
| `components/AnalysisReport.tsx` | Initialize assumptions with actual margin |
| `lib/calculations.ts` | Fix scenario margin calculations |

---

## Priority Order

1. **Fix 4** - CRITICAL bug causing wrong projections
2. **Fix 2** - Assumptions always visible with better design
3. **Fix 3** - Financial tables
4. **Fix 1** - Leadership photos (enhancement)
