# Plan: Speed Up AI Personality Analysis

## Problem
AI personality analysis takes 5-10 minutes. The `ideal-life` chunk (24k thinking budget) is a monolithic bottleneck.

## Solution: Split `ideal-life` into 4 Parallel Chunks

**Current:** 1 chunk × 24k thinking = sequential bottleneck
**After:** 4 chunks × 8k thinking = parallel execution

### New Chunk Structure

| New Chunk | Content | Budget | Model |
|-----------|---------|--------|-------|
| `superpowers` | 5 Superpowers + 3 Growth Edges | 10k | Haiku |
| `best-fit-work` | Ideal Job + 2 Jobs to Avoid | 10k | Sonnet |
| `best-fit-romantic` | Ideal Partner + 2 Partners to Avoid | 10k | Sonnet |
| `best-fit-friends` | Ideal Friends + 2 Friends to Avoid | 8k | Haiku |

**Also trim:** "What to Avoid" from 5 archetypes → 2

## Changes

### 1. Add 4 new chunks, remove `ideal-life`

**File:** `/Users/andrewwilkinson/Deep-Personality/app/api/analyze-parallel/route.ts`

**A. Update THINKING_BUDGETS (~line 156):**
```typescript
const THINKING_BUDGETS: Record<string, number> = {
  'overview': 10000,
  'personality': 16000,
  'emotional': 20000,
  'values': 20000,
  // 'ideal-life': 24000,  // REMOVED - split into 4 chunks below
  'superpowers': 10000,      // NEW
  'best-fit-work': 10000,    // NEW
  'best-fit-romantic': 10000, // NEW
  'best-fit-friends': 8000,  // NEW
  'wellbeing-base': 20000,
  'resources': 10000,
  'conclusion': 16000,
  // ... comparison chunks unchanged
};
```

**B. Update CHUNK_MODEL_ROUTING (~line 41):**
```typescript
const CHUNK_MODEL_ROUTING: Record<string, 'sonnet' | 'haiku'> = {
  'overview': 'haiku',
  'superpowers': 'haiku',        // NEW - fast
  'best-fit-work': 'sonnet',     // NEW - needs reasoning
  'best-fit-romantic': 'sonnet', // NEW - needs reasoning
  'best-fit-friends': 'haiku',   // NEW - simpler
  'resources': 'haiku',
  'conclusion': 'haiku',
  // Complex chunks stay on Sonnet
  'personality': 'sonnet',
  'emotional': 'sonnet',
  'values': 'sonnet',
  'wellbeing-base': 'sonnet',
};
```

**C. Update CHUNK_PRIORITIES (~line 2037):**
```typescript
const CHUNK_PRIORITIES: Record<string, number> = {
  'best-fit-work': 0,        // Start complex chunks first
  'best-fit-romantic': 0,
  'emotional': 1,
  'values': 2,
  'wellbeing-base': 3,
  'best-fit-friends': 4,
  'personality': 5,
  'superpowers': 6,          // Fast, can start later
  'resources': 7,
  'overview': 8,
  'conclusion': 9,
};
```

**D. Update REPORT_ORDER (~line 2049):**
```typescript
const REPORT_ORDER: Record<string, number> = {
  'overview': 0,
  'personality': 1,
  'emotional': 2,
  'values': 3,
  'superpowers': 4,          // NEW
  'best-fit-work': 5,        // NEW
  'best-fit-romantic': 6,    // NEW
  'best-fit-friends': 7,     // NEW
  'wellbeing-base': 8,
  'resources': 100,
  'conclusion': 101,
};
```

### 2. Replace `ideal-life` chunk with 4 new chunks

**Location:** `getIndividualChunks()` function (~line 183)

**Remove:** The entire `ideal-life` chunk definition (id: 'ideal-life', ~249 lines)

**Add 4 new chunks:**

```typescript
// --- CHUNK 1: Superpowers & Growth Edges ---
{
  id: 'superpowers',
  name: 'Your Superpowers',
  buildPrompt: (profile, _, relationshipType) => `
Here is ${name}'s psychological profile:
${JSON.stringify(getRelevantProfileData(profile, 'ideal-life'), null, 2)}

${SCORING_CONTEXT}

Write ONLY the "Your Superpowers" and "Your Growth Edges" sections.

## 💪 Your Superpowers
List 5 specific strengths from ${name}'s profile. For each: name it, explain how it shows up, give an example, suggest how to leverage it.

## 🌱 Your Growth Edges (The Honest Part)
### 3 Blind Spots to Watch
Be direct but kind. For each: name it, explain how it limits them, give a sign to watch for, offer one concrete action.

Use markdown formatting. Be specific to THIS person.`
},

// --- CHUNK 2: Best Fit Work ---
{
  id: 'best-fit-work',
  name: 'Best Fit: Work',
  buildPrompt: (profile, _, relationshipType) => `
Here is ${name}'s psychological profile:
${JSON.stringify(getRelevantProfileData(profile, 'ideal-life'), null, 2)}

${SCORING_CONTEXT}

Write ONLY the "Best Fit: Work" section.

## 💼 Best Fit: Work

### ✅ Your Ideal Job/Role
Based on RIASEC, Big Five, values, and motivation:

| ✅ Success Requirements | Why You'll Fail Without This |
|------------------------|------------------------------|
| [Non-negotiable element] | [What happens without it] |
| [Another requirement] | [The cost of ignoring] |

**Specific Roles That Fit:** 5 job titles that match their profile.

### 🚫 Jobs to Avoid
2 job types that would be terrible fits:

#### Job Type 1: [Archetype Name]
| ❌ Element | Why It Clashes |
|-----------|----------------|
| [Aspect] | [Brief reason] |
**Example Roles:** [2-3 job titles]

#### Job Type 2: [Archetype Name]
| ❌ Element | Why It Clashes |
|-----------|----------------|
| [Aspect] | [Brief reason] |
**Example Roles:** [2-3 job titles]

Use markdown formatting.`
},

// --- CHUNK 3: Best Fit Romantic ---
{
  id: 'best-fit-romantic',
  name: 'Best Fit: Relationships',
  buildPrompt: (profile, _, relationshipType) => `
Here is ${name}'s psychological profile:
${JSON.stringify(getRelevantProfileData(profile, 'ideal-life'), null, 2)}

${SCORING_CONTEXT}

Write ONLY the "Best Fit: Relationships" section.

## 💕 Best Fit: Relationships

### ✅ Your Ideal Partner
| ✅ Relationship Requirements | What Happens Without This |
|----------------------------|---------------------------|
| [Non-negotiable trait] | [The dysfunction that results] |
| [Another requirement] | [Why you'll struggle] |

**Attachment Compatibility:** What kind of partner helps ${name} feel secure?

### 💔 Partners to Avoid
2 partner types that would create suffering:

#### Partner Type 1: The [Archetype Name]
| ❌ Their Traits | Why This Hurts You |
|----------------|-------------------|
| [Key trait] | [How it triggers attachment] |
**The Dynamic:** [What the relationship would look like]

#### Partner Type 2: The [Archetype Name]
| ❌ Their Traits | Why This Hurts You |
|----------------|-------------------|
| [Key trait] | [How it clashes] |
**The Dynamic:** [The relationship pattern]

Use markdown formatting.`
},

// --- CHUNK 4: Best Fit Friends ---
{
  id: 'best-fit-friends',
  name: 'Best Fit: Friendships',
  buildPrompt: (profile, _, relationshipType) => `
Here is ${name}'s psychological profile:
${JSON.stringify(getRelevantProfileData(profile, 'ideal-life'), null, 2)}

${SCORING_CONTEXT}

Write ONLY the "Best Fit: Friendships" section.

## 👥 Best Fit: Friendships

### ✅ Your Ideal Friends
| ✅ Social Requirements | What Happens Without This |
|----------------------|---------------------------|
| [Type of friend needed] | [Isolation that results] |

**Social Circle Size:** Based on extraversion, what's optimal?

### 👎 Friends to Avoid
2 friend types that drain energy:

#### Toxic Friend Type 1: The [Archetype Name]
| ❌ Their Traits | Why This Drains You |
|----------------|-------------------|
| [Key trait] | [How it depletes ${name}] |

#### Toxic Friend Type 2: The [Archetype Name]
| ❌ Their Traits | Why This Drains You |
|----------------|-------------------|
| [Key trait] | [The dynamic it creates] |

Use markdown formatting.`
},
```

### 3. Reduce `resources` budget

**Location:** HAIKU_THINKING_BUDGETS (~line 68)
```typescript
'resources': 3000,  // Was 5000
```

## Expected Impact

| Before | After |
|--------|-------|
| 1 × `ideal-life` @ 24k = 4-5 min bottleneck | 4 chunks @ 8-10k each, running in parallel |
| All 4 sections wait on 1 chunk | Each section starts immediately |
| **Total: 5-10 min** | **Target: 2-4 min** |

## Files to Modify

1. `/Users/andrewwilkinson/Deep-Personality/app/api/analyze-parallel/route.ts`
   - THINKING_BUDGETS: Add 4 new entries, remove `ideal-life`
   - CHUNK_MODEL_ROUTING: Add routing for new chunks
   - CHUNK_PRIORITIES: Reorder for optimal parallel start
   - REPORT_ORDER: Set output order for new chunks
   - `getIndividualChunks()`: Replace `ideal-life` with 4 new chunk definitions
