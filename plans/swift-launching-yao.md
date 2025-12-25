# Plan: Ensure AI Training Prompts Include ALL Test Insights

## Summary

The "Train Your Personal AI" feature in Deep Personality is **missing 4 key assessments** from the generated prompts. The prompts also lack optimal structure for AI comprehension.

---

## Current State Analysis

### Location of Key Code
- **Prompt generation:** `/components/Dashboard.tsx` lines 776-1045
- **Main function:** `generateProfileSummary()` - creates the data summary used by all 3 prompt generators
- **Three prompt types:**
  - `generateChatGPTCustomPrompt()` - Full prompt for Custom GPTs
  - `generateChatGPTProjectPrompt()` - Condensed version (manually constructed, different format)
  - `generateClaudeProjectPrompt()` - XML-structured prompt

### Assessments Currently INCLUDED (15 of 19):
1. IPIP-50 (Big Five)
2. ECR-S (Attachment Style)
3. PVQ-21 (Values)
4. O*NET Mini-IP (RIASEC Career Interests)
5. WEIMS (Work Motivation)
6. GAD-7 (Anxiety)
7. PHQ-9 (Depression)
8. PCL-5 (PTSD)
9. ACE (Adverse Childhood Experiences)
10. DTS (Distress Tolerance)
11. RSQ (Rejection Sensitivity)
12. SCS-SF (Self-Compassion)
13. DERS-16 (Emotional Dysregulation)
14. SWLS (Life Satisfaction)
15. UCLA-3 (Loneliness)
16. PERMA (Wellbeing)
17. ASRS-18 (ADHD)
18. CSI-16 (Relationship Satisfaction)

### Assessments MISSING from generateProfileSummary():
1. **AQ-10** (Autism Screening) - likelyAutistic flag, subscales
2. **CAT-Q** (Camouflaging/Masking) - significantMasking, exhaustionIndicator
3. **Sensory Processing** - sensitivityLevel, primarySensitivities
4. **Personality Styles** - Cluster A/B/C scores

### Additional Missing Data:
5. **Dark Triad** - Intentionally stripped from AI analysis, but could be included for personal AI training with appropriate framing
6. **Demographics** (age, gender) - Not currently included in profile summary

---

## Issues Identified

### Issue 1: Missing 4 Neurodivergence/Clinical Assessments
The autism screening (AQ-10), masking assessment (CAT-Q), sensory processing, and personality cluster data are all collected but NOT included in the AI training prompts.

### Issue 2: Inconsistent Prompt Formats
- `generateChatGPTCustomPrompt()` uses `generateProfileSummary()`
- `generateChatGPTProjectPrompt()` manually builds a condensed format with different property names
- This means bugs/additions need to be made in 2 places

### Issue 3: No Cross-Measure Insights
The main analysis (prompts.ts) includes sophisticated cross-measure patterns like:
- RSQ + Attachment interaction
- DERS subscale predictions
- ACE + Attachment origin
- Values-based conflicts

These powerful insights are NOT included in the AI training prompts.

### Issue 4: No Clinical Condition Context
The `detectTriggeredClinicalConditions()` function identifies patterns like:
- ADHD + Autism overlap
- Burnout indicators
- Perfectionism patterns
- Social anxiety patterns

This rich context isn't provided to the trained AI.

---

## User Decisions
- **Dark Triad:** Include with shadow-work framing
- **Comprehensiveness:** Maximum (all assessments + clinical patterns + cross-measure insights)
- **ChatGPT Project:** Match full format (not condensed)

---

## Implementation Plan

### Step 1: Add Missing Assessments to generateProfileSummary()

Add to `/components/Dashboard.tsx` at line ~875 (before custom responses section):

```typescript
// Autism Screening
if (a.aq_10) {
  summary += `AUTISM SCREENING (AQ-10): ${a.aq_10.totalScore}/10 - ${a.aq_10.label}\n`;
  if (a.aq_10.likelyAutistic) summary += `  Likely autistic neurotype\n`;
  summary += `  Subscales: Attention to detail (${a.aq_10.subscales.attention_to_detail}), Switching (${a.aq_10.subscales.attention_switching}), Communication (${a.aq_10.subscales.communication}), Imagination (${a.aq_10.subscales.imagination})\n\n`;
}

// Camouflaging/Masking
if (a.cat_q) {
  summary += `SOCIAL CAMOUFLAGING (CAT-Q): ${a.cat_q.totalScore}/125 - ${a.cat_q.label}\n`;
  if (a.cat_q.significantMasking) summary += `  Significant social masking detected\n`;
  if (a.cat_q.exhaustionIndicator) summary += `  Warning: Masking exhaustion risk\n`;
  summary += `  Compensation: ${a.cat_q.subscales.compensation} (${a.cat_q.subscaleLabels.compensation})\n`;
  summary += `  Masking: ${a.cat_q.subscales.masking} (${a.cat_q.subscaleLabels.masking})\n`;
  summary += `  Assimilation: ${a.cat_q.subscales.assimilation} (${a.cat_q.subscaleLabels.assimilation})\n\n`;
}

// Sensory Processing
if (a.sensory_processing) {
  summary += `SENSORY PROCESSING: ${a.sensory_processing.totalScore}/50 - ${a.sensory_processing.label}\n`;
  summary += `  Sensitivity Level: ${a.sensory_processing.sensitivityLevel}\n`;
  if (a.sensory_processing.primarySensitivities?.length > 0) {
    summary += `  Primary Sensitivities: ${a.sensory_processing.primarySensitivities.join(', ')}\n`;
  }
  const s = a.sensory_processing.subscales;
  summary += `  Visual: ${s.visual}, Auditory: ${s.auditory}, Tactile: ${s.tactile}\n`;
  summary += `  Olfactory: ${s.olfactory}, Gustatory: ${s.gustatory}\n`;
  summary += `  Proprioceptive: ${s.proprioceptive}, Vestibular: ${s.vestibular}\n\n`;
}

// Personality Styles (Cluster A/B/C)
if (a.personality_styles) {
  summary += `PERSONALITY STYLE PATTERNS:\n`;
  summary += `- Cluster A (Eccentric): ${a.personality_styles.clusterA.raw.toFixed(1)} - ${a.personality_styles.clusterA.label}\n`;
  summary += `- Cluster B (Dramatic): ${a.personality_styles.clusterB.raw.toFixed(1)} - ${a.personality_styles.clusterB.label}\n`;
  summary += `- Cluster C (Anxious): ${a.personality_styles.clusterC.raw.toFixed(1)} - ${a.personality_styles.clusterC.label}\n\n`;
}
```

### Step 2: Add Dark Triad Section

Add after Personality Styles in generateProfileSummary():

```typescript
// Dark Triad (Shadow Side)
const dt = profile.darkTriad || profile._internal?.darkTriad;
if (dt) {
  summary += `SHADOW TRAITS (Dark Triad):\n`;
  summary += `Understanding your shadow side gives you power over it.\n`;
  if ('machiavellianism' in dt && typeof dt.machiavellianism === 'object') {
    summary += `- Machiavellianism: ${dt.machiavellianism.percentile}th percentile${dt.machiavellianism.flagged ? ' (elevated)' : ''}\n`;
    summary += `- Narcissism: ${dt.narcissism.percentile}th percentile${dt.narcissism.flagged ? ' (elevated)' : ''}\n`;
    summary += `- Psychopathy: ${dt.psychopathy.percentile}th percentile${dt.psychopathy.flagged ? ' (elevated)' : ''}\n`;
  }
  summary += '\n';
}
```

### Step 3: Add Clinical Pattern Detection Section

Add new helper function and call it in generateProfileSummary():

```typescript
// Add after Dark Triad section
summary += generateClinicalPatternsSummary(profile);
```

Create new function (can be added near generateProfileSummary):

```typescript
const generateClinicalPatternsSummary = (profile: IndividualProfile): string => {
  let summary = '';
  const a = profile.assessments;
  const patterns: string[] = [];

  // Detect key patterns (simplified version of detectTriggeredClinicalConditions)

  // ADHD + Autism overlap
  if (a.asrs_18?.likelyADHD && (a.aq_10?.likelyAutistic || a.cat_q?.significantMasking)) {
    patterns.push('ADHD-Autism overlap (30-80% comorbidity) - both conditions interact');
  }

  // Burnout indicators
  let burnoutCount = 0;
  if (a.weims?.amotivationFlag) burnoutCount++;
  if (a.perma && a.perma.pillars.engagement < 5) burnoutCount++;
  if (a.phq_9 && a.phq_9.score >= 10) burnoutCount++;
  if (a.swls && a.swls.score < 15) burnoutCount++;
  if (burnoutCount >= 3) {
    patterns.push('Burnout pattern detected (low motivation + low engagement + mood impact)');
  }

  // Perfectionism
  const ipip = a.ipip_50?.domainScores;
  if (ipip && ipip.conscientiousness.percentileEstimate >= 85 &&
      ipip.neuroticism.percentileEstimate >= 70 &&
      a.scs_sf && a.scs_sf.subscales.self_judgment >= 3) {
    patterns.push('Perfectionism pattern (high standards + self-criticism + anxiety)');
  }

  // Social anxiety pattern
  if (a.rsq && a.rsq.score >= 12 &&
      ipip && ipip.extraversion.percentileEstimate <= 25 &&
      ipip.neuroticism.percentileEstimate >= 60 &&
      a.gad_7 && a.gad_7.score >= 8) {
    patterns.push('Social anxiety pattern (rejection sensitivity + avoidance + worry)');
  }

  if (patterns.length > 0) {
    summary += `DETECTED PATTERNS:\n`;
    patterns.forEach(p => summary += `- ${p}\n`);
    summary += '\n';
  }

  return summary;
};
```

### Step 4: Add Cross-Measure Insights Section

Add to generateProfileSummary() after clinical patterns:

```typescript
summary += generateCrossMeasureInsights(profile);
```

Create function:

```typescript
const generateCrossMeasureInsights = (profile: IndividualProfile): string => {
  let summary = '';
  const a = profile.assessments;
  const insights: string[] = [];

  // RSQ + Attachment interaction
  if (a.rsq && a.ecr_s) {
    const highRSQ = a.rsq.score >= 12;
    const anxious = a.ecr_s.anxiety.raw >= 3.5;
    const avoidant = a.ecr_s.avoidance.raw >= 3.5;

    if (highRSQ && anxious && !avoidant) {
      insights.push(`Rejection sensitivity + Anxious attachment: May seek excessive reassurance when feeling rejected`);
    } else if (highRSQ && avoidant) {
      insights.push(`Rejection sensitivity + Avoidant attachment: May withdraw preemptively ("reject before being rejected")`);
    }
  }

  // ACE + Attachment origin
  if (a.ace && a.ace.score >= 4 && a.ecr_s) {
    insights.push(`High ACE + ${a.ecr_s.attachmentStyleLabel} attachment: Early experiences likely shaped relational patterns`);
  }

  // Values conflicts
  if (a.pvq_21) {
    const vals = a.pvq_21.topValues;
    if (vals.includes('Security') && vals.includes('Stimulation')) {
      insights.push(`Values tension: Security vs Stimulation creates internal conflict`);
    }
    if (vals.includes('Tradition') && vals.includes('Self-direction')) {
      insights.push(`Values tension: Tradition vs Self-direction creates internal conflict`);
    }
  }

  // DERS-specific predictions
  if (a.ders_16?.subscalesHigh?.includes('impulse')) {
    insights.push(`Low impulse control under stress: May say things regretted later during conflict`);
  }

  if (insights.length > 0) {
    summary += `CROSS-MEASURE INSIGHTS:\n`;
    insights.forEach(i => summary += `- ${i}\n`);
    summary += '\n';
  }

  return summary;
};
```

### Step 5: Refactor generateChatGPTProjectPrompt()

Replace the manual construction with `generateProfileSummary()`:

```typescript
const generateChatGPTProjectPrompt = (profile: IndividualProfile): string => {
  const name = profile.name || 'the user';
  const profileSummary = generateProfileSummary(profile);

  return `You are ${name}'s personalized AI coach with comprehensive knowledge of their psychology based on 19 validated assessments.

PSYCHOLOGICAL PROFILE FOR ${name.toUpperCase()}:
${profileSummary}

YOUR ROLE AND APPROACH:
1. **Therapeutic Guidance**: Draw on CBT, DBT, ACT, and attachment-based approaches. Match interventions to their profile.
2. **Relationship Coaching**: Understand their attachment style and help them navigate relationships.
3. **Career Advice**: Align suggestions with their RIASEC interests and work motivation.
4. **Self-Improvement**: Address specific growth areas based on their scores.

COMMUNICATION STYLE:
- Be warm, direct, and insight-driven
- Reference their specific scores when relevant
- Validate experiences while gently challenging unhelpful patterns
- Provide concrete, actionable suggestions tailored to their personality

Remember: You know ${name} deeply through their assessment data. Use this knowledge to provide personalized, meaningful support.`;
};
```

### Step 6: Add Demographics (age, gender) to Summary

Add at the start of generateProfileSummary():

```typescript
// Demographics
if (profile.demographics?.age) {
  summary += `AGE: ${profile.demographics.age}\n`;
}
// Note: gender may be in demographics or at profile level
summary += '\n';
```

---

## Files to Modify

| File | Location | Changes |
|------|----------|---------|
| `/components/Dashboard.tsx` | lines 776-903 | Add AQ-10, CAT-Q, Sensory, Personality Styles, Dark Triad to `generateProfileSummary()` |
| `/components/Dashboard.tsx` | lines 776-903 | Add `generateClinicalPatternsSummary()` helper function |
| `/components/Dashboard.tsx` | lines 776-903 | Add `generateCrossMeasureInsights()` helper function |
| `/components/Dashboard.tsx` | lines 936-999 | Refactor `generateChatGPTProjectPrompt()` to use full summary |

---

## Expected Outcome

After implementation, the AI training prompts will include:
- All 19 assessments (adding AQ-10, CAT-Q, Sensory, Personality Styles)
- Dark Triad with shadow-work framing
- Clinical pattern detection (ADHD+Autism overlap, burnout, perfectionism, social anxiety)
- Cross-measure insights (RSQ+Attachment, ACE+Attachment, Values conflicts, DERS predictions)
- Consistent format across all 3 prompt types
