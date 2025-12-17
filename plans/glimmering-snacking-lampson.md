# Plan: Homepage Redesign - Jason Fried & Chip Heath Style

## The Problem with Current Copy

The current homepage uses typical SaaS marketing:
- Feature-heavy ("18 clinically validated instruments")
- List-based (bullets of benefits)
- Marketing-speak ("comprehensive," "scientific precision")
- Tells people what it does, not why it matters

## Design Philosophy

### Jason Fried (Basecamp)
- Contrarian: Challenge what people assume
- Direct: Short, punchy sentences
- Problem-first: Lead with the pain point
- Anti-hype: Understated confidence
- Opinionated: Take a stance

### Chip Heath (Made to Stick)
- **Simple**: One core message
- **Unexpected**: Break patterns
- **Concrete**: Specific, not abstract
- **Credible**: Proof that resonates
- **Emotional**: Identity, not features
- **Stories**: Show, don't tell

---

## New Copy Direction

### Hero - The Hook (SELECTED)

**Headline:**
> "In 25 minutes, you'll understand yourself better than a therapist would after 10 sessions."

**Subhead:**
> "The same assessments therapists charge $400/hour to interpret. AI-analyzed. Free. Yours to keep forever."

### Three Cards - Transform Features into Outcomes
**Current:** "Romantic Life", "Professional Life", "Personal Growth" with feature lists

**New approach - specific, relatable scenarios:**

**Card 1: "Why does this keep happening?"**
> Finally understand your relationship patterns.
> Why you pick who you pick. Why fights escalate.
> What you actually need (not what you think you need).

**Card 2: "Wrong job, right person"**
> You're not lazy. You're not unmotivated.
> You might just be in the wrong environment.
> Find out what actually drives you.

**Card 3: "The honest mirror"**
> No positive affirmations. No toxic positivity.
> Just the truth about your mental health, resilience,
> and what's actually holding you back.

### AI Analysis Section
**Current:** Feature checklist with green checkmarks

**New approach - make it tangible:**
> "You'll get a 10,000-word analysis that reads like
> a letter from someone who's known you for years.
>
> Download it. Share it with your therapist.
> Use it to train ChatGPT to actually understand you."

### CTA Section
**Current:** "Sign In / Register" + "Continue as Guest"

**New approach - reduce friction, increase curiosity:**
> **Primary:** "Start the assessment" (not "Sign In")
> **Secondary:** "See a sample report first"
> **Micro-copy:** "25 minutes. No payment. Your data stays yours."

---

## Visual Design Changes

1. **Remove emoji overload** - One accent, not emoji soup
2. **More whitespace** - Let copy breathe
3. **Single column hero** - Focus attention
4. **Cards → Stories** - Less grid, more narrative flow
5. **Darker, confident palette** - Less pastel SaaS
6. **One CTA above fold** - Don't overwhelm

---

## File to Modify

| File | Changes |
|------|---------|
| `components/Wizard.tsx` | Lines 874-977 - Complete rewrite of Step 0 marketing section |

---

## Implementation

Single file change in `Wizard.tsx`, replacing the marketing section (lines 874-977) with new copy and simplified design.

### Key Sections to Rewrite:
1. Hero headline + subhead (lines 878-883)
2. Three feature cards (lines 887-903)
3. AI analysis highlight box (lines 906-933)
4. Pro tip section (lines 936-940)
5. CTA buttons + micro-copy (lines 942-970)
