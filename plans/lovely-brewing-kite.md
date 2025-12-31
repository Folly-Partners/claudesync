# Deep Personality: Eliminate Report Repetition

## Problem Summary

Reports contain ~25-35% redundant content due to **parallel chunk generation with no shared state**:

1. Each of 8-12+ chunks receives the COMPLETE psychological profile
2. Chunks execute via `Promise.all` - no awareness of what other chunks wrote
3. `SECTION_OWNERSHIP_MATRIX` is advisory text only, not enforced
4. Result: Same causal models re-explained 15+ times across sections

### Repetition Types (from ChatGPT audit)
| Type | Current | Target |
|------|---------|--------|
| Causal chain (trauma→attachment→symptoms) | 15+ times | 1-2 |
| Big Five trait re-explanations | 5+ times | 0 (reference only) |
| Attachment pattern deep-dives | 8+ sections | 1 |
| Treatment duplicates (EMDR, DBT, etc.) | 4+ each | 1 each |
| Metaphor reuse ("Ferrari with bicycle brakes") | 5+ times | 1 |

---

## Core Principle: Reference Without Re-Explanation

The goal is NOT to prevent cross-integration. Sections SHOULD consider all aspects of the person. The goal is to prevent **re-explaining concepts that were already explained**.

| Type | Example | Verdict |
|------|---------|---------|
| Reference | "Due to your anxious attachment patterns, this shows up in your work as..." | GOOD |
| Re-explanation | "You have anxious attachment, which means you worry about abandonment and seek reassurance from partners. This leads to..." | BAD |
| Reference | "Given your high Neuroticism..." | GOOD |
| Re-explanation | "Your high Neuroticism (88th percentile) means you experience emotions more intensely than most people, making you prone to..." | BAD |

**Key insight:** Each section should assume the reader has already read prior sections. Use phrases like "As discussed earlier," "Given your [trait]," or "Due to your [pattern]" - then move directly to the NEW insight.

---

## Solution: Hybrid Pre-Synthesis + Enhanced Ownership

### Architecture Change

```
CURRENT:
  Profile → All Chunks (Parallel) → Combined Report

PROPOSED:
  Profile → Core Model Generator (~3s, Haiku)
                 ↓
  Core Model + Profile → All Chunks (Parallel) → Combined Report
```

**Key insight:** Generate a compressed "Core Psychological Model" first. This tells each chunk "these concepts have been explained already - just reference them, don't re-explain."

---

## Implementation Plan

### Phase 1: Create Core Psychological Model

**Purpose:** The Core Model provides:
1. One-liner summaries for reference phrases
2. **Ownership mapping** - which chunk OWNS (fully explains) each concept
3. Reference phrases for non-owner chunks

**New file:** `/Users/andrewwilkinson/Deep-Personality/services/analyze/core-model.ts`

```typescript
export interface CorePsychologicalModel {
  // One-liner summaries that chunks can reference
  personalitySummary: {
    O: string; // "High Openness (82nd): creative, abstract thinker"
    C: string;
    E: string;
    A: string;
    N: string;
  };
  attachmentOneLiner: string; // "fearful-avoidant: craves closeness but fears engulfment"
  traumaSummary: string; // "High ACE (6) with early neglect themes"
  clinicalConditions: string[]; // ["ADHD", "Anxiety", "Depression"]

  // WHO OWNS WHAT (ensures first mention is full explanation)
  conceptOwnership: {
    bigFive: string;           // "personality" - chunk ID that fully explains
    attachment: string;        // "emotional"
    emotionRegulation: string; // "emotional"
    trauma: string;            // "wellbeing-base" or "clinical-ptsd"
    values: string;            // "values"
  };

  // Reference phrases for NON-OWNER chunks
  referenceExamples: {
    personality: string; // "Given your high Openness and low Conscientiousness..."
    attachment: string;  // "Due to your fearful-avoidant attachment..."
    trauma: string;      // "Your trauma history shapes this as..."
  };
}

// Fixed ownership based on report section order
export const CONCEPT_OWNERSHIP: Record<string, string> = {
  bigFive: 'personality',
  attachment: 'emotional',
  emotionRegulation: 'emotional',
  conflictStyle: 'emotional',
  rejectionSensitivity: 'emotional',
  values: 'values',
  careerInterests: 'values',
  workMotivation: 'values',
  trauma: 'wellbeing-base',  // or 'clinical-ptsd' if PTSD triggered
  permaWellbeing: 'wellbeing-base',
  lifeSatisfaction: 'wellbeing-base',
};

export async function generateCoreModel(profile: ProfileData): Promise<CorePsychologicalModel>
```

**Generator uses Haiku for speed (~3s)** - creates one-liners and reference phrases. Ownership is deterministic based on section order.

---

### Phase 1.5: Build Ownership-Aware Chunk Instructions

**File:** `/Users/andrewwilkinson/Deep-Personality/services/analyze/core-model.ts`

Each chunk gets personalized instructions based on whether it OWNS or REFERENCES each concept:

```typescript
export function getOwnershipInstructions(chunkId: string, coreModel: CorePsychologicalModel): string {
  const owned: string[] = [];
  const referenced: { concept: string; phrase: string }[] = [];

  // Check each concept
  if (CONCEPT_OWNERSHIP.bigFive === chunkId) {
    owned.push('Big Five personality traits');
  } else {
    referenced.push({
      concept: 'Big Five',
      phrase: coreModel.referenceExamples.personality
    });
  }

  if (CONCEPT_OWNERSHIP.attachment === chunkId) {
    owned.push('Attachment style');
  } else {
    referenced.push({
      concept: 'Attachment',
      phrase: coreModel.referenceExamples.attachment
    });
  }

  // ... same for trauma, values, etc.

  return `
${owned.length > 0 ? `
**YOU OWN (fully explain these - this is the ONE place they get explained):**
${owned.map(c => `- ${c}`).join('\n')}

Provide thorough explanations with examples. The reader learns about these HERE.
` : ''}

**ALREADY EXPLAINED (reference only, do NOT re-explain):**
${referenced.map(r => `- ${r.concept}: Use "${r.phrase}..." then move to your NEW insight`).join('\n')}
`;
}
```

**Example output for ADHD chunk:**
```
**ALREADY EXPLAINED (reference only, do NOT re-explain):**
- Big Five: Use "Given your high Openness and low Conscientiousness..." then move to your NEW insight
- Attachment: Use "Due to your fearful-avoidant attachment..." then move to your NEW insight
- Trauma: Use "Your trauma history shapes this as..." then move to your NEW insight

Focus on how ADHD specifically manifests given these traits, not what the traits mean.
```

**Example output for Emotional World chunk:**
```
**YOU OWN (fully explain these - this is the ONE place they get explained):**
- Attachment style
- Emotion regulation patterns
- Conflict style
- Rejection sensitivity

Provide thorough explanations with examples. The reader learns about these HERE.

**ALREADY EXPLAINED (reference only, do NOT re-explain):**
- Big Five: Use "Given your high Neuroticism..." then move to your NEW insight
```

---

### Phase 2: Inject Ownership Instructions Per-Chunk

**File:** `/Users/andrewwilkinson/Deep-Personality/app/api/analyze-parallel/route.ts`
**Location:** Lines 2157-2174 (chunk prompt building)

Each chunk gets its own ownership-aware instructions:

```typescript
// Generate core model ONCE before all chunks
const coreModel = await generateCoreModel(cleanProfileA);

// Build prompts for each chunk with ownership context
const chunkPromises = sortedChunks.map(chunk => {
  const fullPrompt = chunk.buildPrompt(cleanProfileA, cleanProfileB, relationshipType);

  // Get ownership instructions specific to THIS chunk
  const ownershipInstructions = getOwnershipInstructions(chunk.id, coreModel);

  // Prepend ownership instructions to chunk's specific instructions
  const chunkInstructions = `
${ownershipInstructions}

---

${extractChunkInstructions(fullPrompt, chunk.id)}
`;

  return {
    id: chunk.id,
    name: chunk.name,
    cacheableContext: cacheableContext,  // Shared profile data
    chunkInstructions: chunkInstructions, // Chunk-specific with ownership
    promise: callAnthropicChunkCached(...)
  };
});
```

**Result:** Each chunk knows:
- What it OWNS (fully explain)
- What's ALREADY EXPLAINED (reference only with suggested phrasing)

---

### Phase 3: Enhanced Section Ownership Matrix

**File:** `/Users/andrewwilkinson/Deep-Personality/services/analyze/prompts.ts`
**Location:** Replace `SECTION_OWNERSHIP_MATRIX` (line 209)

New version emphasizing **reference without re-explanation**:

```typescript
export const ENHANCED_SECTION_OWNERSHIP_MATRIX = `
## WRITING RULE: ASSUME THE READER KNOWS

The reader has already read prior sections. When you reference a concept from an earlier section:

**DO THIS (Reference):**
- "Due to your anxious attachment patterns, you may find yourself..."
- "Given your high Neuroticism, this triggers..."
- "Your trauma history means that..."
- "Building on the ADHD patterns discussed earlier..."

**DON'T DO THIS (Re-explanation):**
- "You have anxious attachment, which means you worry about abandonment and constantly seek reassurance from partners. This pattern developed because..."
- "Your high Neuroticism (88th percentile) means you experience emotions more intensely than most people. This trait causes you to..."
- "Your trauma history includes 6 adverse childhood experiences. Research shows that ACE scores above 4 are associated with..."

**The Test:** If you're about to explain WHAT a concept means, stop. Just reference it and move to your NEW insight about how it applies in THIS context.

### OWNERSHIP TABLE (Where concepts get explained ONCE)

| Concept | Explained In | Everywhere Else |
|---------|--------------|-----------------|
| Big Five traits (what each means) | Personality Architecture | "Given your [trait]..." |
| Attachment style (mechanics) | Emotional World | "Due to your [style]..." |
| Emotion regulation (DERS patterns) | Emotional World | "Your regulation patterns mean..." |
| Trauma/ACE impact | Wellbeing or PTSD section | "Your trauma history..." |
| Treatment options (EMDR, DBT, etc.) | First section that needs it | "See [Section] for options" |

### CLINICAL SECTION RULE
Clinical sections (ADHD, Anxiety, Depression, etc.) should focus on:
1. How THIS condition specifically manifests given their profile
2. THIS condition's unique gifts and challenges
3. THIS condition's specific strategies

NOT: Re-explaining Big Five traits, attachment mechanics, or trauma dynamics.
`;
```

---

### Phase 4: Update Clinical Chunk Prompts

**File:** `/Users/andrewwilkinson/Deep-Personality/app/api/analyze-parallel/route.ts`
**Location:** Clinical chunk buildPrompt (lines 762-810)

Add "assume reader knows" header to each clinical prompt:

```typescript
**WRITING RULE: ASSUME THE READER KNOWS**

The reader has already learned about their personality traits, attachment style, and trauma history
in earlier sections. Reference these concepts without re-explaining them.

GOOD: "Due to your anxious attachment, your ADHD shows up as..."
BAD: "You have anxious attachment, which means you worry about abandonment... Your ADHD..."

**YOUR FOCUS FOR ${chunk.conditionKey}:**
1. How ${chunk.conditionKey} SPECIFICALLY shows up given their unique profile
2. ${chunk.conditionKey}-specific gifts and challenges (not general trait descriptions)
3. ${chunk.conditionKey}-specific strategies and treatments

Reference personality/attachment/trauma as needed, but don't explain what they ARE -
explain how they INTERACT with ${chunk.conditionKey}.
```

---

### Phase 5: Add Repetition Metrics

**File:** `/Users/andrewwilkinson/Deep-Personality/app/api/analyze-parallel/route.ts`
**Location:** After chunk assembly (line 2216)

```typescript
function analyzeRepetition(text: string): object {
  return {
    attachmentExplanations: (text.match(/attachment.{0,50}(means|characterized by)/gi) || []).length,
    bigFiveReExplanations: (text.match(/(openness|conscientiousness|extraversion|agreeableness|neuroticism).{0,30}(means|which means)/gi) || []).length,
    traumaChains: (text.match(/trauma.{0,50}(leads to|→|causes)/gi) || []).length,
    emdrMentions: (text.match(/EMDR/gi) || []).length,
  };
}

const metrics = analyzeRepetition(combinedText);
logServerEvent(`[REPETITION] ${JSON.stringify(metrics)}`);
```

---

## Files to Modify

| File | Change |
|------|--------|
| `services/analyze/core-model.ts` | NEW - Core model generator |
| `services/analyze/prompts.ts` | Replace SECTION_OWNERSHIP_MATRIX with enhanced version |
| `services/analyze/index.ts` | Export new core-model functions |
| `app/api/analyze-parallel/route.ts` | Integrate core model, update clinical prompts, add metrics |

---

## Implementation Order

| Step | Task | Risk | Impact |
|------|------|------|--------|
| 1 | Create `core-model.ts` with generator | Low | Foundation |
| 2 | Update `prompts.ts` with enhanced ownership | Low | High |
| 3 | Integrate core model into route.ts | Medium | High |
| 4 | Update clinical chunk prompts | Low | High |
| 5 | Add repetition metrics | Low | Monitoring |
| 6 | Test with high-trigger profiles | - | Validation |

---

## Expected Outcomes

| Metric | Before | After |
|--------|--------|-------|
| Report length | ~25k words | ~18k words |
| Attachment explanations | 8+ | 1-2 |
| Big Five re-explanations | 5+ | 0 |
| Treatment duplicates | 4+ each | 1 each |
| Generation time | ~45s | ~48s (+3s for core model) |

---

## Testing Strategy

1. Generate report for profile with ADHD + Anxiety + Depression + High ACE
2. Search for repetition patterns:
   - `grep -c "attachment.*means"`
   - `grep -c "EMDR"`
   - `grep -c "Neuroticism.*means"`
3. Compare word count before/after
4. Verify clinical depth preserved (spot-check quality)
