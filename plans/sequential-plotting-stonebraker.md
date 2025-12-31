# Add Missing Assessments to Therapist PDF

## Goal

Ensure ALL assessment results are included in the clinical therapist PDF export, including Dark Triad and 16 other missing assessments.

## Current State

The `buildSimpleTherapistDocument()` function in `lib/pdf-report-builder.ts` currently includes **15 assessments** but the app supports **32 assessments**.

### Currently Included (15)
- PHQ-9, GAD-7, PCL-5, ACE (clinical)
- DERS, DTS-SF, SCS-SF (emotion regulation)
- IPIP-50 (personality)
- ECR-S (attachment)
- PERMA, SWLS, UCLA-3 (wellbeing)
- ASRS-18, AQ-10 (neurodevelopmental)
- PVQ-21 (values - listed only, no dedicated section)

### Missing (17)
| Assessment | Domain | Key |
|------------|--------|-----|
| **Dark Triad (SD3)** | Personality | `dark_triad` |
| Personality Styles | Personality | `personality_styles` |
| HPD indicators | Personality | `hpd` |
| BPD indicators | Personality | `bpd` |
| HCP Core/Extended | Personality | `hcp` |
| CSI-16 | Relationship | `csi_16` |
| RSQ | Relationship | `rsq` |
| RIASEC | Career | `riasec` |
| WEIMS | Career | `weims` |
| RAADS-14 | Neurodevelopmental | `raads_14` |
| CAT-Q | Neurodevelopmental | `cat_q` |
| Sensory Processing | Neurodevelopmental | `sensory` |
| Compulsive Behaviors | Behavioral | `compulsive` |
| ISI (Insomnia) | Physical | `isi` |
| Godin (Exercise) | Physical | `godin` |
| Physical Health | Physical | `physical_health` |

---

## Files to Modify

| File | Changes |
|------|---------|
| `lib/pdf-report-builder.ts` | Add section builders for missing assessments |

---

## Implementation Steps

### Step 1: Add Dark Triad Section

Add `buildDarkTriadSection()` after personality section:
```typescript
function buildDarkTriadSection(a: ProfileData['assessments']): string {
  if (!a?.dark_triad) return '';
  const { machiavellianism, narcissism, psychopathy } = a.dark_triad;
  // Table with trait, score, percentile, interpretation
}
```

### Step 2: Add Personality Patterns Section

Add `buildPersonalityPatternsSection()` for cluster styles, HPD, BPD, HCP:
```typescript
function buildPersonalityPatternsSection(a: ProfileData['assessments']): string {
  // Combine: personality_styles, hpd, bpd, hcp
  // Use cautious clinical language - these are screening indicators only
}
```

### Step 3: Add Relationship Section

Add `buildRelationshipSection()` for CSI-16, RSQ:
```typescript
function buildRelationshipSection(a: ProfileData['assessments']): string {
  // CSI-16: relationship satisfaction score
  // RSQ: rejection sensitivity with interpretation
}
```

### Step 4: Add Career/Values Section

Add `buildCareerValuesSection()` for RIASEC, WEIMS, and enhance PVQ-21:
```typescript
function buildCareerValuesSection(a: ProfileData['assessments']): string {
  // RIASEC: top 3 interest codes
  // WEIMS: motivation style profile
  // PVQ-21: ranked values (already listed, add interpretation)
}
```

### Step 5: Enhance Neurodevelopmental Section

Update `buildScreeningSection()` to include RAADS-14, CAT-Q, Sensory:
```typescript
// Add to existing section:
// - RAADS-14: autism diagnostic scale (if administered)
// - CAT-Q: camouflaging score with subscales
// - Sensory Processing: over/under-responsive patterns
```

### Step 6: Add Behavioral Health Section

Add `buildBehavioralHealthSection()` for compulsive behaviors:
```typescript
function buildBehavioralHealthSection(a: ProfileData['assessments']): string {
  // Substance, gambling, internet/gaming, eating patterns
  // Clinical flags for elevated scores
}
```

### Step 7: Add Physical Health Section

Add `buildPhysicalHealthSection()` for ISI, Godin, physical patterns:
```typescript
function buildPhysicalHealthSection(a: ProfileData['assessments']): string {
  // ISI: insomnia severity
  // Godin: exercise frequency and activity level
  // Physical Health: sleep, energy, nutrition patterns
}
```

### Step 8: Update Instruments List

Update `buildInstrumentsAdministered()` to dynamically list all administered assessments.

### Step 9: Update Clinical Summary

Update `buildClinicalSummarySection()` to reference new assessment domains in the narrative synthesis.

---

## Section Order in Final Report

1. Header (client info, dates)
2. Instruments Administered
3. **Clinical Mental Health** (PHQ-9, GAD-7, PCL-5, ACE)
4. **Emotion Regulation** (DERS, DTS, SCS)
5. **Personality - Big Five** (IPIP-50)
6. **Personality - Dark Triad** (SD3) ← NEW
7. **Personality Patterns** (Clusters, HPD, BPD, HCP) ← NEW
8. **Attachment** (ECR-S)
9. **Relationships** (CSI-16, RSQ) ← NEW
10. **Wellbeing** (PERMA, SWLS, UCLA-3)
11. **Values & Career** (PVQ-21, RIASEC, WEIMS) ← NEW
12. **Neurodevelopmental** (ASRS-18, AQ-10, RAADS-14, CAT-Q, Sensory) ← ENHANCED
13. **Behavioral Health** (Compulsive Behaviors) ← NEW
14. **Physical Health** (ISI, Godin, patterns) ← NEW
15. Summary of Findings
16. Limitations
17. Footer

---

## Interpretation Guidelines

### Dark Triad
- Report percentile estimates for each trait
- Use neutral language: "elevated" not "high"
- Note these are normal personality variations unless extreme

### Personality Patterns (Clusters/HPD/BPD/HCP)
- Frame as "patterns consistent with..." not diagnoses
- Include disclaimer about screening nature
- Only report if scores warrant mention

### Conditional Assessments
- RAADS-14: Only shown if AQ-10 ≥ 4
- HCP Extended: Only if HCP Core flags
- Report "not administered" if conditional not triggered
