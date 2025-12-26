# Plan: Enhance AI Analysis Report Resource Recommendations

## Goal
Upgrade the resource recommendations in Deep Personality AI analysis reports to include specific, evidence-based podcast episodes from high-quality shows like Huberman Lab, FoundMyFitness, and The Drive with Peter Attia.

## Current State
- **File**: `/Users/andrewwilkinson/Deep-Personality/services/analyze/prompts.ts`
- Resource recommendations exist in `CLINICAL_SECTION_TEMPLATES` (lines 152-689)
- Current format includes generic podcast names (e.g., "ADHD Experts Podcast") without specific episodes
- Books are already specific titles

## Clinical Conditions Needing Updated Podcast Recommendations

| Condition | Line Numbers | Current Podcast Recommendations |
|-----------|-------------|--------------------------------|
| ADHD | 186-189 | ADHD Experts Podcast, Hacking Your ADHD |
| Autism | 240-244 | The Neurodivergent Woman, Autism in Adulthood, Embracing Autism |
| Sensory Processing | 276-279 | None listed |
| Anxiety | 303-307 | The Anxious Truth, Anxiety Slayer, The Calm Collective |
| Depression | 333-337 | The Hilarious World of Depression, Mental Illness Happy Hour |
| PTSD/Trauma | 360-363 | Trauma Therapist Podcast, The Trauma-Informed Lens |
| High ACE | 388-392 | Adult Child, The Place We Find Ourselves |
| Dark Triad | 415-418 | Understanding Today's Narcissist |
| High Conflict Personality | 474-478 | High Conflict Institute, Understanding Today's Narcissist |
| Burnout | 505-508 | WorkLife with Adam Grant, The Happiness Lab |
| Perfectionism | 532-535 | Unlocking Us (Brown), Self-Compassion with Kristin Neff |
| Social Anxiety | 561-564 | The Anxious Truth, Social Anxiety Solutions |
| Codependency | 591-594 | Codependency No More, Beyond Bitchy |
| Substance Risk | 621-624 | Recovery Happy Hour, The Dopey Podcast |
| Compulsive Behaviors | 684-688 | The Happiness Lab, Recovery Happy Hour |

## Proposed Changes

### Update Each Clinical Section's Podcast Recommendations To:

1. **Keep existing specialty podcasts** where relevant (they're often condition-specific)
2. **Add specific episodes** from evidence-based shows:
   - **Huberman Lab** - Specific episodes with guest experts or deep dives
   - **FoundMyFitness (Dr. Rhonda Patrick)** - Specific episodes on relevant topics
   - **The Drive (Dr. Peter Attia)** - Specific episodes with psychiatrists/researchers

### Example Format Change

**Before:**
```
**Resources:**
- Podcasts: *ADHD Experts Podcast*, *Hacking Your ADHD*
```

**After:**
```
**Resources:**
- Podcasts:
  - Huberman Lab: "ADHD & How Anyone Can Improve Their Focus" (Episode #37)
  - Huberman Lab: "Dr. Wendy Suzuki: Boost Attention & Memory"
  - The Drive: "#196 - John Ratey, M.D.: ADHD, exercise, and the brain"
  - *ADHD Experts Podcast*, *Hacking Your ADHD*
```

## Files to Modify
- `/Users/andrewwilkinson/Deep-Personality/services/analyze/prompts.ts` - Main prompts file

## Decisions Made
- **Research specific episodes** from Huberman Lab, FoundMyFitness, and The Drive
- **2-3 episodes per condition** - focused, high-impact recommendations
- **Replace existing podcasts entirely** - only use evidence-based shows

---

## Curated Podcast Episodes by Condition

### ADHD (Lines 186-189)
```
- Huberman Lab: "ADHD & How Anyone Can Improve Their Focus" (Essentials episode)
- Huberman Lab: "Dr. Wendy Suzuki: Boost Attention & Memory with Science-Based Tools"
- The Drive: "#196 - John Ratey, M.D.: ADHD, exercise, nutrition, and the power of movement"
```

### Autism/Neurodivergence (Lines 240-244)
```
- Huberman Lab: "Dr. Sergiu Pașca: Using Stem Cells to Cure Autism, Epilepsy & Schizophrenia" (covers autism genetics, neurodevelopment, spectrum nature)
- Huberman Lab: "ADHD & How Anyone Can Improve Their Focus" (Essentials - relevant for ADHD-autism overlap)
- FoundMyFitness: "Dr. Rhonda Patrick on Omega-3s, Brain Health & Development"
```

### Sensory Processing (Lines 276-279)
```
- Huberman Lab: "Using Sound & Music to Improve Learning, Focus & Mood"
- Huberman Lab: "Control Pain & Heal Faster with Your Brain"
- FoundMyFitness: "Sauna Benefits Deep Dive" (sensory/nervous system regulation)
```

### Anxiety (Lines 303-307)
```
- The Drive: "#362 - Josh Spitalnick, Ph.D.: Understanding anxiety, OCD, and the spectrum of anxiety disorders" (definitive anxiety episode)
- Huberman Lab: "How to Control Your Cortisol & Overcome Burnout"
- Huberman Lab: "Tools for Managing Stress & Anxiety"
```

### Depression (Lines 333-337)
```
- Huberman Lab: "Science of Depression & Tools for Recovery"
- FoundMyFitness: "Dr. Charles Raison on Depression, the Immune-Brain Interface & Whole-Body Hyperthermia"
- The Drive: "#15 - Paul Conti, M.D.: trauma, suicide, community, and self-compassion"
```

### PTSD/Trauma (Lines 360-363)
```
- Huberman Lab: "Erasing Fears & Trauma: Tools from Neuroscience" (covers PTSD treatments including EMDR, ketamine, MDMA)
- Huberman Lab: "DJ Shipley: Mental Health, Trauma Recovery & Tools for Resilience"
- The Drive: "#15 - Paul Conti, M.D.: trauma, suicide, community, and self-compassion"
```

### High ACE/Childhood Adversity (Lines 388-392)
```
- Huberman Lab: "Erasing Fears & Trauma: Tools from Neuroscience"
- Huberman Lab: "Dr. David Spiegel: Using Hypnosis to Enhance Health & Performance"
- The Drive: "#15 - Paul Conti, M.D.: trauma, suicide, community, and self-compassion"
```

### Dark Triad (Lines 415-418)
```
- Huberman Lab: "Dr. Karl Deisseroth: Understanding & Healing the Mind"
- The Drive: "#377 - Arthur Brooks: Understanding true happiness"
```

### High Conflict Personality (Lines 474-478)
```
- Huberman Lab: "Essentials: Science of Building Strong Social Bonds"
- Huberman Lab: "Dr. David Buss: How Humans Select & Keep Romantic Partners"
- The Drive: "#15 - Paul Conti, M.D.: trauma, suicide, community, and self-compassion"
```

### Burnout (Lines 505-508)
```
- Huberman Lab: "How to Control Your Cortisol & Overcome Burnout"
- FoundMyFitness: "Sauna Use for Depression: The Hyperthermia Protocol"
- The Drive: "#377 - Arthur Brooks: Understanding true happiness"
```

### Perfectionism (Lines 532-535)
```
- Huberman Lab: "How to Control Your Cortisol & Overcome Burnout"
- Huberman Lab: "Dr. David Spiegel: Using Hypnosis to Enhance Health & Performance"
- FoundMyFitness: "Dr. Rhonda Patrick on Self-Compassion & Stress Reduction"
```

### Social Anxiety (Lines 561-564)
```
- Huberman Lab: "Essentials: Science of Building Strong Social Bonds"
- Huberman Lab: "How to Speak Clearly & With Confidence | Matt Abrahams"
- The Drive: "#377 - Arthur Brooks: Understanding true happiness"
```

### Codependency (Lines 591-594)
```
- Huberman Lab: "Essentials: Science of Building Strong Social Bonds"
- Huberman Lab: "Dr. David Buss: How Humans Select & Keep Romantic Partners"
- The Drive: "#15 - Paul Conti, M.D.: trauma, suicide, community, and self-compassion"
```

### Substance Risk (Lines 621-624)
```
- Huberman Lab: "Tools for Overcoming Substance & Behavioral Addictions | Ryan Soave"
- Huberman Lab: "Dr. Anna Lembke: Understanding & Treating Addiction"
- FoundMyFitness: "Dr. Rhonda Patrick on Exercise for Depression & Addiction Recovery"
```

### Compulsive Behaviors (Lines 684-688)
```
- Huberman Lab: "Tools for Overcoming Substance & Behavioral Addictions | Ryan Soave"
- Huberman Lab: "Essentials: How Dopamine Regulates Motivation & Drive"
- FoundMyFitness: "Dr. Rhonda Patrick on Brain Health & Dopamine"
```

---

## Implementation Plan

### Step 1: Update ADHD Section (Lines 186-189)
Replace current podcasts with curated Huberman Lab/The Drive episodes

### Step 2: Update Remaining Clinical Sections
Work through each clinical section systematically:
- Autism (240-244)
- Sensory (276-279)
- Anxiety (303-307)
- Depression (333-337)
- PTSD (360-363)
- High ACE (388-392)
- Dark Triad (415-418)
- High Conflict (474-478)
- Burnout (505-508)
- Perfectionism (532-535)
- Social Anxiety (561-564)
- Codependency (591-594)
- Substance Risk (621-624)
- Compulsive Behaviors (684-688)

### Step 3: Update Comparison Report Resources (Lines 828-839)
Update couple-specific podcast recommendations with evidence-based episodes

### Step 4: Test
Verify prompts.ts still loads correctly after changes
