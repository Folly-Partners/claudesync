# Deep Personality: Clinical Psychology Ethics Review

## Executive Summary

A comprehensive review of the Deep Personality codebase from a clinical psychology perspective. Issues are ranked by severity using a traffic light system based on what would concern or outrage a licensed psychologist.

---

## RED - Critical Issues (Would Outrage a Psychologist)

### 1. AI Making Treatment Recommendations
**Files:** `services/analyze/prompts.ts` lines 306-378
**The Problem:**
- AI explicitly recommends **specific psychiatric medications** by name: "Adderall, Ritalin, Vyvanse"
- States stimulants are "NOT addictive when used as prescribed" (oversimplification)
- Recommends "70-80% response rate" for stimulant medication
- Suggests antidepressants, therapy modalities based on screening scores

**Why This Is Outrageous:**
- No medical history review, contraindication screening, or monitoring capability
- Practicing medicine without a license
- Could cause serious harm if user takes this as medical advice

---

### 2. Inadequate Suicidal Ideation Protocol
**Files:** `services/analyze/prompts.ts` line 482, `types/profile.ts` line 115
**The Problem:**
- PHQ-9 item #9 alone triggers "suicidalIdeationFlag"
- Response is only: "If you're experiencing suicidal thoughts, reach out now: 988"
- No risk stratification (passive ideation vs. active intent vs. imminent risk)
- No follow-up protocol, no contact collection, no professional escalation
- 988 is US-only (app serves US/Canada)

**Why This Is Outrageous:**
- Conflates passive death wishes with active suicidality
- No validated risk assessment (Columbia-SSRS or similar)
- Could miss someone in genuine crisis or over-alarm someone with fleeting thoughts
- No audit trail or professional notification system

---

### 3. HCP Composite Index - Clinically Invalid
**Files:** `services/scoring.ts` lines 261-337
**The Problem:**
- Custom formula: 30% Cluster B + 25% Dark Triad + 15% Low Agreeableness + 15% High Neuroticism + 15% HCP Core
- **No published validation** of this weighting
- **Mathematical error:** Divides percentile (0-100) by 20 to get "1-5 scale" - this is arbitrary rescaling
- Threshold 3.5 for "High Conflict Personality indicators present" is arbitrary
- Bill Eddy's HCP framework is from legal/mediation literature, not validated psychology

**Why This Is Outrageous:**
- Labeling someone as "High Conflict Personality" based on an unvalidated composite
- Could be used against people in custody disputes, employment, relationships
- No sensitivity/specificity data - unknown false positive rate

---

### 4. Clinical Screening Tools Used as Diagnostic Instruments
**Files:** `types/profile.ts`, `services/analyze/prompts.ts` lines 35-127
**The Problem:**
- PHQ-9, GAD-7, PCL-5, ASRS-18, AQ-10, RAADS-14 are **screening tools**
- App generates automated "flags" based on clinical thresholds
- AI then makes clinical interpretations: "Your depression is moderate..."
- No differential diagnosis capability
- No context for medications, medical conditions, life circumstances

**Why This Is Outrageous:**
- Screening tools are designed to prompt referral, not replace clinical assessment
- AI cannot conduct clinical interview or rule out other conditions
- Users may believe they have conditions they don't have (or miss ones they do)

---

### 5. Personality Disorder Language Without Adequate Safeguards
**Files:** `services/analyze/prompts.ts` lines 1293-1332
**The Problem:**
- When Cluster B ≥3.5, AI generates sections labeled:
  - "Borderline" personality pattern
  - "Narcissistic" personality pattern
  - "Antisocial" personality pattern
- Recommends books like "Stop Walking on Eggshells" (frames person as problem)
- Uses DSM-5 cluster framework with clinical certainty

**Why This Is Outrageous:**
- 5-item cluster scale ≠ personality disorder assessment
- Could devastate relationships if shared
- High Openness + ADHD or trauma responses can mimic these patterns
- No safeguard preventing misuse against someone

---

## YELLOW - Significant Concerns (Would Concern a Psychologist)

### 6. Dark Triad Assessment Hidden/Consent Issues
**Files:** `services/data.ts` lines 17-94, `services/scoring.ts` lines 186-215
**The Problem:**
- 12 Dark Triad items are embedded within IPIP-50 and Personality Styles
- Users don't know they're being assessed for Machiavellianism, Narcissism, Psychopathy
- Data is stripped from AI analysis BUT kept in downloadable JSON
- Could be shared with partners/employers without understanding implications

**Concern Level:**
- Informed consent issue - users should know what they're being assessed for
- Downloaded profiles contain stigmatizing labels without context

---

### 7. Dark Triad Presentation - Stigmatizing Language
**Files:** `app/share/[code]/page.tsx`, `components/Dashboard.tsx` lines 4284-4339
**The Problem:**
- Current descriptions use stigmatizing clinical language:
  - "Strategic manipulation, cynicism" (Machiavellianism)
  - "Grandiosity, need for admiration" (Narcissism)
  - "Low empathy, impulsivity" (Psychopathy)
- Red warning icons imply danger/pathology
- No strengths framing (unlike ADHD/Autism sections which do this well)

**Concern Level:**
- Could cause shame, relationship damage, psychological harm
- Inconsistent with neurodiversity-affirming approach used elsewhere

---

### 8. Scale Adaptations Without Revalidation
**Files:** `services/scoring.ts` throughout
**The Problem:**
| Scale | Original | Adapted | Issue |
|-------|----------|---------|-------|
| ECR-S | 1-7 Likert | 1-5 Likert | Threshold 3.2 not validated |
| CAT-Q | 7-point | 5-point | Norms recalibrated, not revalidated |
| SWLS | 1-7 | 1-5 | Linear adjustment assumption |
| RSQ | 7-point | 1-5 | No validation |
| PERMA | 0-10 | 1-5 | Acknowledged but still used clinically |

**Concern Level:**
- Scale adaptations may change psychometric properties
- Thresholds derived from original scales may not apply
- Good: Developer acknowledged limitations in comments

---

### 9. Autism Screening Tool Stacking
**Files:** `services/scoring.ts` lines 806-963
**The Problem:**
- Uses THREE tools: AQ-10 → RAADS-14 → CAT-Q
- CAT-Q is designed for people ALREADY diagnosed, not as screening
- High CAT-Q can trigger autism discussion even with low AQ-10
- Social anxiety, trauma, ADHD can all elevate CAT-Q scores

**Concern Level:**
- False positive risk for people with other conditions
- Tool misuse (CAT-Q validity reversed when used for screening)
- Could lead to unnecessary diagnosis-seeking or identity confusion

---

### 10. Comparison Reports Share Clinical Data
**Files:** `services/analyze/prompts.ts` lines 1338-1392
**The Problem:**
- When analyzing couples, both people's clinical flags are discussed
- Person A's anxiety/depression/trauma disclosed to Person B
- No explicit consent for this disclosure
- Could enable emotional manipulation: "The test says you're borderline"

**Concern Level:**
- Privacy violation between partners
- Potential for relationship harm
- No power dynamics consideration

---

### 11. Custom Thresholds Without Clinical Justification
**Files:** `services/scoring.ts` various
**The Problem:**
| Assessment | Threshold | Source |
|------------|-----------|--------|
| Sensory Processing | Visual ≥7/10 | "Custom thresholds based on clinical observation" |
| Compulsive Behaviors | Substance ≥2/4, Internet ≥3/4 | No justification for difference |
| DERS-16 subscale | >3.5 | Comment: "Arbitrary threshold for High" |
| HCP Index | 3.5 | No sensitivity/specificity data |

**Concern Level:**
- Thresholds determine who gets flagged/labeled
- Without validation, unknown error rates
- Developer acknowledged some are arbitrary

---

### 12. No Affirmative Informed Consent Flow
**Files:** `components/Wizard.tsx`
**The Problem:**
- Users can start assessment immediately without:
  - Confirming they're 18+
  - Understanding screening vs. diagnosis distinction
  - Consenting to clinical assessments specifically
  - Warning before suicidal ideation question
  - Consent before Dark Triad assessment

**Concern Level:**
- Terms exist but aren't actively consented to
- No age verification mechanism
- Clinical assessments deserve explicit consent

---

## GREEN - Good Practices (Psychologist Would Approve)

### 13. ADHD Presentation - Neurodiversity-Affirming
**File:** `components/visualizations/ADHDGauges.tsx`
- Clear "This is a Screening, Not a Diagnosis" header
- "ADHD Superpowers" section positions traits as strengths
- Explains ASRS-18 validation, emphasizes professional evaluation
- Excellent model for other sections

### 14. Autism Presentation - Contemporary Approach
**File:** `components/visualizations/AutismScreeningDisplay.tsx`
- Uses non-pathologizing colors (purple, not red)
- "Neurotypical Range" presented neutrally
- "Autistic Strengths" section
- "It's not a disorder to be fixed but a difference to be understood"

### 15. HCP Pattern Reframing
**File:** `components/visualizations/HCPDisplay.tsx`
- Cluster A: "Independent & Unconventional" (not Paranoid/Schizoid)
- Cluster B: "Expressive & Passionate" (not Dramatic/Emotional)
- Cluster C: "Cautious & Thoughtful" (not Anxious/Avoidant)
- Each includes Strengths, Challenges, Growth Strategies

### 16. Dark Triad Stripped from AI Analysis
**File:** `services/analyze/helpers.ts` lines 34-56
- Dark Triad data removed before sending to AI
- Good safeguard preventing AI clinical interpretation
- Comment: "will be reviewed by a psychologist in person"

### 17. Validated Scoring for Core Instruments
**File:** `services/scoring.ts`
- IPIP-50: Proper z-score conversion with N>300K norms
- GAD-7/PHQ-9/PCL-5: Published clinical thresholds used correctly
- SD3 Dark Triad: Uses Jones & Paulhus (2014) norms
- ISI Insomnia: Validated thresholds from Morin et al. (2011)

### 18. Comprehensive Terms of Service Disclaimers
**File:** `app/terms/page.tsx`
- "Results are NOT diagnoses" clearly stated
- "High scores do not indicate a personality disorder"
- "Educational and informational purposes only"
- Professional consultation recommended

### 19. Mental Health Screening Disclaimers
**File:** `components/visualizations/MentalHealthGauges.tsx`
- "These are screening tools, not diagnostic instruments"
- Encouragement messages calibrated to score severity
- Clear that scores are personal/sensitive

---

## Clinical Validity Summary

| Category | Assessment | Validity |
|----------|------------|----------|
| **Valid** | IPIP-50, GAD-7, PHQ-9, PCL-5, ISI, ACE, SD3 | Proper scoring with published norms |
| **Adapted** | ECR-S, SWLS, PERMA, RSQ, CAT-Q | Functional but not revalidated |
| **Problematic** | HCP Composite, Sensory Processing, Compulsive Behaviors | Custom/unvalidated |
| **Misused** | CAT-Q (used as screener), Clinical tools (used diagnostically) | Validity structure violated |

---

## Implementation Plan

### 1. AI Treatment Recommendations → Add Disclaimers
**File:** `services/analyze/prompts.ts`
**Solution:** Keep treatment information but frame as informational:
- Add header: "Treatment Options to Discuss with Your Doctor"
- Add disclaimer: "The following information is educational only. Always consult a licensed healthcare provider before starting any treatment."
- Keep medication names but add: "Ask your doctor if [medication type] might be appropriate for you"
- Add footer: "Only a qualified professional can diagnose and recommend treatment"

### 2. Suicide Risk Protocol → Improve Response
**File:** `services/analyze/prompts.ts`
**Solution:**
- Keep PHQ-9 item #9 detection
- Add tiered response based on score level (1-2 vs 3):
  - Score 1-2: "If you're having difficult thoughts, talking to a therapist can help. Consider reaching out to a mental health professional."
  - Score 3: Current crisis resources + "Please reach out today"
- Add Canadian crisis line: 1-833-456-4566
- Add Crisis Text Line: Text HOME to 741741
- Keep 988 for US

### 3. HCP Composite → Add Strong Caveats
**File:** `services/scoring.ts`, `components/visualizations/HCPDisplay.tsx`
**Solution:**
- Keep the composite but add prominent disclaimer
- Change label from "High Conflict Personality indicators present" to "Patterns that may benefit from professional exploration"
- Add explanation: "This score combines multiple screening measures to identify interpersonal patterns. It is not a validated diagnostic tool and should be interpreted with a qualified professional."
- In visualization, add info tooltip explaining the composite is exploratory

### 4. Clinical Screening Tools → Strengthen Disclaimers
**Files:** `services/analyze/prompts.ts`, visualization components
**Solution:** Keep all tests but add consistent framing:
- Every clinical section header gets: "Screening Result" badge (not "Assessment" or "Diagnosis")
- Add to AI prompt template: "Always clarify that [PHQ-9/GAD-7/etc.] is a screening tool that suggests further professional evaluation, not a diagnosis"
- In visualizations, add: "This screening suggests you may benefit from discussing [condition] with a mental health professional"

### 5. Personality Disorder Labels → Soften Language
**File:** `services/analyze/prompts.ts` lines 1293-1332
**Solution:**
- Change "Borderline personality pattern" → "Emotional intensity patterns"
- Change "Narcissistic personality pattern" → "Self-confidence patterns"
- Change "Antisocial personality pattern" → "Independence patterns"
- Add context: "These patterns often develop as adaptive responses to life experiences and can be explored productively with a therapist"
- Remove "Stop Walking on Eggshells" recommendation (stigmatizing)

### 6. Dark Triad Hidden → Leave as is ✓

### 7. Dark Triad Presentation → Leave as is ✓
**ALSO:** Remove Dark Triad stripping from AI analysis
**File:** `services/analyze/helpers.ts` lines 34-56
- Delete/comment out the code that removes dark_triad from profile before AI analysis
- AI will now be able to interpret Dark Triad scores in context

### 8. Scale Adaptations → Document Better
**File:** `services/scoring.ts`
**Solution:** Add comment blocks explaining each adaptation:
```typescript
// SCALE ADAPTATION: Original ECR-S uses 1-7 Likert
// Adapted to 1-5 for consistency across assessment battery
// Threshold 3.2 represents midpoint+0.2 to identify "above average" anxiety/avoidance
// Note: This adaptation has not been independently validated
```
- Add similar documentation for SWLS, RSQ, PERMA, CAT-Q
- No functional changes, just transparency

### 9. CAT-Q/Autism Screening → Add Disclaimers
**File:** `components/visualizations/AutismScreeningDisplay.tsx`
**Solution:** Add context disclaimer:
- "The CAT-Q measures social camouflaging behaviors. High scores can occur in autism, ADHD, social anxiety, or as a response to social pressure. A high score suggests discussing these patterns with a specialist."
- Keep multi-tool approach but frame as "comprehensive screening" that prompts professional evaluation

### 10. Comparison Reports → Add Disclosure Notice
**File:** `services/analyze/prompts.ts` comparison section
**Solution:** Add to comparison report template:
- Header: "This comparison includes personal assessment results for both partners"
- Add: "By viewing this report together, you're sharing sensitive information about your psychological patterns. Use this information with care and compassion."
- Consider adding: "Some findings may be sensitive. Consider whether you want to discuss specific sections with a therapist present."

### 11. Custom Thresholds → Frame as Exploratory
**File:** `services/scoring.ts`, relevant visualizations
**Solution:** For sensory/compulsive/other custom thresholds:
- Add comments documenting they are "exploratory thresholds designed to prompt professional consultation"
- In visualizations, avoid definitive language like "You have high sensory sensitivity"
- Use: "Your responses suggest sensory patterns worth exploring with an occupational therapist or neuropsychologist"

### 12. Informed Consent Flow → Add Pre-Assessment Screen
**File:** `components/Wizard.tsx` (or new `components/ConsentScreen.tsx`)
**Solution:** Add consent screen before assessment starts:
```
Before You Begin:

☐ I confirm I am 18 years or older

☐ I understand this is a screening tool, not a clinical diagnosis.
   Results suggest areas to explore with qualified professionals.

☐ I consent to complete psychological assessments including
   personality, mental health screening, and interpersonal patterns.

[Continue to Assessment]
```
- Must check all boxes to proceed
- Store consent timestamp in profile

---

## Files Requiring Changes

| Priority | File | Changes |
|----------|------|---------|
| 1 | `services/analyze/helpers.ts` | Remove Dark Triad stripping (lines 34-56) |
| 2 | `services/analyze/prompts.ts` | Add treatment disclaimers, improve suicide response, soften personality labels |
| 3 | `components/Wizard.tsx` | Add consent screen |
| 4 | `services/scoring.ts` | Add documentation comments for adaptations and thresholds |
| 5 | `components/visualizations/HCPDisplay.tsx` | Add composite disclaimer |
| 6 | `components/visualizations/AutismScreeningDisplay.tsx` | Add CAT-Q context disclaimer |
| 7 | Comparison report template in prompts.ts | Add disclosure notice |
