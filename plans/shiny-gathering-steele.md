# Adaptive High-Conflict Personality (HCP) Screening

## Summary
Add adaptive two-stage HCP screening to Deep Personality using Bill Eddy's framework. Short screener triggers deeper assessment only if elevated.

## Architecture

### Stage 1: HCP Quick Screen (existing)
- **5 items** already in PERSONALITY_STYLES (HCP_1-5)
- **Trigger threshold**: Average >= 3.5 (1 SD above mean)
- Covers: all-or-nothing thinking, external blame, grudge-holding, conflict escalation, loyalty questioning

### Stage 2: HCP Extended (NEW - conditional)
- **18 items** only shown if Stage 1 >= 3.5
- Components:
  - **MSI-BPD adapted** (10 items) - validated borderline screening, reworded for self-insight
  - **Bill Eddy WEB items** (8 items) - Words, Emotions, Behavior framework

### WEB Subscales
| Subscale | Items | What it measures |
|----------|-------|------------------|
| Polarized Thinking | 2 | All-or-nothing cognition |
| Unmanaged Emotions | 2 | Emotional dysregulation |
| Extreme Behavior | 2 | Actions most wouldn't do |
| Blame Preoccupation | 2 | Target-of-blame pattern |

### Pattern Detection
Score alignment with 4 HCP types:
- **Borderline** → affective instability, abandonment, identity, self-harm items
- **Narcissistic** → polarized thinking, blame, anger items
- **Histrionic** → relationship instability, unmanaged emotions, impulsivity
- **Antisocial** → extreme behavior, blame, impulsivity

## Wizard Flow

```
PERSONALITY_STYLES (includes HCP Core 5 items)
    ↓
    └─→ If HCP Core avg >= 3.5
        ↓
        HCP_EXTENDED (18 items, ~3 min)
    ↓
ECR-S (continues normally)
```

## Files to Modify

### 1. `/services/data.ts`
Add HCP_EXTENDED test definition:
```typescript
export const HCP_EXTENDED: TestDefinition = {
  id: 'hcp_extended',
  name: 'High Conflict Patterns Assessment',
  items: [
    // MSI-BPD adapted (10 items)
    { id: 'hcp_msi_1', text: 'I have relationships that are intense but unstable.', subscale: 'relationship_instability' },
    // ... 9 more MSI items

    // WEB-aligned (8 items)
    { id: 'hcp_web_1', text: 'People are either completely trustworthy or completely untrustworthy.', subscale: 'polarized_thinking' },
    // ... 7 more WEB items
  ]
};
```

### 2. `/services/scoring.ts`
Add scoring logic:
- MSI-BPD score (positive count >= 7 = flagged)
- WEB subscale averages
- Pattern scores (borderline, narcissistic, histrionic, antisocial)
- Primary pattern detection
- hcpLikely composite flag

### 3. `/types.ts`
Add type definitions:
```typescript
hcp_extended?: {
  msiBpd: { score: number; positiveCount: number; flagged: boolean };
  webScores: {
    polarized_thinking: { raw: number; label: string };
    unmanaged_emotions: { raw: number; label: string };
    extreme_behavior: { raw: number; label: string };
    blame_preoccupation: { raw: number; label: string };
  };
  patterns: { borderline, narcissistic, histrionic, antisocial: number };
  primaryPattern: string;
  hcpLikely: boolean;
};
```

### 4. `/components/Wizard.tsx`
Add conditional logic (follows RAADS-14 pattern):
```typescript
const calculateHCPCoreScore = useCallback(...);
const shouldShowHCPExtended = useMemo(() => {
  const hcpItems = ['HCP_1', 'HCP_2', 'HCP_3', 'HCP_4', 'HCP_5'];
  const hcpCompleted = hcpItems.every(id => answers[id] !== undefined);
  if (!hcpCompleted) return false;
  return calculateHCPCoreScore(answers) >= 3.5;
}, [answers]);
```

### 5. `/config/wizard-sections.ts`
Add section metadata:
```typescript
'hcp_extended': {
  icon: AlertTriangle,
  timeEstimate: '~3 min',
  insight: 'Understanding your conflict patterns can transform your relationships...',
  color: 'red',
  scaleType: 'true',
  displayName: 'Conflict Patterns',
  transitionMessage: 'Based on your responses, these questions will help clarify your conflict style.',
}
```

### 6. `/components/visualizations/HCPDisplay.tsx` (NEW)
Create display component with:
- WEB breakdown gauges (4 dimensions)
- Pattern profile (radar/bar showing 4 HCP types)
- Primary pattern card with Bill Eddy educational content
- Strengths-based framing (not stigmatizing)
- Growth strategies

## Educational Framing (Bill Eddy Style)

**Key messages:**
- Patterns are learned, not permanent
- Everyone has some conflict tendencies (spectrum)
- Awareness enables change
- Focus on understanding, not blame

**Pattern descriptions use:**
- Neutral names (e.g., "Emotional Intensity Pattern" not "Borderline")
- Strengths alongside challenges
- Actionable growth strategies

## Use Case Support

| Use Case | How Supported |
|----------|---------------|
| Personal insight | Default framing, strengths-based |
| Relationship screening | Comparison mode, pattern compatibility |
| Professional intake | MSI-BPD clinical scoring, flags |
| Research | Raw scores, subscales, binary flags |

## Implementation Notes

**Self-harm item**: Soften wording from clinical MSI-BPD. Instead of "I have deliberately hurt myself or had thoughts of self-harm", use gentler phrasing like "I've gone through difficult periods where I struggled with wanting to hurt myself" - maintains clinical utility while being less triggering.

## Validation Sources
- MSI-BPD (Zanarini et al., 2003) - 81% sensitivity, 85% specificity
- Bill Eddy WEB Method (High Conflict Institute)
- Existing HCP Index composite already in codebase
