# Dynamic Personalized Teasers for PremiumGate

## Summary
Transform the static, generic paywall teasers into dynamic, personalized teasers that reference users' actual assessment results. This creates psychological curiosity gaps that increase conversion while maintaining compassionate, non-clinical language.

## Current State
- `PremiumGate.tsx` shows static arrays (`LOCKED_INSIGHTS_INDIVIDUAL`, `LOCKED_INSIGHTS_COMPARISON`)
- Props are minimal: `email`, `contentType`, `contentId`, `onUnlock`, `previewContent`
- Full profile data is available in Dashboard but NOT passed to PremiumGate
- Same teasers shown to every user regardless of their unique patterns

## Goal
Show teasers that feel personally relevant:
- "Your attachment style is **Anxious-Preoccupied**. This means you—" [blurred]
- "At the **91st percentile** for rejection sensitivity, you..." [blurred]
- "We found **3 specific triggers** shaping your relationships..." [blurred]

---

## Implementation Plan

### Phase 1: Create Teaser Generation Utility

**New file: `/lib/teaser-insights.ts`**

```typescript
export interface TeaserInsight {
  id: string;
  emoji: string;
  title: string;
  teaser: string;
  isPersonalized: boolean;
  priority: number; // Higher = more compelling
}

export interface ProfileTeaserData {
  // Individual mode
  insights: TeaserInsight[];
  personalizedHeadline: string;
  personalizedSubhead: string;

  // Comparison mode additions
  relationshipDynamics?: TeaserInsight[];
}

export function generateTeaserData(
  profileA: IndividualProfile,
  profileB?: IndividualProfile | null,
  contentType: 'full_report' | 'comparison'
): ProfileTeaserData
```

**Key functions to implement:**
1. `findNotablePatterns(profile)` - Identify top 3-5 compelling aspects
2. `selectTeaserTemplates(patterns)` - Match patterns to teaser copy
3. `generatePersonalizedHeadline(patterns)` - Dynamic headline based on profile
4. `applyEthicalGuardrails(teasers, clinicalFlags)` - Soften language for high-severity profiles

### Phase 2: Pattern Recognition Logic

**Priority order for selecting which aspects to tease:**

| Priority | Pattern Type | Detection Logic |
|----------|-------------|-----------------|
| 1 | Suicidal ideation | `phq_9.suicidalIdeationFlag === true` → Use supportive-only mode |
| 2 | Anxious attachment | `ecr_s.anxiety.raw >= 4.0` |
| 3 | Avoidant attachment | `ecr_s.avoidance.raw >= 4.0` |
| 4 | ADHD flagged | `asrs_18.likelyADHD === true` |
| 5 | Autism/masking | `aq_10.likelyAutistic OR cat_q.significantMasking` |
| 6 | High rejection sensitivity | `rsq.score >= 10` |
| 7 | Extreme Big Five (85th+/15th-) | Any domain at extremes |
| 8 | Value-behavior conflicts | `topValues` conflicts with Big Five patterns |
| 9 | Low wellbeing paradox | e.g., high accomplishment + low meaning |

**For comparison mode, add:**
- Attachment style mismatch detection
- Big Five gap analysis (>40 percentile gap)
- Opposing values detection (Schwartz circumplex)
- Pursuer-distancer dynamic detection

### Phase 3: Teaser Templates

**Individual Mode Examples:**

```typescript
const TEASER_TEMPLATES = {
  'attachment:anxious': {
    emoji: '💔',
    title: 'Your Core Pattern',
    teaser: 'Why closeness triggers fear (and what to do about it)...',
  },
  'clinical:adhd': {
    emoji: '🧠',
    title: 'Your Attention Diversity', // From compassionate-framing.ts
    teaser: 'Why your brain works differently (and how to work with it)...',
  },
  'bigfive:neuroticism:high': (percentile: number) => ({
    emoji: '🌊',
    title: 'Your Emotional Intensity',
    teaser: `At the ${percentile}th percentile, you feel everything deeply. Here's why...`,
  }),
  // ... more templates
};
```

**Comparison Mode Examples:**

```typescript
const COMPARISON_TEMPLATES = {
  'attachment:mismatch': (nameA, styleA, nameB, styleB) => ({
    emoji: '🔥',
    title: 'Your Attachment Dance',
    teaser: `${nameA}'s ${styleA} meets ${nameB}'s ${styleB}. See the pattern...`,
  }),
  'values:opposition': (nameA, valueA, nameB, valueB) => ({
    emoji: '⚔️',
    title: 'Your Value Collision',
    teaser: `${valueA} vs. ${valueB}: the hidden battleground...`,
  }),
  // ... more templates
};
```

### Phase 4: Update PremiumGate Component

**Changes to `/components/PremiumGate.tsx`:**

1. **Expand props interface:**
```typescript
interface PremiumGateProps {
  email: string;
  contentType: 'full_report' | 'comparison';
  contentId: string;
  onUnlock?: () => void;
  previewContent?: string;
  // NEW
  teaserData?: ProfileTeaserData;
}
```

2. **Dynamic headline rendering:**
```tsx
<h2 className="text-3xl md:text-4xl font-bold text-white text-center mb-4">
  {teaserData?.personalizedHeadline || defaultHeadline}
</h2>
```

3. **Personalized teaser cards with "Based on your results" badge:**
```tsx
{insights.map((teaser) => (
  <div key={teaser.id} className={`... ${teaser.isPersonalized ? 'ring-2 ring-pink-400/30' : ''}`}>
    <span>{teaser.emoji}</span>
    <div>
      <h4>{teaser.title}</h4>
      <p>{teaser.teaser}</p>
      {teaser.isPersonalized && (
        <span className="text-xs text-pink-300 mt-1">Based on your results</span>
      )}
    </div>
  </div>
))}
```

### Phase 5: Dashboard Integration

**Changes to `/components/Dashboard.tsx` (around line 3229):**

```typescript
import { generateTeaserData } from '@/lib/teaser-insights';

// Memoize to avoid recalculation
const teaserData = useMemo(() => {
  if (!profileA) return undefined;
  return generateTeaserData(
    profileA,
    profileB,
    profileB ? 'comparison' : 'full_report'
  );
}, [profileA, profileB]);

// Pass to PremiumGate
<PremiumGate
  email={user?.email || ''}
  contentType={profileB ? 'comparison' : 'full_report'}
  contentId={profileA?.id || ''}
  onUnlock={() => setIsUnlocked(true)}
  teaserData={teaserData}
/>
```

---

## Ethical Guardrails

**Critical safety checks before showing any teaser:**

```typescript
function applyEthicalGuardrails(
  teasers: TeaserInsight[],
  profile: IndividualProfile
): TeaserInsight[] {
  const crisis = useShouldShowCrisis(profile.assessments);

  // CRITICAL: Suicidal ideation flag
  if (profile.assessments.phq_9?.suicidalIdeationFlag) {
    return SUPPORTIVE_ONLY_TEASERS;
  }

  // HIGH severity: Use only supportive language
  if (crisis.severity === 'critical' || crisis.severity === 'high') {
    return teasers.map(t => softenLanguage(t));
  }

  return teasers;
}
```

**Language transformations for sensitive profiles:**

| Avoid | Use Instead |
|-------|-------------|
| "Your core wound" | "Patterns that shaped you" |
| "What's broken" | "How you've adapted" |
| "Your trauma" | "Your lived experience" |
| "Before it's too late" | "When you're ready" |

---

## File Changes Summary

| File | Action |
|------|--------|
| `/lib/teaser-insights.ts` | **CREATE** - Core teaser generation logic |
| `/components/paywall/BlurredInsight.tsx` | **CREATE** - Reusable blurred preview component |
| `/components/paywall/GlimpseGrid.tsx` | **CREATE** - The visual "what we discovered" section |
| `/components/paywall/ScoreGauge.tsx` | **CREATE** - Mini gauge visualization for scores |
| `/components/PremiumGate.tsx` | **MODIFY** - Accept `teaserData` prop, integrate GlimpseGrid |
| `/components/Dashboard.tsx` | **MODIFY** - Compute `teaserData` with useMemo, pass to PremiumGate |

**Existing files to leverage (read-only):**
- `/lib/compassionate-framing.ts` - Use `nonPathologizingName` from framings
- `/components/CrisisResources.tsx` - Use `useShouldShowCrisis` for guardrails
- `/services/analyze/helpers.ts` - Use `detectTriggeredClinicalConditions`
- `/types.ts` - `IndividualProfile` type definitions

---

## Visual Elements Design

**The user requested dramatic visual teasers with:**
- Blurred gauge charts
- Partial text cutoffs mid-sentence
- Visual data hints

### Visual Component: Blurred Data Previews

**New component: `/components/paywall/BlurredInsight.tsx`**

```tsx
interface BlurredInsightProps {
  type: 'gauge' | 'quadrant' | 'text' | 'list';
  visibleData: string | number;  // What they CAN see
  hiddenLabel?: string;          // What's blurred
}
```

**Example implementations:**

1. **Attachment Quadrant (for comparison)**
```tsx
<div className="relative">
  {/* Quadrant chart with both dots visible */}
  <AttachmentPlot profileA={...} profileB={...} />
  {/* Blur overlay on labels/interpretation */}
  <div className="absolute inset-0 backdrop-blur-sm bg-gradient-to-t from-slate-900/80">
    <p className="text-purple-200">Your attachment dance: ████████████</p>
  </div>
</div>
```

2. **Score Gauge with Hidden Meaning**
```tsx
<div className="flex items-center gap-4">
  <div className="relative w-20 h-20">
    {/* Gauge showing needle position */}
    <GaugeChart value={89} max={100} />
    {/* Label is blurred */}
    <span className="blur-sm">Rejection Sensitivity</span>
  </div>
  <div>
    <p className="text-white font-bold">89th percentile</p>
    <p className="text-purple-200/70 blur-[3px]">
      This means you detect rejection signals before...
    </p>
  </div>
</div>
```

3. **Mid-Sentence Text Cutoff**
```tsx
<div className="bg-white/5 rounded-lg p-4 border border-white/10">
  <h4 className="text-white font-bold">Your Core Pattern</h4>
  <p className="text-purple-200">
    Your attachment style is <span className="text-pink-300 font-semibold">Anxious-Preoccupied</span>.
    This means you tend to—
    <span className="blur-[4px] select-none">
      seek reassurance frequently and may interpret neutral
      signals as rejection. The pattern typically develops when...
    </span>
  </p>
</div>
```

4. **Numbered List with Hidden Items**
```tsx
<div className="space-y-2">
  <p className="text-white text-sm font-medium">We identified 5 patterns:</p>
  <div className="space-y-1.5">
    <div className="flex items-center gap-2">
      <span className="text-pink-400">1.</span>
      <span className="text-purple-200">Your fear of abandonment shows up as—</span>
      <span className="blur-[3px] text-purple-200">checking behavior</span>
    </div>
    <div className="flex items-center gap-2 blur-[4px]">
      <span className="text-pink-400">2.</span>
      <span className="text-purple-200">████████████████████</span>
    </div>
    <div className="flex items-center gap-2 blur-[4px]">
      <span className="text-pink-400">3.</span>
      <span className="text-purple-200">████████████████████</span>
    </div>
    {/* Items 4-5 fully hidden */}
  </div>
</div>
```

### Layout: The "Glimpse Grid"

**Main paywall layout with visual elements:**

```
┌─────────────────────────────────────────────────────────────────┐
│                         🔒                                      │
│           "Finally understand why you feel this way."           │
│                                                                 │
│   Your heightened alertness isn't a flaw—it's your brain       │
│   trying to keep you safe. See what this means.                │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ ✨ What We Discovered                                    │   │
│  │                                                          │   │
│  │ Your attachment style: Anxious-Preoccupied               │   │
│  │ This means you━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │   │
│  │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────┐  ┌──────────────────┐                    │
│  │  [GAUGE: 89th]   │  │  [GAUGE: 94th]   │                    │
│  │  ████████████    │  │  ████████████    │                    │
│  │  Rejection       │  │  Emotional       │                    │
│  │  Sensitivity     │  │  Intensity       │                    │
│  └──────────────────┘  └──────────────────┘                    │
│                                                                 │
│  We found 5 patterns:                                           │
│  1. Your fear of— ████████████                                 │
│  2. ████████████████████████                                   │
│  3. ████████████████████████                                   │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  💔 Your Core Pattern    │  🧠 Your Attention Diversity        │
│  Why closeness triggers  │  Why your brain works               │
│  fear...                 │  differently...                      │
│  [Based on your results] │  [Based on your results]            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│           [ 🔓 See What We Found — $19 ]                       │
│                                                                 │
│           🛡️ 100% Money-Back Guarantee                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Additional Files Needed

| File | Purpose |
|------|---------|
| `/components/paywall/BlurredInsight.tsx` | **CREATE** - Reusable blurred preview component |
| `/components/paywall/GlimpseGrid.tsx` | **CREATE** - The visual "what we discovered" section |
| `/components/paywall/ScoreGauge.tsx` | **CREATE** - Mini gauge visualization for scores |

---

## Example Output

### Individual (Anxious Attachment + High Neuroticism + ADHD)

**Headline:** "Finally understand why you feel this way."

**Subhead:** "Your heightened alertness isn't a flaw—it's your brain trying to keep you safe."

**Teasers:**
1. 💔 **Your Core Pattern** — "Why closeness triggers fear..." `[Based on your results]`
2. 🧠 **Your Attention Diversity** — "Why your brain works differently..." `[Based on your results]`
3. 🌊 **Your Emotional Intensity** — "At the 89th percentile..." `[Based on your results]`
4. 🛡️ **Your Defense Mechanisms** — "The walls you've built..."
5. 💕 **Your Ideal Partner Type** — "Who can actually help you feel secure..."
6. 🔮 **5 Specific Predictions** — "What happens if nothing changes..."

### Comparison (Anxious + Avoidant Pairing)

**Headline:** "See the full picture of Alex + Sam."

**Subhead:** "Alex's need for closeness meets Sam's need for space. This creates a specific pattern."

**Teasers:**
1. 🔥 **Your Attachment Dance** — "The push-pull pattern you can't escape..." `[Based on your results]`
2. ⚔️ **Your Value Collision** — "Stimulation vs. Security..." `[Based on your results]`
3. 🗣️ **Why You Misunderstand** — "What Alex needs vs. what Sam says..."
4. 🧩 **Where You Complete Each Other** — "Your complementary strengths..."
5. 💔 **The Breaking Point** — "The scenario that could end this..."
6. 🌟 **Your Superpower Together** — "What you can achieve together..."

---

## Testing Strategy

1. Test with example profiles (`example_profile.json`, `example_profile_sam.json`)
2. Verify fallback to static teasers when no notable patterns detected
3. Confirm ethical guardrails activate for high-severity clinical flags
4. Test both individual and comparison modes
5. Verify no visible performance lag from teaser computation
