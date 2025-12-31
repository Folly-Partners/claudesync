# Plan: Add Legal Hedging and Soften Alarming Clinical Language

## Goal
Keep authoritative tone but add "potential" hedging AND soften the most alarming clinical labels.

## File to Modify
`/Users/andrewwilkinson/Deep-Personality/services/analyze/prompts.ts`

---

## Part 1: System-Level Hedge

### Add to SYSTEM_PROMPT (after line 18)

```
**LEGAL HEDGE FOR CLINICAL SECTIONS:**
When discussing clinical screening results, use "potential" or "likely" as a hedge. Example: "Your potential ADHD" not "Your ADHD." Remain authoritative about what the data shows, but acknowledge these are screening results, not diagnoses. Never say "You have X" or "You are X" - say "You likely have X" or "You appear to have X."
```

---

## Part 2: MOST ALARMING Sections (Special Treatment)

### A. Dark Triad (line 720-743)

**Problem:** Uses "Psychopathy", "Narcissism" directly - terrifying labels

**Changes:**
1. Keep title as `"Your Shadow Side"` (no change)
2. Add framing instruction:
```
**CRITICAL:** Never use the word "psychopathy" directly to describe the person. Instead:
- "Psychopathy" → "Bold/ruthless patterns" or "low-empathy strategic patterns"
- "Narcissism" → "Self-focused patterns" or "confidence-driven patterns"
- "Machiavellianism" → "Strategic/pragmatic patterns"
Frame these as PATTERNS everyone has to some degree, not pathology.
```
3. Update profile table instruction to use softer labels

### B. High Conflict Personality (line 747-799)

**Problem:** Uses "HPD", "BPD" (Borderline Personality Disorder) - heavily stigmatized clinical diagnoses

**Changes:**
1. Update title from `"Your Conflict Patterns"` to `"Understanding Your Conflict Style"`
2. Add framing instruction:
```
**CRITICAL:** Never use clinical abbreviations HPD or BPD. Instead:
- "HPD patterns" → "Attention-seeking patterns" or "expressive emotional style"
- "BPD patterns" → "Emotional intensity patterns" or "abandonment-sensitivity patterns"
These are PATTERNS, not personality disorders. We are not diagnosing.
```
3. Update the HCP Pattern Table (lines 766-771) to remove HPD/BPD labels:
   - `Histrionic (HPD)` → `Expressive Style`
   - `Borderline (BPD)` → `Emotional Intensity`

### C. Cluster Personality Subtypes (lines 1426-1460)

**Problem:** Uses actual personality disorder names: "Paranoid", "Schizoid", "Schizotypal", "Avoidant"

**Changes:**
1. Add framing instruction:
```
**CRITICAL:** Never use clinical personality disorder names. Instead:
- "Paranoid" → "Vigilant/cautious pattern"
- "Schizoid" → "Independent/internal pattern"
- "Schizotypal" → "Unconventional/creative pattern"
- "Avoidant" → "Socially careful pattern"
These are personality STYLES, not disorders.
```
2. Update subtype labels in the tables (lines 1451-1459)

---

## Part 3: Standard Clinical Section Title Updates

| Line | Current Title | New Title |
|------|---------------|-----------|
| 435 | "How Your Mind Works Differently" | "Potential ADHD: How Your Mind Works Differently" |
| 475 | "Your Autistic Neurotype" | "Potential Autism: Exploring Your Autistic Traits" |
| 566 | "Understanding Your Anxiety" | "Potential Anxiety: Understanding Your Patterns" |
| 604 | "When Everything Feels Heavy" | "Potential Depression: When Everything Feels Heavy" |
| 655 | "Why Your Past Still Shows Up" | "Potential PTSD: Why Your Past Still Shows Up" |
| 808 | "Running on Empty" | "Potential Burnout: Running on Empty" |
| 876 | "The Fear of Being Judged" | "Potential Social Anxiety: The Fear of Being Judged" |
| 916 | "When You Lose Yourself in Others" | "Codependency Patterns: When You Lose Yourself in Others" |
| 945 | "Understanding Your Coping Vulnerabilities" | "Potential Substance Use Concerns" |
| 976 | "When Habits Take Control" | "Potential Compulsive Patterns" |

---

## Part 4: SCORING_CONTEXT Updates (lines 24-43)

Update clinical threshold language:
- `Score ≥6 = likely autistic` → `Score ≥6 = screening suggests autistic traits`
- `4+ positives = likely ADHD` → `4+ positives = screening suggests ADHD patterns`
- `Score ≥10 suggests clinical anxiety` → `Score ≥10 suggests potential anxiety disorder`
- `Score ≥10 suggests clinical depression` → `Score ≥10 suggests potential depression`
- `Score ≥31 suggests probable PTSD` → `Score ≥31 suggests potential PTSD`

---

## Summary

| Category | Changes |
|----------|---------|
| System prompt | Add 1 legal hedge paragraph |
| Dark Triad | Keep "Your Shadow Side" title + soften "psychopathy/narcissism" language |
| HCP Section | New title + remove HPD/BPD abbreviations |
| Cluster subtypes | Remove disorder names (Paranoid, Schizoid, etc.) |
| 10 clinical titles | Add "Potential" prefix |
| Scoring context | Soften threshold language |

This keeps the report authoritative and insightful while adding legal protection.
