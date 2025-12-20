# Deep Personality: ADHD Screening & Clinical Flagging Enhancement

## Summary

Add ASRS-18 (Adult ADHD Self-Report Scale) assessment and integrate clinical flagging with evidence-based treatment recommendations throughout the app.

**User Preferences:**
- ASRS-18 (18 items) - full WHO ADHD assessment with inattention & hyperactivity subscales
- User-visible flags with compassionate framing (not hidden like Dark Triad)
- Evidence-based specific treatment recommendations (CBT, DBT, EMDR, medication classes with rationale)

---

## Files to Modify

| File | Changes |
|------|---------|
| `~/Deep-Personality/types.ts` | Add ASRS-18 type interface, ClinicalFlags interface |
| `~/Deep-Personality/services/data.ts` | Add ASRS-18 TestDefinition (18 items) |
| `~/Deep-Personality/services/scoring.ts` | Add ASRS scoring with Part A screener + subscales |
| `~/Deep-Personality/components/Wizard.tsx` | Add ASRS-18 to assessment flow, section metadata |
| `~/Deep-Personality/components/Visualizations.tsx` | Add ADHDGauges component |
| `~/Deep-Personality/components/Dashboard.tsx` | Import and render ADHD visualization |
| `~/Deep-Personality/app/api/analyze/route.ts` | Add Clinical Considerations section, ADHD integration |
| `~/Deep-Personality/lib/treatment-recommendations.ts` | NEW: Treatment matrix by condition |
| `~/Deep-Personality/lib/compassionate-framing.ts` | NEW: Framing language library |

---

## Implementation Steps

### Phase 1: Type Definitions (`types.ts`)

Add to `IndividualProfile.assessments`:

```typescript
asrs_18?: {
  totalScore: number;           // 0-72
  partAScore: number;           // 0-24 (items 1-6)
  partALabel: string;           // 'Negative Screen' | 'Positive Screen'
  likelyADHD: boolean;          // true if ≥4 items above threshold
  inattentionScore: number;     // 0-36 (9 items)
  inattentionLabel: string;     // 'Low' | 'Moderate' | 'High'
  hyperactivityScore: number;   // 0-36 (9 items)
  hyperactivityLabel: string;
  label: string;                // Overall interpretation
  presentationType: 'Predominantly Inattentive' | 'Predominantly Hyperactive-Impulsive' | 'Combined' | 'Subthreshold';
};
```

Add new `ClinicalFlags` interface for passing flags to AI.

---

### Phase 2: Assessment Definition (`services/data.ts`)

Add `ASRS_18` TestDefinition after PERMA (line ~668):

```typescript
export const ASRS_18: TestDefinition = {
  id: 'asrs_18',
  name: 'Attention & Focus Patterns',
  description: 'Thinking about the past six months, indicate how often each statement applies to you.',
  items: [
    // Part A (6 items - clinical screener)
    { id: 'asrs_1', text: 'I have trouble wrapping up the final details of a project...', subscale: 'inattention' },
    { id: 'asrs_2', text: 'I have difficulty getting things in order...', subscale: 'inattention' },
    { id: 'asrs_3', text: 'I have problems remembering appointments...', subscale: 'inattention' },
    { id: 'asrs_4', text: 'When I have a task that requires a lot of thought...', subscale: 'inattention' },
    { id: 'asrs_5', text: 'I fidget or squirm with my hands or feet...', subscale: 'hyperactivity' },
    { id: 'asrs_6', text: 'I feel overly active and compelled to do things...', subscale: 'hyperactivity' },
    // Part B (12 items - additional symptoms)
    // ... items 7-18 for inattention (7-11) and hyperactivity (12-18)
  ]
};
```

---

### Phase 3: Scoring Logic (`services/scoring.ts`)

Add ASRS scoring with:

1. **Dichotomous Part A Scoring** (for clinical screen):
   - Items 1-3: Score positive if response ≥ "Sometimes" (2)
   - Items 4-6: Score positive if response ≥ "Often" (3)
   - **Cutoff:** 4+ positive = "Likely ADHD"

2. **Continuous Subscale Scoring**:
   - Inattention: Sum items 1-4, 7-11 (9 items, max 36)
   - Hyperactivity: Sum items 5-6, 12-18 (9 items, max 36)

3. **Presentation Type**:
   - Compare subscale percentages to determine Inattentive/Hyperactive/Combined

4. Add `generateClinicalFlags()` function to aggregate all clinical indicators.

---

### Phase 4: Wizard Integration (`components/Wizard.tsx`)

1. Import `ASRS_18` from data.ts
2. Add section metadata:
   ```typescript
   'asrs_18': {
     icon: Brain,
     timeEstimate: '~3 min',
     insight: 'Assess your attention and focus patterns',
     color: 'cyan'
   }
   ```
3. Add to steps array after DTS, before RSQ

---

### Phase 5: Visualization (`components/Visualizations.tsx`)

Create `ADHDGauges` component:
- Two circular gauges: Inattention (0-36) and Hyperactivity (0-36)
- Part A screener result indicator (Positive/Negative)
- Presentation type label if screen positive
- Comparison mode support (side-by-side for two profiles)
- Color coding: Green (Low), Amber (Moderate), Red (High)

---

### Phase 6: Dashboard Integration (`components/Dashboard.tsx`)

1. Import `ADHDGauges`
2. Add to profile summary generation
3. Add visualization section after mental health gauges:
   ```tsx
   {profileA?.assessments?.asrs_18 && (
     <ADHDGauges profileA={profileA} profileB={profileB} />
   )}
   ```

---

### Phase 7: Treatment Recommendations (NEW FILES)

#### `lib/treatment-recommendations.ts`

Treatment matrix by condition with **layman-friendly efficacy data**:

##### Depression Treatments

| Treatment | How Well It Works | What This Means | Source |
|-----------|------------------|-----------------|--------|
| **CBT** | 60-70% response rate | ~2 in 3 people feel significantly better | Cuijpers et al., 2019 meta-analysis |
| **Behavioral Activation** | 50-60% remission | ~1 in 2 achieve full remission | Ekers et al., 2014 |
| **SSRIs** (e.g., sertraline) | NNT = 7 | For every 7 people who take it, 1 gets better who wouldn't have on placebo | Cipriani et al., 2018 Lancet |
| **SNRIs** (e.g., venlafaxine) | NNT = 7-8 | Similar to SSRIs; may help more with fatigue/pain | Cipriani et al., 2018 |
| **Bupropion** | NNT = 9 | Slightly less effective but fewer sexual side effects | Cipriani et al., 2018 |

##### Anxiety Treatments

| Treatment | How Well It Works | What This Means | Source |
|-----------|------------------|-----------------|--------|
| **CBT** | 50-60% remission | ~1 in 2 no longer meet diagnosis after treatment | Hofmann & Smits, 2008 |
| **Exposure Therapy** | 80-90% improvement | ~4 in 5 see significant reduction in specific fears | Wolitzky-Taylor et al., 2008 |
| **SSRIs** | NNT = 5-7 | More effective for anxiety than depression | Baldwin et al., 2014 |
| **Buspirone** | 60% response | Takes 2-4 weeks; no dependence risk | Chessick et al., 2006 |

##### PTSD Treatments

| Treatment | How Well It Works | What This Means | Source |
|-----------|------------------|-----------------|--------|
| **EMDR** | 77% no longer have PTSD | ~3 in 4 lose diagnosis after 6-12 sessions | Shapiro, 2018; VA/DoD Guidelines |
| **CPT** | 53% remission | ~1 in 2 achieve full remission | Resick et al., 2017 |
| **Prolonged Exposure** | 53% remission | Similar to CPT; may be harder to tolerate | Powers et al., 2010 |
| **Sertraline/Paroxetine** | NNT = 4-5 | FDA-approved; often used with therapy | Stein et al., 2006 |
| **Prazosin** (for nightmares) | 70% reduction | ~7 in 10 have fewer/less intense nightmares | Raskind et al., 2013 |

##### ADHD Treatments

| Treatment | How Well It Works | What This Means | Source |
|-----------|------------------|-----------------|--------|
| **Stimulants** (methylphenidate, amphetamines) | 70-80% response | ~3 in 4 see significant symptom reduction | Faraone & Glatt, 2010 |
| **Atomoxetine** (non-stimulant) | 60% response | Option if stimulants aren't tolerated | Newcorn et al., 2008 |
| **CBT for ADHD** | 30-50% additional improvement | Added benefit on top of medication | Safren et al., 2010 |
| **ADHD Coaching** | Moderate evidence | Improves organization, time management | Prevatt & Yelland, 2015 |

##### Cluster B (Emotional Dysregulation) Treatments

| Treatment | How Well It Works | What This Means | Source |
|-----------|------------------|-----------------|--------|
| **DBT** | 77% no longer meet BPD criteria at 1 year | ~3 in 4 see major improvement | Linehan et al., 2006 |
| **Schema Therapy** | 52% recovery vs 29% for other therapies | Nearly 2x more effective than standard care | Giesen-Bloo et al., 2006 |
| **MBT** | 50% remission at 18 months | Particularly good for relationship patterns | Bateman & Fonagy, 2009 |

##### Efficacy Key for Users

```
Response = Symptoms noticeably better (usually ≥50% reduction)
Remission = Symptoms mostly or completely gone
NNT (Number Needed to Treat) = How many people need treatment for 1 to benefit
  - NNT of 5 = Very effective (1 in 5 benefits beyond placebo)
  - NNT of 10 = Moderately effective (1 in 10 benefits beyond placebo)
```

#### `lib/compassionate-framing.ts`

Condition-specific framing language:
- Non-pathologizing introductions
- "These patterns often developed as protective strategies"
- Strength-based reframes
- Disclaimer about screening vs. diagnosis

---

### Phase 8: AI Analysis Integration (`app/api/analyze/route.ts`)

#### 8.1 Add ADHD to SCORING CONTEXT (line ~209)

```
- ASRS (ADHD Screening): Measures inattention (0-36) and hyperactivity (0-36).
  Part A screener positive (4+ items above threshold) suggests clinical evaluation.
  Presentation types: Predominantly Inattentive, Hyperactive-Impulsive, or Combined.
```

#### 8.2 New Clinical Considerations Section (after Mental Health Support ~line 912)

```markdown
## 🏥 Clinical Considerations

*The following observations are based on validated assessments and are provided
for self-understanding, not diagnosis...*

### Flags Detected in {name}'s Profile

[List flagged conditions with compassionate framing]

### Evidence-Based Treatment Recommendations

| Therapy | How Well It Works | What This Means for You | Why It Fits Your Profile |
|---------|------------------|------------------------|-------------------------|
| CBT | 60-70% feel significantly better | ~2 in 3 people improve | [Personalized rationale] |
| EMDR | 77% no longer meet PTSD criteria | ~3 in 4 recover | [If trauma indicated] |
| DBT | 77% major improvement at 1 year | ~3 in 4 see lasting change | [If emotion dysregulation] |

### Medication Considerations

*Always discuss with a psychiatrist - this is educational only.*

| Medication Class | How Well It Works | Plain English | Notes for Your Situation |
|-----------------|------------------|---------------|-------------------------|
| SSRIs | NNT = 5-7 for anxiety | 1 in 5-7 benefits beyond placebo | [If anxiety/depression flagged] |
| Stimulants | 70-80% response for ADHD | ~3 in 4 see significant improvement | [If ADHD flagged] |
| Prazosin | 70% nightmare reduction | ~7 in 10 sleep better | [If PTSD with nightmares] |

**Understanding the numbers:**
- **Response rate** = Symptoms noticeably better (usually 50%+ reduction)
- **Remission** = Symptoms mostly or completely gone
- **NNT** = Number Needed to Treat (lower = more effective; NNT of 5 means 1 in 5 benefits beyond placebo)
```

#### 8.3 ADHD Integration Throughout Analysis

Integrate ADHD into existing sections:

1. **Career Sweet Spot**: Emphasize variety, novelty, hyperfocus, deadline motivation
2. **Work Style**: Time management strategies, focus tips, environment needs
3. **Relationship Dynamics**: RSD, interrupting patterns, time blindness
4. **Coping Strategies**: ADHD-specific tools (body doubling, Pomodoro, external structure)
5. **Your Superpowers**: Hyperfocus, creativity, crisis performance, resilience
6. **Environment Recommendations**: Clutter management, noise control, launch pads

#### 8.4 Update Dark Triad Handling

Change `stripDarkTriadFromProfile()` to include Dark Triad with compassionate framing context instead of stripping entirely. Add `_clinicalContext.darkTriad.framingNote`.

---

### Phase 9: Comparison Mode

When both profiles have ASRS data, add:

- Side-by-side ADHD visualization
- Insight box if one screens positive and one doesn't
- AI analysis section on ADHD dynamics:
  - Different time perception
  - Communication style differences
  - Strategies for neurotypical partner
  - Strategies for ADHD partner
  - "Two ADHD peas" considerations if both positive

---

## Clinical Flags Summary

| Condition | Source | Threshold | Flag Name |
|-----------|--------|-----------|-----------|
| Depression | PHQ-9 | ≥10 | `depression.flagged` |
| Anxiety | GAD-7 | ≥10 | `anxiety.flagged` |
| PTSD | PCL-5 | ≥31 | `ptsd.flagged` |
| ADHD | ASRS Part A | 4+ positive | `adhd.likelyADHD` |
| Cluster A | Personality Styles | ≥4.0 | `clusterA.flagged` |
| Cluster B | Personality Styles | ≥4.0 | `clusterB.flagged` |
| Cluster C | Personality Styles | ≥4.0 | `clusterC.flagged` |
| Dark Triad | SD3 | 1 SD above mean | `darkTriad.*.flagged` |
| Childhood Trauma | ACE | ≥4 | `adverseChildhood.flagged` |

---

## Disclaimers to Include

1. **Main disclaimer** at top of Clinical Considerations
2. **Treatment disclaimer** before recommendations
3. **Personality patterns disclaimer** (not disorders, developed for reasons)
4. **ASRS disclaimer** (screening tool, not diagnostic)
5. **Crisis resources** if suicidal ideation indicated

---

## Testing Checklist

- [ ] ASRS-18 flows correctly in Wizard
- [ ] Part A screening logic correctly flags at 4+ threshold
- [ ] Subscale scoring calculates correctly
- [ ] Presentation type determination works
- [ ] ADHDGauges renders in single and comparison mode
- [ ] AI analysis includes ADHD in relevant sections
- [ ] Clinical Considerations section generates with flags
- [ ] Treatment recommendations match flagged conditions
- [ ] Compassionate framing reads well
- [ ] Dark Triad now visible with appropriate framing
