# Autism/Neurodivergence Screening Implementation Plan

## Overview
Add comprehensive neurodivergence screening to Deep Personality:
- **AQ-10** (Autism Quotient - 10 items) - Baron-Cohen's validated screener
- **CAT-Q** (Camouflaging Autistic Traits - 25 items) - Detects masking behaviors
- **Sensory Processing** (10 items) - Custom sensory sensitivity assessment
- **Total**: ~45 new items, ~8 minutes additional assessment time

**Placement**: Near end of assessment flow (after PHQ-9, GAD-7, PCL-5)

---

## Files to Modify

### 1. Data Definitions
**File**: `~/Deep-Personality/services/data.ts`

Add three new TestDefinition exports:
- `AQ_10` - 10 items with subscales: attention_to_detail, attention_switching, communication, imagination
- `CAT_Q` - 25 items with subscales: compensation (9), masking (8), assimilation (8)
- `SENSORY_PROCESSING` - 10 items with subscales: visual, auditory, tactile, olfactory, gustatory, proprioceptive, vestibular

### 2. Type Definitions
**File**: `~/Deep-Personality/types.ts`

Add to `IndividualProfile.assessments`:
```typescript
aq_10?: {
  totalScore: number; percentile: number; label: string;
  likelyAutistic: boolean;
  subscales: { attention_to_detail, attention_switching, communication, imagination }
}
cat_q?: {
  totalScore: number; percentile: number; label: string;
  significantMasking: boolean; exhaustionIndicator: boolean;
  subscales: { compensation, masking, assimilation }
  subscaleLabels: { compensation, masking, assimilation }
}
sensory_processing?: {
  totalScore: number; label: string; sensitivityLevel: string;
  subscales: { visual, auditory, tactile, olfactory, gustatory, proprioceptive, vestibular }
  primarySensitivities: string[]
}
```

### 3. Scoring Logic
**File**: `~/Deep-Personality/services/scoring.ts`

Add:
- Normative data constants (AQ10_NORMS, CATQ_NORMS, SENSORY_THRESHOLDS)
- AQ-10 binary scoring (Agree/Strongly Agree on autism-consistent items = 1 point, cutoff ≥6)
- CAT-Q Likert sum scoring with subscale calculations
- Sensory processing sum scoring with domain flagging
- Update regex filter for customQuestionResponses to exclude new item prefixes

### 4. Wizard Configuration
**File**: `~/Deep-Personality/config/wizard-sections.ts`

Add SECTION_META entries:
```typescript
'aq_10': { icon: Brain, timeEstimate: '~2 min', insight: 'Explore your social and communication patterns', color: 'violet' }
'cat_q': { icon: Users, timeEstimate: '~4 min', insight: 'Understand how you adapt in social situations', color: 'purple' }
'sensory_processing': { icon: Sparkles, timeEstimate: '~2 min', insight: 'Map your unique sensory experiences', color: 'fuchsia' }
```

### 5. Wizard Component
**File**: `~/Deep-Personality/components/Wizard.tsx`

- Import: `AQ_10, CAT_Q, SENSORY_PROCESSING` from data.ts
- Add to steps array after ASRS_18, before ACE:
  ```typescript
  { type: 'test', data: AQ_10 },
  { type: 'test', data: CAT_Q },
  { type: 'test', data: SENSORY_PROCESSING },
  ```

### 6. Visualization Component (NEW)
**File**: `~/Deep-Personality/components/visualizations/AutismScreeningDisplay.tsx`

Create new component with:
- Combined screening result banner (autistic traits detected / significant masking / neurotypical)
- Three-column display: AQ-10 gauge, CAT-Q subscales, Sensory profile
- Comparison mode support (profileA, profileB)
- Context section explaining each screening tool

### 7. Visualizations Export
**File**: `~/Deep-Personality/components/Visualizations.tsx`

Add export: `export { AutismScreeningDisplay } from './visualizations/AutismScreeningDisplay';`

### 8. Dashboard Integration
**File**: `~/Deep-Personality/components/Dashboard.tsx`

- Import AutismScreeningDisplay
- Add section after ADHDGauges:
  ```tsx
  {profileA.assessments.aq_10 && (
    <section>
      <h3>Neurodivergence Screening</h3>
      <AutismScreeningDisplay profileA={profileA} profileB={profileB} />
    </section>
  )}
  ```

### 9. Compassionate Framing
**File**: `~/Deep-Personality/lib/compassionate-framing.ts`

Add three new framings:
- `AUTISM_FRAMING` - Neurodiversity-affirming language, autistic strengths, late-discovery validation
- `MASKING_FRAMING` - Social adaptation patterns, exhaustion acknowledgment, unmasking guidance
- `SENSORY_FRAMING` - Heightened sensory awareness as difference not flaw, accommodation strategies

Update `FramingKey` and `ALL_FRAMINGS` to include new entries.

### 10. Treatment Recommendations
**File**: `~/Deep-Personality/lib/treatment-recommendations.ts`

Add `AUTISM_SUPPORT` with:
- **Therapies**: Autism-affirming therapy, OT (sensory focus), Autism coaching
- **Lifestyle**: Sensory accommodations, unmasking practice
- Include considerations about avoiding ABA for adults, finding neurodiversity-affirming providers

Update `ConditionKey` and `ALL_TREATMENTS`.

### 11. AI Prompts
**File**: `~/Deep-Personality/services/analyze/prompts.ts`

Add to SCORING_CONTEXT:
- AQ-10 interpretation (0-10 scale, ≥6 threshold)
- CAT-Q interpretation (compensation/masking/assimilation subscales, exhaustion indicator)
- Sensory processing interpretation (domain sensitivities)
- Neurodivergence-specific guidance:
  - Frame autism as neurotype difference, not disorder
  - Highlight autistic strengths
  - Acknowledge masking exhaustion
  - Recognize autism-ADHD comorbidity (30-80% overlap)
  - Validate late-discovered autism experience

### 12. Marketing/Landing Page
**File**: `~/Deep-Personality/components/LandingHero.tsx`

Add to assessments list:
```typescript
{ name: "AQ-10", desc: "Autism Screening", validity: "NHS validated" },
{ name: "CAT-Q", desc: "Masking Assessment", validity: "Research validated" },
```

### 13. Demo Account Update
**File**: Database update via Supabase or API

Update `demo@deeppersonality.app` profile with **positive scores for ALL conditions**:
- **ADHD**: likelyADHD: true, high inattention + hyperactivity
- **Autism**: likelyAutistic: true, AQ-10 score 7+
- **Masking**: significantMasking: true, exhaustionIndicator: true
- **Sensory**: moderate-high sensitivity, multiple primary sensitivities
- **Depression**: PHQ-9 moderate (14+)
- **Anxiety**: GAD-7 moderate (12+)
- **PTSD**: ptsdFlag: true, PCL-5 38+
- **Personality Clusters**: All clusters elevated (3.5+ raw scores)
- **ACE**: Elevated score
- **Attachment**: Anxious-avoidant pattern

### 14. Sample Profiles Update
**Files**:
- `~/Deep-Personality/example_profile.json`
- `~/Deep-Personality/example_profile_sam.json`

Update both sample profiles with:
- **Balanced but complete scores** for ALL assessments
- Include all new autism/sensory fields
- Varied profiles (one more neurotypical, one with some elevated traits)
- Ensure every assessment has data (ipip_50, ecr_s, csi_16, ders_16, onet_mini, pvq_21, weims, ace, gad_7, phq_9, pcl_5, asrs_18, aq_10, cat_q, sensory_processing, dts, rsq, scs_sf, swls, ucla_3, perma, personality_styles)

---

## Implementation Order

1. **types.ts** - Add interfaces (no dependencies)
2. **data.ts** - Add test definitions (no dependencies)
3. **scoring.ts** - Add scoring logic (depends on 1, 2)
4. **wizard-sections.ts** - Add section config (no dependencies)
5. **Wizard.tsx** - Add tests to flow (depends on 2, 4)
6. **AutismScreeningDisplay.tsx** - Create visualization (depends on 1)
7. **Visualizations.tsx** - Export component (depends on 6)
8. **Dashboard.tsx** - Integrate visualization (depends on 6, 7)
9. **compassionate-framing.ts** - Add framing content (no dependencies)
10. **treatment-recommendations.ts** - Add support options (no dependencies)
11. **prompts.ts** - Update AI context (no dependencies)
12. **LandingHero.tsx** - Update marketing (no dependencies)
13. **example_profile.json** - Update sample data (depends on 1)
14. **Demo account** - Update via API/database (depends on 1)

---

## Clinical References

**AQ-10**:
- Baron-Cohen et al. (2001), Allison et al. (2012)
- Clinical cutoff: ≥6 suggests autism likely
- General population mean: ~2.0 (SD 1.9)

**CAT-Q**:
- Hull et al. (2019)
- Autistic adults mean: ~116 (SD 23)
- Non-autistic mean: ~91 (SD 25)
- High camouflaging threshold: ~124

**Sensory Processing**:
- Informed by Adolescent/Adult Sensory Profile (Brown & Dunn, 2002)
- Custom thresholds based on clinical observation

---

## Key Design Decisions

1. **Neurodiversity-affirming language** throughout - autism as difference, not deficit
2. **Masking detection critical** - CAT-Q catches autism missed by AQ-10 alone (especially in women/late-diagnosed)
3. **Sensory processing separate** - Useful standalone insight even without autism flag
4. **Exhaustion indicator** - CAT-Q item 17 specifically flagged for burnout risk
5. **Avoid pathologizing** - "Autistic neurotype" not "Autism Spectrum Disorder"
6. **Late-discovery validation** - Explicit content for adults discovering autism later in life

---

## POST-IMPLEMENTATION AUDIT - GAPS FOUND

### Critical Gaps (Blocking)

#### 1. AutismScreeningDisplay Not Exported from Visualizations.tsx
**Issue**: Dashboard imports from `./Visualizations` (monolithic file) but AutismScreeningDisplay was only added to `./visualizations/index.ts` (folder)
**File**: `~/Deep-Personality/components/Visualizations.tsx`
**Fix**: Add re-export at end of file:
```typescript
// Re-export from extracted components
export { AutismScreeningDisplay } from './visualizations/AutismScreeningDisplay';
```

#### 2. TypeScript Error in AutismScreeningDisplay
**Issue**: Parameter 's' implicitly has 'any' type (line 393)
**File**: `~/Deep-Personality/components/visualizations/AutismScreeningDisplay.tsx`
**Fix**: Add explicit type annotation to the parameter

### Integration Gaps (Not Blocking but Incomplete)

#### 3. SCORING_CONTEXT Not Used in Main Analyze Route
**Issue**: `/app/api/analyze/route.ts` imports SCORING_CONTEXT but never uses it in the prompts
**Note**: `/app/api/analyze-parallel/route.ts` DOES use it correctly
**Files**: `~/Deep-Personality/app/api/analyze/route.ts`
**Impact**: Main analyze route's AI prompts don't include autism scoring guidance

#### 4. CLINICAL_SECTION_TEMPLATES Never Used
**Issue**: Detailed autism section template in prompts.ts is exported but never imported anywhere
**File**: `~/Deep-Personality/services/analyze/prompts.ts` (defined), no consumers
**Impact**: AI doesn't get the rich autism analysis template

#### 5. compassionate-framing.ts Never Used
**Issue**: AUTISM_FRAMING, MASKING_FRAMING, SENSORY_FRAMING defined but never imported/rendered
**Files**:
  - `~/Deep-Personality/lib/compassionate-framing.ts` (defined)
  - No import anywhere in app
**Impact**: Neurodiversity-affirming framing not shown to users

#### 6. treatment-recommendations.ts Never Used
**Issue**: AUTISM_SUPPORT treatment recommendations defined but never imported/rendered
**Files**:
  - `~/Deep-Personality/lib/treatment-recommendations.ts` (defined)
  - No import anywhere in app
**Impact**: Autism support recommendations not shown to users

### Lower Priority Gaps

#### 7. Email Notification Doesn't Highlight Autism Data
**Issue**: `/app/api/complete/route.ts` sends profile as attachment but AI prompt doesn't mention autism assessments
**Impact**: Admin email doesn't specifically flag autism screening results (low priority - data is in attachment)

#### 8. Main Analyze Route Missing Autism in Inline Scoring Context
**Issue**: The hardcoded scoring context in `/app/api/analyze/route.ts` doesn't include AQ-10, CAT-Q, sensory processing
**Lines**: ~147-165 in route.ts
**Impact**: AI doesn't know how to interpret autism scores in main route

---

## FIX IMPLEMENTATION ORDER

### Phase 1: Critical Fixes (Must Do)
1. **Visualizations.tsx** - Add AutismScreeningDisplay re-export
2. **AutismScreeningDisplay.tsx** - Fix TypeScript 'any' error

### Phase 2: AI Integration Fixes
3. **analyze/route.ts** - Add SCORING_CONTEXT usage (or update inline context)
4. **analyze/route.ts** - Import and use CLINICAL_SECTION_TEMPLATES

### Phase 3: UI Rendering (Optional but Recommended)
5. Create component or section in Dashboard to render:
   - compassionate-framing content for relevant conditions
   - treatment-recommendations for flagged conditions

   Or integrate into the AI-generated analysis

---

## Files Requiring Changes

| File | Issue | Priority |
|------|-------|----------|
| `components/Visualizations.tsx` | Missing AutismScreeningDisplay export | CRITICAL |
| `components/visualizations/AutismScreeningDisplay.tsx` | TypeScript 'any' error | CRITICAL |
| `app/api/analyze/route.ts` | Missing SCORING_CONTEXT usage | HIGH |
| `app/api/analyze/route.ts` | Missing autism in inline context | HIGH |
| `lib/compassionate-framing.ts` | Never imported/used | MEDIUM |
| `lib/treatment-recommendations.ts` | Never imported/used | MEDIUM |
| `app/api/complete/route.ts` | No autism highlight in email | LOW |
