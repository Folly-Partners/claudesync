# Plan: Full Context for Every Report Section

## Core Insight

Each section should receive the **complete psychological profile**, not filtered data. Even though a section focuses on one topic (e.g., substance abuse), the AI should have access to **everything** it knows about the person to make interconnections.

**The analogy:** A psychologist writing a substance abuse section has the entire case file in front of them. They naturally connect ADHD to self-medication, attachment anxiety to stress-drinking, ACE scores to learned numbing. The AI should work the same way.

## Problem with Current Approach

```
Current: Profile → getRelevantProfileData(chunkId) → Filtered subset → AI
```

The `getRelevantProfileData()` function aggressively filters. For example, the substance abuse section receives:
- ✓ ACE, DERS, DTS, compulsive behaviors
- ✗ ADHD screening (ASRS-18) - filtered out
- ✗ Attachment patterns (ECR-S) - filtered out
- ✗ Autism indicators - filtered out

This **artificially silos** what the AI knows, preventing it from making connections like:
- ADHD → self-medication with substances
- Anxious attachment → relationship stress driving substance use
- High Openness + sensation-seeking → experimentation patterns
- ACE + avoidant attachment → numbing as learned survival

## The Fix: Full Context, Focused Output

```
New: Full Profile → AI → Focused section (with full context to draw from)
```

**Every section gets:**
1. Complete psychological profile (all assessments)
2. Section-specific focus instructions (what to write about)
3. Integration prompt (actively look for cross-measure patterns)

The prompts tell the AI **what lens to view through**, but the AI has **everything** available.

## Why This Works

1. **We can't anticipate all connections** - Manual cross-condition mapping (ADHD→substance) misses patterns we haven't thought of

2. **The AI is capable** - With 5K-20K extended thinking tokens, Claude can sift through a full profile and identify what matters

3. **The conclusion already gets full data** - Proving the system handles it. Each section should be a focused synthesis, not just the end

4. **Token cost is negligible** - Full profile ~1,500 tokens × 6 chunks = ~9K extra input tokens ≈ $0.02/report

5. **Matches how real psychologists work** - Full case file, focused section

## Implementation

### Step 1: Modify `getRelevantProfileData()` in `helpers.ts`

Remove filtering entirely - always return full profile:

```typescript
function getRelevantProfileData(profile: Profile, chunkId: string): Profile {
  // Return full profile for all chunks - let AI synthesize with full context
  return profile;
}
```

The existing filtering switch statement can be removed entirely.

### Step 2: Add Integration Prompt to Each Section

Add to `prompts.ts` or each chunk's `buildPrompt`:

```typescript
const CROSS_INTEGRATION_PROMPT = `
## Full Profile Integration

You have access to ${name}'s COMPLETE psychological profile - all assessments,
all scores, all patterns. While this section focuses on [SECTION_TOPIC], you
should actively consider how ALL aspects of their psychology interconnect.

Examples of connections to look for:
- ADHD + substance patterns → self-medication dynamics
- Attachment style + mental health → relational roots of depression/anxiety
- Trauma history + coping style → learned survival strategies
- Personality traits + clinical patterns → how their Big Five shapes symptom expression
- Neurodivergence + masking → exhaustion, burnout, identity confusion

Don't just list these connections - integrate them naturally into your analysis.
Describe how THIS PERSON's specific pattern manifests, not generic possibilities.
`;
```

### Step 3: Update Chunk Prompts

Each chunk's `buildPrompt` function should:
1. Receive full profile (not filtered)
2. Include section focus instructions (what to write about)
3. Include cross-integration prompt (actively synthesize)

```typescript
// Example for wellbeing-inversions chunk
buildPrompt(profile: Profile) {
  return `
${SYSTEM_PROMPT}

## ${name}'s Complete Psychological Profile
${JSON.stringify(profile.assessments, null, 2)}

## Your Focus: Wellbeing & Clinical Patterns
Primary topics: mental health screening, substance risk, coping strategies, treatment options

${CROSS_INTEGRATION_PROMPT}

${CLINICAL_SECTION_TEMPLATES}
  `;
}
```

### Step 4: Test Edge Cases

- Profile with ADHD + substance risk → verify self-medication connection is made
- Profile with anxious attachment + depression → verify relational depression angle
- Profile with autism + ADHD → verify comorbidity discussion
- Profile with high ACE + avoidant attachment → verify trauma-coping connection

## Files to Modify

| File | Change |
|------|--------|
| `services/analyze/helpers.ts` | Modify `getRelevantProfileData()` to return full profile |
| `services/analyze/prompts.ts` | Add `CROSS_INTEGRATION_PROMPT` constant |
| `services/analyze/chunks/*.ts` | Update each chunk's `buildPrompt` to include integration prompt |
| `app/api/analyze-parallel/route.ts` | No changes needed (already passes profile through) |

## Validation

After implementation, generate reports for test profiles with known cross-condition patterns and verify:

1. Substance section mentions ADHD self-medication (when ADHD present)
2. Depression section mentions attachment origins (when anxious/avoidant)
3. ADHD section mentions substance risk (when elevated)
4. Personality section explains scattered focus through ADHD lens (when present)
5. Autism section discusses ADHD comorbidity (when both present)
