# Conversion Optimization: Assessment Intro Screen

**File:** `~/Deep-Personality/components/Wizard.tsx`
**Component:** `SectionIntro` (lines 79-249)
**Goal:** Increase conversion from intro screen to assessment completion

---

## Final Copy Changes

### Headline (line 82 in SectionIntro call, line 1079 in renderStep)

```
Current:  "Psychological Deep Dive"
New:      "Finally Understand Your Patterns"
```

### Description (line 83 in SectionIntro call, line 1080 in renderStep)

```
Current:  "This assessment is designed to map your personality infrastructure,
          emotional patterns, and core values. The resulting profile can be used
          to dramatically improve your relationships with partners, colleagues, and friends."

New:      "In 35 minutes, you'll understand why you react the way you do,
          why some relationships feel harder than others, and what you actually
          need to feel fulfilled. No vague labels—just clarity."
```

### Time Estimate (line 92)

```
Current:  "35-50 minutes · Save anytime · Pick up where you left off"
New:      "Most finish in ~35 min · Save anytime · Pick up where you left off"
```

### Category Cards (lines 96-132)

| Card | Current Title | Current Description | New Description |
|------|---------------|---------------------|-----------------|
| Personality | Personality | "Your core traits and how they shape your world" | "Why you react the way you do" |
| Attachment | Attachment | "How you connect and what you need from others" | "Why some relationships feel harder" |
| Values | Values | "What drives your decisions and priorities" | "What you need to feel fulfilled" |
| Insights | Insights | "AI-powered analysis that feels surprisingly accurate" | "Patterns you've never articulated" |

### CTA Button (line 226)

```
Current:  "Begin Assessment"
New:      "Start My Profile"
```

### Reassurance Text (lines 136-138)

```
Current:  "No right or wrong answers — just honest reflection.
          Your results are private and never shared."

New:      "No right or wrong answers—just honest reflection.
          Your results are private, and you'll own them forever."
```

---

## Implementation Checklist

- [ ] Update headline in `renderStep()` line 1079
- [ ] Update description in `renderStep()` line 1080
- [ ] Update time estimate text line 92
- [ ] Update Personality card description line 104
- [ ] Update Attachment card description line 113
- [ ] Update Values card description line 122
- [ ] Update Insights card description line 131
- [ ] Update CTA button text line 226
- [ ] Update reassurance text lines 136-138

---

## File to Modify

**`~/Deep-Personality/components/Wizard.tsx`** - Single file, ~10 string changes
