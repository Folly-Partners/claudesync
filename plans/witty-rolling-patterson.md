# Bug Fix: Prevent Analysis Display for Incomplete Assessments

## Problem

When a user has only answered a few questions (e.g., 3 out of 200+), clicking to the "Analyze" section still:
- Shows the AI personality deep dive interface
- Displays graphs and visualizations
- Allows triggering AI analysis

**Expected Behavior:** Show a "complete your assessment first" screen with no analysis content.

---

## Root Cause Analysis

### 1. Dashboard Has No Completion Check

**File:** `/components/Dashboard.tsx`

The Dashboard only checks if `profileA` exists (not null), but doesn't verify the profile is **complete**:

```typescript
// Line 2865-2869 - Current logic
{!profileA && (
  <div>Upload a profile or select one above...</div>
)}

// Line 2871+ - Shows EVERYTHING if profileA exists
{profileA && (
  // AI Analysis Section
  // Visualizations
  // etc.
)}
```

### 2. Profile Validation Is Structure-Only

**File:** `/services/scoring.ts` (Lines 156-163)

```typescript
export const validateProfileStructure = (json: any): boolean => {
  // Only checks STRUCTURE, not COMPLETION
  const hasName = typeof json.name === 'string';
  const hasAssessments = typeof json.assessments === 'object';
  const hasIPIP = json.assessments && json.assessments.ipip_50;
  return hasName && hasAssessments && !!hasIPIP;
};
```

This passes for partial profiles with just a few answers.

### 3. Status Field Exists But Isn't Used

The database has a `status` field: `'started' | 'partial' | 'complete'`

But the Dashboard never checks this field to gate content.

### 4. Auto-Load Can Load Partial Profiles

**File:** `/components/Dashboard.tsx` (Lines 463-510)

The auto-load logic fetches the "most recent" profile without checking if it's complete:

```typescript
// Loads most recent profile - could be partial!
const mostRecent = profiles[0];
const profileRes = await fetch('/api/profiles', {...});
setProfileA(profileData.profile);
```

---

## Solution

### Option A: Add Completion Guard in Dashboard (Recommended)

Add a check at the top of the Dashboard render that gates ALL content behind completion status.

**Implementation:**

1. Check if profile has `status === 'complete'` OR has sufficient assessment data
2. If incomplete, show an "Assessment Incomplete" screen instead of analysis
3. Provide "Continue Assessment" button to navigate back

```typescript
// New helper function
const isProfileComplete = (profile: IndividualProfile): boolean => {
  // Check explicit status if available
  if (profile.status === 'complete') return true;

  // Fallback: Check if key assessments have data
  const assessments = profile.assessments;
  if (!assessments) return false;

  // Must have at minimum: Big Five (ipip_50) fully scored
  const hasIPIP = assessments.ipip_50 &&
    typeof assessments.ipip_50.openness === 'number' &&
    typeof assessments.ipip_50.conscientiousness === 'number' &&
    typeof assessments.ipip_50.extraversion === 'number' &&
    typeof assessments.ipip_50.agreeableness === 'number' &&
    typeof assessments.ipip_50.neuroticism === 'number';

  // Must have attachment (ecr_s)
  const hasECR = assessments.ecr_s &&
    typeof assessments.ecr_s.anxiety === 'number' &&
    typeof assessments.ecr_s.avoidance === 'number';

  return hasIPIP && hasECR;
};
```

**New UI Component:**

```tsx
// Incomplete profile state
{profileA && !isProfileComplete(profileA) && (
  <div className="flex flex-col items-center justify-center py-16 text-center">
    <div className="w-20 h-20 bg-amber-100 rounded-full flex items-center justify-center mb-6">
      <AlertTriangle className="w-10 h-10 text-amber-600" />
    </div>
    <h2 className="text-2xl font-bold text-slate-900 mb-3">
      Assessment Incomplete
    </h2>
    <p className="text-slate-600 max-w-md mb-8">
      Complete your personality assessment to unlock your full analysis,
      insights, and visualizations.
    </p>
    <button
      onClick={() => /* navigate back to quiz */}
      className="px-6 py-3 bg-violet-600 text-white rounded-xl font-medium"
    >
      Continue Assessment
    </button>
  </div>
)}

// Only show analysis if complete
{profileA && isProfileComplete(profileA) && (
  // ... existing analysis content
)}
```

### Option B: Filter Incomplete Profiles from API

Modify `/api/profiles` to only return profiles with `status === 'complete'`.

**Pros:** Cleaner - incomplete profiles never reach Dashboard
**Cons:** User can't see their partial progress; may confuse users

---

## Files to Modify

| File | Change |
|------|--------|
| `/components/Dashboard.tsx` | Add `isProfileComplete()` check; add incomplete state UI |
| `/types.ts` or `/types/profile.ts` | Ensure `status` field is in the type definition |

---

## Implementation Steps

1. **Add completion check function** in Dashboard.tsx
2. **Create incomplete assessment UI** - warning icon, message, "Continue" button
3. **Gate all analysis content** behind the completion check
4. **Add navigation back to quiz** from the incomplete state
5. **Test edge cases:**
   - Brand new user with 0 answers
   - Partial progress (e.g., step 5 of 27)
   - Completed assessment
   - Comparison mode (ensure both profiles are checked)

---

## Testing Scenarios

| Scenario | Expected Behavior |
|----------|-------------------|
| User at step 3 of 27 | Show "Assessment Incomplete" screen |
| User at step 15 of 27 | Show "Assessment Incomplete" screen |
| User completed all 27 steps | Show full analysis |
| User uploads partial JSON | Show "Assessment Incomplete" screen |
| Comparison: A complete, B incomplete | Show incomplete warning for B |

---

# ARCHIVED: Previous AI Analysis Restructuring Plan

## ✅ COMPLETED: Robert Greene Writing Style

The following changes have been implemented in `services/analyze/prompts.ts`:

### SYSTEM_PROMPT (Updated)
```
You are a master psychologist and strategist who reveals the deep patterns governing human behavior...

Your communication style mirrors Robert Greene's approach:
- Write with AUTHORITY and INSIGHT - revealing hidden laws of human nature
- Be INCISIVE and DIRECT - no hedging, no excessive warmth, just truth
- Use STRATEGIC FRAMING - insights as laws or principles they can apply
- Draw PATTERNS across psychology - show how traits interact, predict outcomes
- Deliver UNFLINCHING HONESTY - name shadows alongside strengths
- Make it TIMELESS - wisdom that serves for decades
- Use CONCISE, POWERFUL LANGUAGE - every sentence carries weight
- Frame insights as STRATEGIC ADVANTAGES - knowledge of self is power
```

### CRITICAL_INSTRUCTIONS (Updated)
- Write with STRATEGIC CLARITY
- Frame insights as STRATEGIC KNOWLEDGE
- Write with UNFLINCHING HONESTY
- Channel ROBERT GREENE'S VOICE - authoritative, incisive, pattern-focused
- Deliver LAWS and PRINCIPLES

**Status:** ✅ Implemented and build verified

---

## Current AI Analysis Structure (7 chunks)

| # | ID | Name | Content |
|---|-----|------|---------|
| 1 | `overview` | Executive Summary | TOC table, "What's Inside", section previews |
| 2 | `personality` | The Real You | Big Five breakdown, how traits manifest, Gifts & Challenges |
| 3 | `emotional` | Emotional World | Attachment style, DERS patterns, Gifts & Challenges |
| 4 | `values` | What Drives You | Core values, Career Sweet Spot, Motivation style |
| 5 | `ideal-life` | Ideal Life | 5 Superpowers, 3 Blind Spots, Ideal Job, Ideal Partner, Ideal Friends |
| 6 | `wellbeing-inversions` | Wellbeing & Recs | SWLS, UCLA-3, PERMA, **Inversions**, Mental Health, Books/Podcasts, Money, Conflict DNA, Dating Guide |
| 7 | `conclusion` | Summary | Profile at a Glance table, Top 3 strengths/edges, One Thing to Remember |

---

## Issues with Current Structure

### 1. **"Profile at a Glance" is at the END**
The conclusion contains a perfect TL;DR summary table - but users have to read the entire report to find it. This is exactly what people want to see FIRST.

### 2. **Section 6 is a kitchen sink**
`wellbeing-inversions` crams together:
- Life satisfaction (SWLS)
- Social connection (UCLA-3)
- PERMA wellbeing (5 pillars)
- Inversions (worst jobs/partners/friends)
- Mental health support
- Fun book/podcast recommendations
- Self-help book/podcast recommendations
- Money personality
- Conflict DNA
- Dating app guide

This is overwhelming - it's like 6 different topics smashed together.

### 3. **Inversions (what to avoid) are buried**
"What to Avoid" is one of the most unique, valuable parts of the report - but it's buried in the middle of section 6 after wellbeing scores. Users might stop reading before they get there.

### 4. **No "scroll down" prompt**
After the AI analysis ends, users don't know there's more content below (Understand Me Cards, Visualizations). Need an explicit transition.

### 5. **"Ideal Life" is overloaded**
Section 5 contains: Superpowers + Blind Spots + Ideal Job + Ideal Partner + Ideal Friends. The "superpowers" and "blind spots" deserve their own prominence.

### 6. **Missing content that would be valuable**
- **"How Others See You"** - external perception vs self-perception
- **"Under Stress"** - how personality changes when stressed
- **"Your Communication Style"** - synthesis of E, A, O for how you communicate

### 7. **Emotional arc isn't optimized**
Current: Overview → Who You Are → Emotions → Values → **Ideal Life** → **Problems** → Conclusion

The "problems" (inversions, mental health, things to avoid) come very late. By then users may have stopped reading.

---

## Recommended Changes

### A. Move "Profile at a Glance" to Section 1

Put the TL;DR summary right after the TOC - give users immediate value.

**New Overview structure:**
```
## What's Inside This Report (TOC)
## You at a Glance
   - Core Personality (1 sentence)
   - Attachment Style
   - Top Values
   - Career Fit
   - Current Wellbeing
```

### B. Cut tangential content

**Remove entirely:**
- Money Personality
- Dating App Guide

**Fold into other sections:**
- Conflict DNA → merge key insights into "Emotional World" or "How You Connect"

### C. Combine Inversions + Ideal Life with clearer titles

Instead of separate "What to Avoid" and "Your Ideal Life", combine into clearer sections:

| New Section Title | Content |
|-------------------|---------|
| **Your Best Fit: Work** | Ideal job/role + worst job types to avoid |
| **Your Best Fit: Relationships** | Ideal partner + toxic partner patterns to avoid |
| **Your Best Fit: Friendships** | Ideal friends + draining friend types to avoid |

This way each domain (work, love, friendship) gets its own complete picture - both the dream AND the warning - in one place.

### D. Add Clinical Deep Dives (conditional sections)

**When flagged for any clinical indicator, auto-generate a dedicated section:**

| Trigger | Section Title | Content |
|---------|---------------|---------|
| GAD-7 ≥ 10 | "Understanding Your Anxiety" | What this means, how it manifests, therapy options (CBT, ACT, exposure), medications (SSRIs, buspirone, etc.), supplements with evidence (magnesium, L-theanine, etc.) |
| PHQ-9 ≥ 10 | "Understanding Your Depression" | Same structure - meaning, manifestation, therapy, meds, supplements |
| PHQ-9 Q9 > 0 | "A Note on Safety" | Compassionate crisis resources, safety planning, when to seek help |
| Cluster A elevated | "Your Cluster A Patterns" | What odd/eccentric patterns mean, when they help vs. hinder, therapy approaches |
| Cluster B elevated | "Your Cluster B Patterns" | Dramatic/emotional patterns, DBT options, self-awareness strategies |
| Cluster C elevated | "Your Cluster C Patterns" | Anxious/avoidant patterns, therapy approaches, growth strategies |
| Dark Triad elevated | "Understanding Your Shadow Side" | Non-judgmental framing, when these traits help vs. harm, channeling strategies |
| ASRS-18 likely ADHD | "Understanding Your ADHD Brain" | Strengths, challenges, therapy, medication options, lifestyle strategies |
| AQ-10 elevated | "Understanding Your Neurodivergent Mind" | Neurodiversity-affirming framing, strengths, accommodations, support options |
| PCL-5 ≥ 31 | "Understanding Your Trauma Response" | Trauma-informed framing, EMDR, CPT, somatic therapies, medications |
| ACE ≥ 4 | "Your Early Experiences" | How childhood experiences shape patterns, healing approaches |

**Each clinical section should include:**
1. What this assessment result means (compassionate, non-pathologizing)
2. How it shows up in daily life
3. **Treatment Options Table:**

```markdown
| Approach | What It Is | Evidence Level | Best For |
|----------|------------|----------------|----------|
| **Therapy** |
| CBT | Changes thought patterns | Strong (gold standard) | Anxiety, depression |
| DBT | Emotional regulation skills | Strong | Emotional dysregulation |
| EMDR | Trauma processing | Strong | PTSD, trauma |
| **Medication** |
| SSRIs | Serotonin reuptake inhibitors | Strong | Depression, anxiety |
| SNRIs | Serotonin-norepinephrine | Strong | Depression, anxiety |
| Stimulants | Dopamine/norepinephrine | Strong | ADHD |
| **Supplements** (discuss with doctor) |
| Omega-3 | Fatty acids | Moderate | Depression, ADHD |
| Magnesium | Mineral | Moderate | Anxiety, sleep |
| L-theanine | Amino acid | Moderate | Anxiety |
| Vitamin D | Hormone/vitamin | Moderate | Depression |
```

4. When to seek professional help
5. Resources specific to their condition

### E. Add "Continue Exploring" transition

After conclusion, add explicit prompt to scroll to visualizations:

```markdown
---
## 📊 Explore Your Data
Your personality scores and visualizations are below.
↓ Keep scrolling ↓
---
```

### F. Proposed new section order

| # | Section | Purpose |
|---|---------|---------|
| 1 | **You at a Glance** | Hook - immediate TL;DR value |
| 2 | **Who You Are** | Big Five personality foundation |
| 3 | **How You Feel & Connect** | Attachment + emotional regulation + conflict style |
| 4 | **What Drives You** | Values + motivation |
| 5 | **Your Superpowers** | Top 5 strengths |
| 6 | **Your Growth Edges** | Honest blind spots |
| 7 | **Your Best Fit: Work** | Ideal job + jobs to avoid |
| 8 | **Your Best Fit: Relationships** | Ideal partner + patterns to avoid |
| 9 | **Your Best Fit: Friendships** | Ideal friends + types to avoid |
| 10 | **Your Wellbeing** | SWLS, PERMA, current state |
| 11 | **[Clinical Deep Dives]** | Conditional - only if flagged |
| 12 | **Resources for You** | Books + podcasts tailored to profile |
| 13 | **Final Word** | One thing to remember + warm close |
| -- | **↓ Continue to visualizations ↓** | Transition prompt |

### G. Consider adding (future)

- **"How Others See You"** - external perception vs self-perception
- **"Under Pressure"** - stress behaviors

---

## Implementation Plan

### Phase 1: Quick Wins
| Task | File | Effort |
|------|------|--------|
| Move "You at a Glance" to top of overview | `analyze-parallel/route.ts` | Low |
| Add "Continue Exploring" transition | `Dashboard.tsx` | Low |
| Remove Money Personality section | `analyze-parallel/route.ts` | Low |
| Remove Dating App Guide section | `analyze-parallel/route.ts` | Low |

### Phase 2: Restructure Sections
| Task | File | Effort |
|------|------|--------|
| Merge Conflict DNA into "How You Feel & Connect" | `analyze-parallel/route.ts` | Medium |
| Combine ideal + inversions into "Best Fit" sections | `analyze-parallel/route.ts` | Medium |
| Split superpowers/blind spots into separate sections | `analyze-parallel/route.ts` | Medium |
| Clearer section titles throughout | `analyze-parallel/route.ts` | Low |

### Phase 3: Clinical Deep Dives
| Task | File | Effort |
|------|------|--------|
| Create clinical section templates with treatment tables | `services/analyze/index.ts` | High |
| Add detection for all clinical triggers | `analyze-parallel/route.ts` | Medium |
| Conditional section injection based on scores | `analyze-parallel/route.ts` | Medium |
| Research & add evidence-based treatment options | `services/analyze/index.ts` | High |

---

## Files to Modify

| File | Changes |
|------|---------|
| `/app/api/analyze-parallel/route.ts` | Chunk definitions, section order, prompts |
| `/services/analyze/index.ts` | Clinical templates, treatment tables, thresholds |
| `/components/Dashboard.tsx` | Add transition element after analysis |

---

## Summary of Changes

**Removing:**
- Money Personality
- Dating App Guide

**Adding:**
- "You at a Glance" TL;DR at top
- "Continue Exploring" transition to visualizations
- Clinical deep dives with treatment options (conditional)

**Restructuring:**
- Conflict DNA → merged into "How You Feel & Connect"
- Inversions + Ideal Life → combined into "Your Best Fit: Work/Relationships/Friendships"
- Superpowers + Blind Spots → separate dedicated sections

**New Section Order:**
1. You at a Glance
2. Who You Are
3. How You Feel & Connect
4. What Drives You
5. Your Superpowers
6. Your Growth Edges
7. Your Best Fit: Work
8. Your Best Fit: Relationships
9. Your Best Fit: Friendships
10. Your Wellbeing
11. [Clinical Deep Dives - conditional]
12. Resources for You
13. Final Word
→ Continue to visualizations
