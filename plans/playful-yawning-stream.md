# Fix Clinical Deep-Dives Timeout for Complex Profiles

## Problem
The `clinical-deepdives` chunk tries to generate ALL triggered conditions (potentially 15+) in a single API call. For complex profiles (6+ conditions), this times out with "Section could not be generated: Overall timeout".

## Solution: Individual Per-Condition Chunking

Replace the single `clinical-deepdives` chunk with **one chunk per triggered condition**:

| Chunk ID Pattern | Example Conditions | Timeout |
|------------------|-------------------|---------|
| `clinical-adhd` | ADHD | 45s |
| `clinical-autism` | Autism/Masking | 45s |
| `clinical-anxiety` | GAD/Anxiety | 45s |
| `clinical-depression` | Depression/PHQ-9 | 45s |
| `clinical-ptsd` | PTSD/Trauma | 45s |
| `clinical-burnout` | Burnout | 45s |
| ... | (one per condition) | 45s |

**Result**:
- Each condition = 1 small fast chunk (30-45s)
- Max 15+ parallel chunks, but each is trivially fast
- Failed conditions retry individually (no cascading failures)
- Maximum reliability for complex profiles

## Files to Modify

### 1. `/Users/andrewwilkinson/Deep-Personality/services/analyze/helpers.ts`
- Add `ClinicalConditionChunk` interface
- Add `getPerConditionChunks()` function that creates one chunk definition per triggered condition
- Map condition flags to section titles and template snippets

### 2. `/Users/andrewwilkinson/Deep-Personality/services/analyze/index.ts`
- Export new `getPerConditionChunks` function and `ClinicalConditionChunk` type

### 3. `/Users/andrewwilkinson/Deep-Personality/app/api/analyze-parallel/route.ts`
- Remove single `clinical-deepdives` chunk definition (lines 722-757)
- Call `getPerConditionChunks()` to generate individual chunk definitions
- Add default thinking budget for `clinical-*` chunks (5000 tokens)
- Add default timeout for `clinical-*` chunks (45s)
- Update priority sorting to handle dynamic chunk IDs

## Implementation Steps

### Step 1: Add per-condition chunk generator (helpers.ts)

```typescript
export interface ClinicalConditionChunk {
  id: string;           // e.g., 'clinical-adhd', 'clinical-anxiety'
  name: string;         // e.g., 'ADHD Deep-Dive'
  sectionTitle: string; // e.g., '🧠 How Your Mind Works Differently (ADHD)'
  conditionKey: string; // e.g., 'adhd'
}

export function getPerConditionChunks(
  triggered: TriggeredClinicalConditions
): ClinicalConditionChunk[] {
  const chunks: ClinicalConditionChunk[] = [];

  if (triggered.adhd) {
    chunks.push({
      id: 'clinical-adhd',
      name: 'ADHD Deep-Dive',
      sectionTitle: '🧠 How Your Mind Works Differently (ADHD)',
      conditionKey: 'adhd'
    });
  }
  if (triggered.anxiety) {
    chunks.push({
      id: 'clinical-anxiety',
      name: 'Anxiety Deep-Dive',
      sectionTitle: '😰 Understanding Your Anxiety',
      conditionKey: 'anxiety'
    });
  }
  // ... one for each possible condition

  return chunks;
}
```

### Step 2: Replace clinical-deepdives in getIndividualChunks()

```typescript
// Remove old clinical-deepdives chunk (lines 722-757)

// Add individual chunks for each triggered condition
if (triggeredConditions && triggeredConditions.triggeredCount > 0) {
  const conditionChunks = getPerConditionChunks(triggeredConditions);

  for (const chunk of conditionChunks) {
    baseChunks.push({
      id: chunk.id,
      name: chunk.name,
      buildPrompt: (profile, _, relationshipType) => `
${JSON.stringify(getRelevantProfileData(profile, 'wellbeing-inversions'), null, 2)}

${SCORING_CONTEXT}
${CROSS_INTEGRATION_PROMPT}

## ${chunk.sectionTitle}

Write ONLY this clinical deep-dive section. Include:
1. What this actually means (plain English, not clinical jargon)
2. How YOUR specific pattern shows up (connected to ${name}'s other traits)
3. Gifts and challenges table
4. Treatment Options table with efficacy percentages
5. 2-3 targeted resources (books/podcasts)

${getTemplateForCondition(chunk.conditionKey)}

Use markdown formatting. Be specific to ${name}'s profile.`
    });
  }
}
```

### Step 3: Add wildcard timeout/budget handling

```typescript
// In getAdaptiveThinkingBudget:
if (chunkId.startsWith('clinical-')) {
  return isRetry ? 8000 : 5000;  // Small budget for single condition
}

// In getAdaptiveTimeout:
if (chunkId.startsWith('clinical-')) {
  return 45000;  // 45s is plenty for one condition
}
```

### Step 4: Update priority sorting for dynamic IDs

```typescript
// Clinical chunks should all start early
const priority = chunkId.startsWith('clinical-')
  ? 1  // High priority (start early)
  : (CHUNK_PRIORITIES[chunkId] ?? 10);
```

### Step 5: Remove old adaptive scaling

Delete these from route.ts:
- `getAdaptiveTimeout` logic for 'clinical-deepdives'
- `getAdaptiveThinkingBudget` scaling for 'clinical-deepdives'
- References to single clinical-deepdives chunk

## Condition -> Chunk Mapping

| Flag | Chunk ID | Section Title |
|------|----------|---------------|
| adhd | clinical-adhd | 🧠 How Your Mind Works Differently (ADHD) |
| autism | clinical-autism | 🧩 Your Autistic Neurotype |
| autismMasking | clinical-masking | 🎭 Your Masking Patterns |
| anxiety | clinical-anxiety | 😰 Understanding Your Anxiety |
| depression | clinical-depression | 💙 Understanding Your Depression |
| ptsd | clinical-ptsd | 🌊 Understanding Your Trauma Response |
| highAce | clinical-ace | 🌱 Your Childhood Experiences |
| burnout | clinical-burnout | 🔥 Understanding Your Burnout |
| perfectionism | clinical-perfectionism | ⚡ Your Perfectionism Patterns |
| socialAnxiety | clinical-social-anxiety | 👥 Your Social Anxiety |
| codependency | clinical-codependency | 🔗 Your Codependency Patterns |
| substanceRisk | clinical-substance | 🍷 Understanding Your Relationship with Substances |
| sleepDifficulty | clinical-sleep | 😴 Your Sleep Patterns |
| clusterElevated.b | clinical-cluster-b | 🎭 Your Personality Style (Cluster B) |
| ... | ... | ... |

## Success Criteria

- Zero timeouts for any clinical section
- Complex profiles (10+ conditions) complete in <60s total (parallel)
- Each condition section is comprehensive despite smaller chunk
- Failed conditions retry independently (other conditions unaffected)
