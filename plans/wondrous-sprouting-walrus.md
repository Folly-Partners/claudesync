# Plan: Personality-Adaptive Delivery for Deep Personality Reports

## Problem Statement

The current Deep Personality report system delivers difficult findings with a one-size-fits-all "unflinching honesty" approach. While some psychological sensitivity exists (clinical hedging, Gifts & Challenges tables), the system doesn't adapt its delivery based on **how the specific recipient's personality profile will receive the information**.

From psychological analysis of the demo profile, key issues include:
- **Deficit framing** that can trigger shame ("lacks tools", "organizationally scattered")
- **No anticipation of defensive patterns** based on attachment style, neuroticism, values
- **No pre-emptive validation** of protective patterns before naming growth edges
- **Gap between potential and current state** presented without compassion for that tension

## Goal

Create a **Delivery Calibration System** that:
1. Analyzes the recipient's profile to predict defensive patterns
2. Generates personality-adaptive language instructions
3. Pre-emptively validates protective patterns before delivering hard truths
4. Helps difficult findings "land" so people can move to action rather than shut down

---

## Current System Architecture

### Files to Modify

| File | Purpose | Changes Needed |
|------|---------|----------------|
| `services/analyze/prompts.ts` | All prompt constants | Add delivery calibration prompt, modify SYSTEM_PROMPT, reframe deficit language |
| `services/analyze/core-model.ts` | Prevents repetition, generates summaries | Add defensive pattern prediction to core model |
| `services/analyze/helpers.ts` | Clinical detection | Add defensive pattern detection function |
| `app/api/analyze-parallel/route.ts` | Orchestration | Include delivery calibration in chunk generation |

### Current Strengths to Preserve
- Clinical hedging language ("potential", "likely")
- Gifts & Challenges balance tables
- Ownership matrix (prevents re-traumatizing through repetition)
- Neurodivergence-affirming framing
- Dark Triad language softening

---

## Proposed Architecture

### 1. New: Defensive Pattern Prediction

Add a function that analyzes the profile and returns expected defensive patterns:

```typescript
interface DefensivePatterns {
  primaryDefenses: string[];  // e.g., ["intellectualization", "avoidance", "minimization"]
  triggerTopics: string[];    // e.g., ["attachment findings", "ACE implications", "underachievement gap"]
  framingNeeds: {
    needsAutonomy: boolean;      // For Self-Direction values, avoidant attachment
    needsValidation: boolean;    // For high neuroticism, anxious attachment
    needsLogicalFraming: boolean; // For low agreeableness, high openness
    needsHopeBalance: boolean;   // For depression indicators, low SWLS
  };
  validationPhrases: string[];   // Pre-emptive phrases specific to this profile
}
```

### 2. New: Delivery Calibration Prompt

Add `DELIVERY_CALIBRATION_PROMPT` to prompts.ts that instructs the AI to:

**Before delivering ANY difficult finding:**
1. Acknowledge what the pattern protected them from
2. Validate why it made sense given their history
3. THEN name the cost/growth edge
4. Immediately provide actionable next step

**Example transformation:**

| Current | Calibrated |
|---------|------------|
| "You have fearful-avoidant attachment, which means you desperately crave connection while fearing it" | "Your relationship style developed sophisticated radar for danger. In your early environment, this protection was necessary—you learned that closeness could mean pain. The cost now is that the same radar fires in situations that are actually safe, keeping you from the connection you deeply value." |
| "You lack tools to regulate emotional intensity" | "Your nervous system responds with full intensity because it learned that big emotions required big responses to stay safe. You've developed incredible emotional perception. The opportunity now is expanding your repertoire—adding new options for when intensity serves you vs. when you want to modulate it." |
| "Organizationally scattered" | "Your attention follows meaning rather than arbitrary structure. This gives you remarkable ability to notice what matters. For sustained execution, your brain needs external scaffolding—not because something is wrong, but because that's how this type of mind works best." |

### 3. Profile-Specific Framing Rules

Based on attachment + values + neuroticism combinations:

| Profile Pattern | Framing Approach |
|-----------------|------------------|
| **Fearful-Avoidant + High ACE** | Lead with "your protection made sense"; emphasize choice and autonomy; avoid anything prescriptive |
| **High Neuroticism + Low Self-Compassion** | Include grounding normalizers ("this is common"); emphasize treatability; avoid catastrophic framing |
| **High Openness + Self-Direction values** | Frame growth as "expanding options" not "fixing problems"; appeal to self-understanding |
| **Low Agreeableness** | Be direct, avoid softening that feels patronizing; respect their preference for unvarnished truth |
| **ADHD + Low Conscientiousness** | Keep action items concrete, brief, and immediate; acknowledge the knowing-doing gap |

### 4. Modify SYSTEM_PROMPT

Change from static "unflinching honesty" to adaptive delivery:

```
Current: "Deliver UNFLINCHING HONESTY - the reader wants truth, not comfort"

New: "Deliver CALIBRATED HONESTY - truth delivered in a way this specific person can receive and act on.
For this profile, key calibrations:
- [Generated based on their defensive patterns]
- [Generated framing approach]
- [Generated validation needs]

Truth poorly delivered is truth unheard. Your goal is insights they can USE, not just insights that are technically accurate."
```

### 5. Add Pre-Emptive Validation to Clinical Sections

Modify `CLINICAL_SECTION_TEMPLATES` to include profile-aware opening validation:

For ADHD + High ACE + Fearful-Avoidant:
> "Before we explore your ADHD patterns, let's acknowledge something important: you've been managing a brain that works differently while also carrying the weight of early experiences that shaped how you see yourself. The coping strategies you developed—even the ones that now create friction—were intelligent adaptations. This section isn't about what's wrong with you. It's about understanding how your particular mind works so you can build systems that work WITH it."

---

## Implementation Steps

### Phase 1: Types & Detection (`types.ts`, `helpers.ts`)

**File: `services/analyze/types.ts`**
```typescript
// Add new interface
interface DeliveryCalibration {
  // Sensitivity level drives overall softening (1-5 scale)
  sensitivityLevel: number; // 1=very direct, 5=very gentle

  // Specific framing needs
  needsAutonomyFraming: boolean;     // Self-Direction values, avoidant attachment
  needsNormalizingLanguage: boolean; // High neuroticism, high anxiety
  needsStrengthsFirst: boolean;      // Low self-compassion, depression indicators
  needsActionChunking: boolean;      // ADHD, low conscientiousness
  needsLogicalFraming: boolean;      // Low agreeableness, high openness

  // Pre-emptive validation themes
  validationThemes: string[];  // e.g., ["protection made sense", "adaptation was intelligent"]

  // Deficit-to-growth reframes specific to this profile
  reframes: Record<string, string>;  // e.g., {"scattered": "attention follows meaning"}
}
```

**File: `services/analyze/helpers.ts`**
Add `generateDeliveryCalibration(profile: ProfileData): DeliveryCalibration`
- Calculate sensitivity level from: neuroticism percentile, attachment anxiety, ACE score, self-compassion
- Determine framing needs from: values, attachment style, clinical flags
- Generate validation themes from: ACE score, attachment history, triggered conditions
- Build reframe dictionary for deficit language

### Phase 2: Core Model Enhancement (`core-model.ts`)

Extend `CorePsychologicalModel` interface:
```typescript
interface CorePsychologicalModel {
  // ... existing fields ...
  deliveryCalibration: DeliveryCalibration;
}
```

Modify `generateCoreModel()` to include delivery calibration in the Haiku prompt, generating profile-specific:
- Sensitivity level assessment
- Framing instructions
- Validation themes
- Deficit reframes

### Phase 3: Prompts Modification (`prompts.ts`)

**3A: Add `DELIVERY_CALIBRATION_PROMPT`**
New constant that instructs the AI on adaptive delivery:

```typescript
export const DELIVERY_CALIBRATION_PROMPT = `
## Delivery Calibration (Profile-Adaptive)

This person's profile indicates: [SENSITIVITY_LEVEL] sensitivity to difficult feedback.

**Your delivery approach:**
[IF sensitivityLevel >= 4]
- Lead with validation before any difficult finding
- Acknowledge the protective function of patterns before naming costs
- Use "opportunity to expand" rather than "problem to fix" language
- Normalize: "This is common among people with your profile..."
- End difficult sections with concrete, achievable next step
[ELSE IF sensitivityLevel <= 2]
- Be direct and efficient—this profile prefers unvarnished truth
- Skip excessive softening—they'll find it patronizing
- Focus on strategic implications, not emotional validation
- Respect their preference for agency over protection
[ELSE]
- Balance honesty with compassion
- Name patterns directly but include context
- Provide both the challenge and the strength
[END IF]

**Framing requirements for this profile:**
[GENERATED BASED ON PROFILE]

**Deficit language transformations (USE THESE):**
[REFRAME DICTIONARY]

**When delivering hard findings, use this pattern:**
1. [IF needs validation] Acknowledge what this pattern protected them from
2. [IF needs validation] Validate why it made sense given their history
3. Name the current cost/growth edge clearly
4. [IF needs action chunking] Provide ONE concrete next step
`;
```

**3B: Modify `SYSTEM_PROMPT`**

Change line 14 from:
```
- Deliver UNFLINCHING HONESTY - the reader wants truth, not comfort. Name their shadows alongside their strengths
```
To:
```
- Deliver CALIBRATED TRUTH - truth framed so this specific person can receive and act on it. The goal is insights they USE, not just insights that are technically accurate. See Delivery Calibration for this person's specific needs.
```

**3C: Reframe deficit language in templates**

Throughout `CLINICAL_SECTION_TEMPLATES`, replace:
| Current | Reframe |
|---------|---------|
| "lacks tools to regulate" | "developed survival strategies that worked then; can now expand your repertoire" |
| "organizationally scattered" | "attention follows meaning and novelty rather than arbitrary structure" |
| "desperately craves connection while fearing it" | "deeply values connection while having sophisticated protection systems" |
| "stuck in alert mode" | "your nervous system is highly attuned—calibrated for survival, now seeking recalibration" |
| "struggles with X" | "working to develop X" or "building capacity for X" |

**3C-2: Strengthen clinical hedging language (CRITICAL)**

The current SYSTEM_PROMPT has basic hedging but it's inconsistently applied. Add explicit rules:

**Add to `SYSTEM_PROMPT` after the legal hedge section:**
```
**CLINICAL LANGUAGE RULES (MANDATORY):**
These screenings identify TRAITS and PATTERNS, not diagnoses. Only licensed professionals can diagnose.

NEVER SAY:
- "You are autistic" / "You are likely autistic" / "You have autism"
- "You have ADHD" / "You likely have ADHD"
- "You have depression" / "You have anxiety"
- "You are [any clinical label]"

ALWAYS SAY:
- "You show elevated autistic traits" / "Your screening suggests potential autistic traits"
- "Your screening indicates potential ADHD patterns" / "You show patterns consistent with ADHD"
- "Your screening suggests potential depression" / "You show depressive patterns"
- "Your profile indicates [trait/pattern]" not "You are [label]"

KEY PHRASES TO USE:
- "potential [condition]" not "[condition]"
- "[condition] traits/patterns" not "[condition]"
- "your screening suggests" not "you have"
- "patterns consistent with" not "diagnosis of"
- "elevated scores on [screening tool]" not "you are [condition]"

FRAMING RULE: Present as "here's what the data shows" + "here's what it might mean" + "a professional can determine if this applies to you"
```

**Update section titles throughout `CLINICAL_SECTION_TEMPLATES`:**
| Current Title | Updated Title |
|---------------|---------------|
| "Potential ADHD: How Your Mind Works Differently" | "ADHD Traits: How Your Mind Works Differently" |
| "Potential Autism: Exploring Your Autistic Traits" | "Autistic Traits: Exploring Your Neurodivergent Patterns" |
| "Potential Anxiety: Understanding Your Patterns" | "Anxiety Patterns: Understanding Your Nervous System" |
| "Potential Depression: When Everything Feels Heavy" | "Depressive Patterns: When Everything Feels Heavy" |
| "Potential PTSD: Why Your Past Still Shows Up" | "Trauma Patterns: Why Your Past Still Shows Up" |

**Add clinical disclaimer block to ALL clinical sections:**
```
**What This Screening Means:**
This assessment identifies patterns and traits—it is NOT a diagnosis. Screening tools like
[TOOL_NAME] are designed to flag patterns worth exploring, not to definitively determine
whether you have [CONDITION]. Only a qualified professional can make that determination
through comprehensive evaluation. Use this information as a starting point for
self-understanding and conversations with healthcare providers.
```

**3D: Add validation templates to clinical sections**

For each clinical section, add opening validation block that's conditionally included based on `sensitivityLevel >= 3`:

```
[IF HIGH_SENSITIVITY]
Before we explore your [CONDITION] patterns: The coping strategies you've developed—even
the ones that now create friction—were intelligent adaptations to your circumstances.
This section isn't about what's wrong with you. It's about understanding how your
particular mind works so you can build systems that work WITH it.
[END IF]
```

### Phase 4: Route Integration (`app/api/analyze-parallel/route.ts`)

1. Call `generateDeliveryCalibration(profile)` early in the pipeline
2. Include `deliveryCalibration` in the core model
3. Inject calibration into each chunk's user prompt via new helper:
   ```typescript
   function buildCalibrationInstructions(calibration: DeliveryCalibration): string
   ```
4. Pass calibration to `getOwnershipInstructions()` so it can include relevant reframes

### Phase 5: Consolidated Clinical Structure (When >2 Conditions Triggered)

**Problem:** When multiple clinical conditions are flagged (e.g., ADHD + Autism + Anxiety + Depression), the current structure repeats treatment tables, supplement tables, and resources 4+ times. This creates:
- Overwhelming length
- Redundant information (same supplements help multiple conditions)
- Fragmented treatment path instead of unified plan
- Reader fatigue

**Current Architecture Understanding:**
```
generateCoreModel() [Haiku] → detectTriggeredClinicalConditions() → getIndividualChunks()
                                                                         ↓
                                              includes: getPerConditionChunks().map(...)
                                                                         ↓
                                              Each condition → separate chunk with buildPrompt()
                                              Each chunk includes: What/How/Gifts/Treatment/NextSteps
                                                                         ↓
                                              All chunks run in PARALLEL → combined in report order
```

**Solution: Single Consolidated Chunk (Works with Existing Architecture)**

When `triggeredCount > 2`, instead of spreading 4+ separate clinical chunks, generate ONE larger `clinical-consolidated` chunk with a different template.

**1. Add to `helpers.ts`:**
```typescript
export function shouldUseConsolidatedClinical(triggered: TriggeredClinicalConditions): boolean {
  const clinicalCount = [
    triggered.adhd,
    triggered.autism,
    triggered.anxiety,
    triggered.depression,
    triggered.ptsd,
    triggered.burnout
  ].filter(Boolean).length;
  return clinicalCount > 2;
}

export function getTriggeredConditionsList(triggered: TriggeredClinicalConditions): string[] {
  const conditions: string[] = [];
  if (triggered.adhd) conditions.push('ADHD');
  if (triggered.autism) conditions.push('Autism');
  if (triggered.anxiety) conditions.push('Anxiety');
  if (triggered.depression) conditions.push('Depression');
  if (triggered.ptsd) conditions.push('PTSD');
  if (triggered.burnout) conditions.push('Burnout');
  // ... etc
  return conditions;
}
```

**2. Modify `getIndividualChunks()` in `route.ts`:**

```typescript
// Current: Always spread individual clinical chunks
...(triggeredConditions && triggeredConditions.triggeredCount > 0
  ? getPerConditionChunks(triggeredConditions).map(...)
  : []),

// New: Check if we should consolidate
...(triggeredConditions && triggeredConditions.triggeredCount > 0
  ? (shouldUseConsolidatedClinical(triggeredConditions)
      ? [getConsolidatedClinicalChunk(triggeredConditions, name)]  // ONE chunk
      : getPerConditionChunks(triggeredConditions).map(...)        // Multiple chunks
    )
  : []),
```

**3. Add `getConsolidatedClinicalChunk()` function:**

```typescript
function getConsolidatedClinicalChunk(
  triggered: TriggeredClinicalConditions,
  name: string
): ChunkDefinition {
  const conditionsList = getTriggeredConditionsList(triggered);

  return {
    id: 'clinical-consolidated',
    name: 'Consolidated Clinical Profile',
    buildPrompt: (profile: any, _: any, relationshipType: string) => `
Here is ${name}'s COMPLETE psychological profile:
${JSON.stringify(getRelevantProfileData(profile, 'wellbeing-inversions'), null, 2)}

${SCORING_CONTEXT}
${CROSS_INTEGRATION_PROMPT}

## Your Clinical Profile: Understanding How Your Mind Works

${name} shows patterns across MULTIPLE areas that commonly co-occur: ${conditionsList.join(', ')}.
Rather than treating these as separate conditions, this section integrates them into ONE cohesive picture.

**STRUCTURE (Follow Exactly):**

### Part 1: Understanding Your Patterns

For EACH of these conditions, write 2-3 paragraphs explaining what it means for ${name} specifically.
Connect to their Big Five, attachment, values. NO treatment info here - just understanding.

${triggered.adhd ? `#### ADHD Traits\n[What ADHD means for ${name} - connected to their other traits]\n` : ''}
${triggered.autism ? `#### Autistic Traits\n[What autism means for ${name} - connected to their other traits]\n` : ''}
${triggered.anxiety ? `#### Anxiety Patterns\n[What anxiety means for ${name} - connected to their other traits]\n` : ''}
${triggered.depression ? `#### Depressive Patterns\n[What depression means for ${name} - connected to their other traits]\n` : ''}
${triggered.ptsd ? `#### Trauma Patterns\n[What trauma patterns mean for ${name}]\n` : ''}

---

### Part 2: Your Combined Gifts & Challenges

Create ONE unified table drawing from ALL conditions:

| Your Gifts | Your Challenges |
|------------|-----------------|
| [Gift from condition combo] | [Challenge from condition combo] |
| [Another gift] | [Another challenge] |
| [Another gift] | [Another challenge] |
| [Another gift] | [Another challenge] |

---

### Part 3: Your Integrated Treatment Pathway

**The Good News:** Many treatments help MULTIPLE conditions. You don't need ${conditionsList.length} separate plans.

#### Foundation Treatments (Help Everything)
| Approach | What It Addresses | Priority |
|----------|------------------|----------|
| [Treatment] | [Which conditions from their list] | HIGH/MED/LOW |

#### Condition-Specific Additions
| Approach | Primary Target | Notes |
|----------|----------------|-------|
| [Treatment] | [Primary condition] | [How it helps others too] |

#### Supplements (Consolidated)
| Supplement | Dosage | Helps With | Evidence |
|------------|--------|------------|----------|
| [Only include supplements that address MULTIPLE conditions in their profile] |

*Consult healthcare provider before starting supplements.*

---

### Part 4: Your Resource Toolkit

Based on ${name}'s specific combination of ${conditionsList.join(', ')}, here are targeted resources:

#### Books
| Book | Author | Which Patterns It Addresses |
|------|--------|---------------------------|
| [Book from approved list] | [Author] | [Specific conditions it helps with] |
| [Book from approved list] | [Author] | [Specific conditions it helps with] |
| [Book from approved list] | [Author] | [Specific conditions it helps with] |

IMPORTANT: Use Amazon search links: [Book Title](https://www.amazon.com/s?k=Book+Title+Author)
CRITICAL: Only recommend from CURATED_BOOKS list.

#### Podcasts
| Episode | Show | Which Patterns It Addresses |
|---------|------|---------------------------|
| [Specific episode] | Huberman Lab/The Drive/FoundMyFitness | [Conditions it covers] |
| [Specific episode] | [Show] | [Conditions it covers] |

CRITICAL: Only recommend from approved shows: Huberman Lab, The Drive, FoundMyFitness.

---

### Part 5: Your Prioritized Next Steps

3-5 specific actions for ${name}, ordered by impact. Each should address multiple conditions where possible.

1. [Most impactful action - explain which conditions it helps]
2. [Second action]
3. [Third action]

Use markdown formatting.`
  };
}
```

**4. Add model routing and thinking budget:**

```typescript
// In CHUNK_MODEL_ROUTING
'clinical-consolidated': 'sonnet',

// In THINKING_BUDGETS
'clinical-consolidated': 25000,  // Needs more budget for integrated analysis
```

**Why This Works:**
- Fits existing parallel architecture - just ONE chunk instead of 4+
- Same buildPrompt pattern, just different template
- Cache-friendly - consolidated prompt still uses shared context
- Graceful fallback - if consolidated fails, can retry with individual chunks
- Reduces output tokens by ~60% for complex profiles

---

### Phase 5b: Restructure Wellbeing + Skip Resources When Consolidated

**When clinical issues are flagged:**
1. **Wellbeing section** → Brief snapshot only (PERMA scores, life satisfaction, loneliness) - NO treatment content
2. **Clinical-consolidated section** → Absorbs treatment + resources content
3. **Resources section** → SKIP (absorbed into clinical-consolidated)

**When NO clinical issues flagged:**
- Wellbeing section → Full version (current behavior)
- Resources section → Normal (current behavior)

**Implementation:**

**1. Create condensed wellbeing chunk template:**

Add a flag `isConsolidatedMode` to the wellbeing chunk builder:

```typescript
// In getIndividualChunks()
{
  id: 'wellbeing-base',
  name: 'Wellbeing & Mental Health',
  buildPrompt: (profile, _, relationshipType) => {
    const isConsolidated = triggeredConditions && shouldUseConsolidatedClinical(triggeredConditions);

    if (isConsolidated) {
      // Brief snapshot version
      return `
Here is ${name}'s psychological profile:
${JSON.stringify(getRelevantProfileData(profile, 'wellbeing-inversions'), null, 2)}

${SCORING_CONTEXT}

## 💫 Your Wellbeing Snapshot

Write a BRIEF wellbeing summary for ${name} (this is NOT the main clinical section - just context).

### Current State
- PERMA wellbeing scores (brief table or bullets)
- Life satisfaction (SWLS score + one-line interpretation)
- Loneliness (UCLA-3 score + one-line interpretation)

### What This Means
2-3 paragraphs contextualizing these scores given their clinical profile.
Connect to their triggered conditions (${getTriggeredConditionsList(triggeredConditions).join(', ')}).

DO NOT include:
- Treatment recommendations (covered in Clinical Profile section)
- Building on strengths (covered in Clinical Profile section)
- Detailed analysis (save for Clinical Profile section)

Keep this section SHORT - it's context, not the main event.`;
    } else {
      // Full version (current)
      return `[existing full wellbeing prompt]`;
    }
  }
}
```

**2. Skip Resources chunk in consolidated mode:**

```typescript
// In getIndividualChunks() - conditionally include resources
...(!(triggeredConditions && shouldUseConsolidatedClinical(triggeredConditions))
  ? [{
      id: 'resources',
      name: 'Growth Resources',
      buildPrompt: // existing resources prompt
    }]
  : []), // Skip resources when consolidated - absorbed into clinical chunk
```

**Note:** The consolidated clinical chunk template (Phase 5) already includes Part 4: Resource Toolkit and Part 5: Prioritized Next Steps, so resources are automatically absorbed when using consolidated mode.

**Updated Report Structure (Consolidated Mode):**

```
1. Overview
2. Personality Architecture
3. Emotional World
4. Values & Motivation
5. Best Fit sections...
6. Wellbeing Snapshot [BRIEF - just scores/context]
7. Clinical Profile & Treatment Pathway [CONSOLIDATED - ONE chunk]
   Part 1: Understanding Your Patterns (ADHD, Autism, etc. - 2-3 paragraphs each)
   Part 2: Combined Gifts & Challenges (ONE unified table)
   Part 3: Integrated Treatment Pathway (foundation + condition-specific + supplements)
   Part 4: Resource Toolkit (books + podcasts - ABSORBED from Resources chunk)
   Part 5: Prioritized Next Steps (3-5 actions)
8. Path Forward / Conclusion
```

**Updated Report Structure (Non-Consolidated Mode - ≤2 conditions):**

```
1. Overview
2. Personality Architecture
3. Emotional World
4. Values & Motivation
5. Best Fit sections...
6. Wellbeing & Mental Health [FULL]
7. Clinical: ADHD [if triggered]
8. Clinical: Autism [if triggered]
9. Resources [SEPARATE]
10. Path Forward / Conclusion
```

---

### Phase 6: Specific Language Changes

**Attachment Section** - Key reframes for fearful-avoidant:
- "desperately craves" → "deeply values"
- "fears engulfment" → "has learned to protect inner world"
- "push-pull dynamic" → "approach-protect pattern"

**ACE Section** - Validation-first opening:
- Add "What you survived required adaptation. These adaptations were intelligent."
- Reframe "childhood adversity impacts" → "how your early environment shaped your nervous system"

**Wellbeing Section** - For low SWLS:
- Add normalizing context before presenting the number
- Connect to hope: "This score reflects your current experience, not your ceiling"

**All Clinical Sections** - Add after each challenge:
- For ADHD profiles: "One concrete step: [SPECIFIC ACTION]"
- For high-neuroticism: "Remember: this is common and treatable"

---

## Design Decisions

1. **Visibility**: **Invisible adaptation** - Just adapt the language without meta-commentary. Cleaner reading experience; the calibration works behind the scenes.

2. **Directness spectrum**: **Profile-adaptive** - Direct types (low neuroticism + low agreeableness) get more unflinching delivery. Sensitive types (high neuroticism, anxious attachment, high ACE) get more validation. True personalization.

3. **Scope**: **All sections at once** - Implement as a system-wide calibration layer that affects every section, not piecemeal.

---

## Testing Approach

1. Generate reports for the same profile with current vs. calibrated prompts
2. Compare language around the most sensitive findings
3. Evaluate: Does it still convey truth? Does it create space for action rather than shutdown?
4. Consider A/B testing with actual users (if possible)

---

## Files to Modify (Summary)

| File | Changes |
|------|---------|
| `services/analyze/types.ts` | Add `DeliveryCalibration` interface |
| `services/analyze/helpers.ts` | (1) Add `generateDeliveryCalibration()`, (2) Add `shouldUseConsolidatedClinical()`, (3) Add `getTriggeredConditionsList()` - all need to be exported |
| `services/analyze/core-model.ts` | Extend `CorePsychologicalModel` interface with `deliveryCalibration` field |
| `services/analyze/prompts.ts` | **Major changes:** (1) Add `DELIVERY_CALIBRATION_PROMPT`, (2) Modify `SYSTEM_PROMPT` for calibrated truth + clinical language rules, (3) Update clinical section titles from "Potential X" to "X Traits/Patterns", (4) Add clinical disclaimer blocks, (5) Reframe deficit language, (6) Add `CONSOLIDATED_CLINICAL_TEMPLATE` constant |
| `app/api/analyze-parallel/route.ts` | (1) Import new helpers, (2) Add delivery calibration to chunk generation, (3) Add `getConsolidatedClinicalChunk()` function, (4) Modify `getIndividualChunks()` to conditionally use consolidated mode, (5) Modify wellbeing chunk for brief mode, (6) Conditionally skip Resources chunk, (7) Add model routing for `clinical-consolidated` |

---

## Key Language Changes Summary

### Clinical Hedging (Apply Everywhere)
| Never Say | Always Say |
|-----------|------------|
| "You are autistic" | "You show elevated autistic traits" |
| "You have ADHD" | "Your screening indicates potential ADHD patterns" |
| "You likely have depression" | "Your screening suggests depressive patterns" |
| "You are [label]" | "Your profile indicates [trait/pattern]" |

### Deficit Reframing
| Deficit Language | Growth Language |
|------------------|-----------------|
| "lacks tools" | "can expand your repertoire" |
| "scattered" | "attention follows meaning" |
| "desperately craves" | "deeply values" |
| "struggles with" | "working to develop" |

### Delivery Calibration
| Sensitivity Level | Approach |
|-------------------|----------|
| 1-2 (Direct types) | Unflinching, efficient, strategic framing |
| 3 (Balanced) | Honest with compassion, context included |
| 4-5 (Sensitive types) | Validation first, normalizing language, hope-forward |

### Consolidated Clinical Structure (>2 conditions)
| Current (Repetitive) | Consolidated (New) |
|----------------------|-------------------|
| 4 separate condition sections, each with full treatment/supplements/resources | Individual condition descriptions (shorter) + ONE unified Gifts & Challenges + ONE integrated Treatment Pathway + ONE Resource Toolkit |
| ~20 pages of clinical content | ~8-10 pages, more actionable |
| Reader must synthesize across sections | Pre-integrated, shows how conditions interact |
