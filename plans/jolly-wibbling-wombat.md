# Deep Personality Assessment Flow Review - FINAL PLAN

## User Decisions
- **Add all three missing wellbeing scales**: Yes (SWLS, UCLA_3, PERMA)
- **Reorder scope**: Full reorder with buffers

---

## New Assessment Order

| Step | Scale ID | Name | Items | Rationale |
|------|----------|------|-------|-----------|
| 0 | intro | Welcome | - | |
| 1 | demographics | The Basics | 6 | |
| **PERSONALITY FOUNDATION** |
| 2 | ipip_50 | Personality Architecture | 68 | Start with familiar Big Five |
| 3 | personality_styles | Personality Styles | 25 | Clusters A/B/C |
| **RELATIONSHIPS & ATTACHMENT** |
| 4 | ecr_s | Attachment Style | 12 | |
| 5 | csi_16 | Relationship Dynamics | 16 | |
| **EMOTIONAL PROCESSING** |
| 6 | ders_16 | Emotional Regulation | 16 | |
| 7 | scs_sf | Self-Compassion | 12 | **MOVED UP** - buffer before clinical |
| **WELLBEING CHECK (buffer before clinical)** |
| 8 | swls | Life Satisfaction | 5 | **NEW** - positive buffer |
| 9 | perma | Wellbeing Profile | 23 | **NEW** - comprehensive wellbeing |
| **CLINICAL - ANXIETY/DEPRESSION** |
| 10 | gad_7 | Anxiety Patterns | 7 | Lighter clinical first |
| 11 | phq_9 | Mood Patterns | 9 | Depression screening |
| **NEURODEVELOPMENTAL (buffer)** |
| 12 | asrs_18 | Attention & Focus | 18 | **MOVED** - buffer between mood/trauma |
| **CLINICAL - TRAUMA** |
| 13 | ace | Early Life Experiences | 10 | Childhood trauma |
| 14 | pcl_5 | Stress Response Patterns | 20 | PTSD symptoms |
| 15 | dts | Emotional Resilience | 15 | Distress tolerance |
| **SOCIAL & CONNECTION** |
| 16 | rsq | Social Sensitivity | 18 | Rejection sensitivity |
| 17 | ucla_3 | Social Connection | 3 | **NEW** - loneliness |
| **POSITIVE/ACTIONABLE ENDING** |
| 18 | onet_mini | Career & Interests | 30 | |
| 19 | pvq_21 | Core Values | 21 | |
| 20 | weims | Motivation Source | 18 | |
| 21-24 | multichoice | Conflict, Needs, Work, Values | 10 | |
| 25 | results | Profile Complete | - | |

**Total new items**: +31 (SWLS: 5, PERMA: 23, UCLA_3: 3)
**New total assessment time**: ~55-60 minutes

---

## Implementation Steps

### 1. Update imports in Wizard.tsx (line 4)

Add `SWLS, UCLA_3, PERMA` to the import statement from `../services/data`.

### 2. Add SECTION_META entries (lines 22-119)

Add metadata for the three new scales:

```typescript
'swls': {
  icon: Star,
  timeEstimate: '~1 min',
  insight: 'Assess your overall life satisfaction',
  color: 'emerald'
},
'ucla_3': {
  icon: Users,
  timeEstimate: '~1 min',
  insight: 'Understand your sense of social connection',
  color: 'indigo'
},
'perma': {
  icon: Sparkles,
  timeEstimate: '~4 min',
  insight: 'Map your wellbeing across five key dimensions',
  color: 'violet'
}
```

### 3. Replace steps array (lines 828-851)

```typescript
const steps = useMemo(() => [
  { type: 'intro', id: 'welcome' },
  { type: 'basic', id: 'demographics' },
  // PERSONALITY FOUNDATION
  { type: 'test', data: IPIP_50 },
  { type: 'test', data: PERSONALITY_STYLES },
  // RELATIONSHIPS & ATTACHMENT
  { type: 'test', data: ECR_S },
  { type: 'test', data: CSI_16 },
  // EMOTIONAL PROCESSING
  { type: 'test', data: DERS_16 },
  { type: 'test', data: SCS_SF },        // MOVED UP - buffer
  // WELLBEING CHECK (buffer before clinical)
  { type: 'test', data: SWLS },          // NEW
  { type: 'test', data: PERMA },         // NEW
  // CLINICAL - ANXIETY/DEPRESSION
  { type: 'test', data: GAD_7 },
  { type: 'test', data: PHQ_9 },
  // NEURODEVELOPMENTAL (buffer)
  { type: 'test', data: ASRS_18 },       // MOVED - buffer before trauma
  // CLINICAL - TRAUMA
  { type: 'test', data: ACE },
  { type: 'test', data: PCL_5 },
  { type: 'test', data: DTS },
  // SOCIAL & CONNECTION
  { type: 'test', data: RSQ },
  { type: 'test', data: UCLA_3 },        // NEW
  // POSITIVE/ACTIONABLE ENDING
  { type: 'test', data: ONET_MINI },
  { type: 'test', data: PVQ_21 },
  { type: 'test', data: WEIMS },
  ...MULTIPLE_CHOICE_SECTIONS.map(s => ({ type: 'multichoice', data: s })),
  { type: 'finish', id: 'results' }
], []);
```

---

## Files to Modify

| File | Changes |
|------|---------|
| `/components/Wizard.tsx` | 1. Add imports for SWLS, UCLA_3, PERMA (line 4)<br>2. Add SECTION_META entries (after line 118)<br>3. Replace steps array (lines 828-851) |

**No changes needed to**:
- `/services/data.ts` - Scales already defined with all items
- `/services/scoring.ts` - Scoring logic already implemented (lines 426-497, 609-615)
- `/types.ts` - `IndividualProfile.assessments` already includes `swls`, `ucla_3`, `perma` types (lines 148-173)
- `/app/api/analyze/route.ts` - AI prompt already includes scoring context for SWLS, UCLA_3, PERMA (lines 206-208) and wellbeing section (lines 592-620)
- `/app/api/complete/route.ts` - Database save uses `profile.assessments` which includes all scales

---

## Data Flow Verification (CONFIRMED)

| Step | Component | Status |
|------|-----------|--------|
| 1. Questions displayed | Wizard.tsx steps array | **NEEDS UPDATE** |
| 2. Answers collected | Wizard.tsx `answers` state | Works automatically |
| 3. Profile scored | scoring.ts `generateProfile()` | Already implemented |
| 4. JSON export | Profile download | Already includes all assessments |
| 5. AI analysis | analyze/route.ts prompt | Already references SWLS, UCLA_3, PERMA |
| 6. Database storage | complete/route.ts | Already saves full `assessments` object |

The only change needed is adding the scales to the Wizard steps array and SECTION_META.

---

## Dark Triad Embedding (UNCHANGED)

The 18 Dark Triad items remain sprinkled throughout the first two assessment sections:

| Assessment | Dark Triad Items | Position |
|------------|------------------|----------|
| IPIP_50 (Step 2) | DT_M1-M4, DT_P1-P4, DT_N1-N4 | Mixed with Big Five items |
| PERSONALITY_STYLES (Step 3) | DT_M5-M6, DT_P5-P6, DT_N5-N6 | Mixed with Cluster items |

All 18 items are marked `domain: 'hidden'` or `subscale: 'hidden'` - they appear as normal personality questions but score separately for Dark Triad. Since IPIP_50 and PERSONALITY_STYLES remain at Steps 2-3 in the new order, this covert assessment is preserved.

---

## Clinical Flow Improvements

| Issue | Solution |
|-------|----------|
| Heavy trauma block (5 consecutive) | Split into mood (GAD-7, PHQ-9) and trauma (ACE, PCL-5, DTS) with ADHD buffer |
| PHQ-9 → ACE jarring transition | ASRS-18 now provides neutral buffer between them |
| Missing wellbeing data | Added SWLS, PERMA, UCLA_3 |
| Self-Compassion too late | Moved SCS_SF before clinical as buffer |
| Ends on clinical content | Now ends with career/values (positive/actionable) |
