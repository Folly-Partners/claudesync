# Plan: Add Treatment Recommendations with Efficacy Levels to AI Analysis

## Goal
Add scientifically validated treatment recommendations (therapy, medication, lifestyle, emerging treatments) for flagged mental health issues (ADHD, depression, anxiety, PTSD, etc.) with plain-language efficacy levels that laymen can understand.

## Files to Modify
1. `/app/api/analyze/route.ts` - Main streaming analysis (individual + comparison modes)
2. `/app/api/analyze-parallel/route.ts` - Parallel chunk analysis (individual + comparison modes)

## Changes

### 1. Enhance Individual Mode Treatment Section (~line 979-1040)

Update the existing "Mental Health Support & Recommendations" section with:

**For each condition (Depression, Anxiety, ADHD, PTSD, Trauma):**

| Treatment | How It Works | How Well It Works | Best For |
|-----------|--------------|-------------------|----------|
| **Therapy Options** |
| CBT | Changes negative thought patterns | ~6 in 10 feel significantly better | Depression, Anxiety |
| EMDR | Reprocesses traumatic memories | ~7 in 10 no longer meet PTSD criteria | Trauma, PTSD |
| DBT | Builds emotional coping skills | ~7 in 10 see major improvement | Emotion regulation |
| **Medication** |
| SSRIs (Prozac, Zoloft, etc.) | Increases serotonin in brain | ~5 in 10 see 50%+ symptom reduction | Depression, Anxiety |
| Stimulants (Adderall, Ritalin) | Increases dopamine/norepinephrine | ~7-8 in 10 see significant improvement | ADHD |
| **Lifestyle** |
| Exercise (30min 3x/week) | Releases endorphins, reduces cortisol | As effective as antidepressants for mild-moderate depression | All conditions |
| Sleep optimization | Restores brain function | Poor sleep worsens ALL mental health conditions | All conditions |
| **Emerging Options** *(when traditional treatments haven't worked)* |
| TMS | Magnetic stimulation of brain | ~5 in 10 respond when meds haven't worked | Worth exploring if antidepressants failed |
| Ketamine/Spravato | Rapid-acting, different mechanism | Works faster than traditional meds | For severe cases under medical supervision |
| Psilocybin therapy | Being studied for depression | Promising early research | Legal only in OR, CO; clinical trials elsewhere |
| Neurofeedback | Trains brain wave patterns | Growing evidence | May help ADHD, anxiety |

### 2. Add Mental Health Section to Comparison/Couple Mode (~line 1480)

Add new section before "Your Relationship at a Glance":

```
## 🧠 Mental Health & Your Relationship

*How individual mental health affects your dynamic, and evidence-based options for support*

### Individual Considerations

**For [Name A]:** (Only if flags present)
Based on their screening results, [specific recommendations with efficacy]

**For [Name B]:** (Only if flags present)
Based on their screening results, [specific recommendations with efficacy]

### Couple-Specific Support

If mental health challenges are affecting the relationship:

| Approach | How It Works | How Well It Works |
|----------|--------------|-------------------|
| Couples Therapy (EFT) | Rebuilds emotional connection | ~7 in 10 couples improve significantly |
| Couples Therapy (Gottman) | Teaches communication skills | ~6 in 10 maintain gains at 5 years |
| ADHD-Neurotypical Coaching | Helps partners understand different brains | Reduces conflict by helping both adapt |

### Supporting Each Other

Specific guidance on:
- How [Name A] can support [Name B] with their challenges
- How [Name B] can support [Name A] with their challenges
- Warning signs that professional help is needed
```

### 3. Update Parallel Route (`analyze-parallel/route.ts`)

Update the `wellbeing-inversions` chunk prompt (~line 831) with the same enhanced treatment section.

## Plain-Language Efficacy Format

Always use formats like:
- "~7 in 10 people see significant improvement"
- "Works for about half of people who try it"
- "As effective as medication for mild cases"
- "Most people notice changes within 2-4 weeks"

Avoid:
- NNT numbers (confusing)
- Effect sizes (d=0.8)
- P-values
- Technical statistical terms

## Treatment Hierarchy (Important)

Present treatments in this order of priority:
1. **First-line:** Therapy (CBT, DBT, EMDR) + Lifestyle (exercise, sleep, diet)
2. **When needed:** Medication (SSRIs, stimulants) - often works best WITH therapy
3. **Emerging options:** Only mention when traditional approaches haven't worked
   - Use softer language: "worth exploring", "promising research", "may help"
   - Include appropriate caveats about legality, medical supervision, availability
   - Don't oversell - these are options, not recommendations

## Conditions to Cover

| Condition | Triggered When | Key Treatments |
|-----------|----------------|----------------|
| Depression | PHQ-9 ≥ 10 | CBT, SSRIs, Exercise, Light therapy, Ketamine |
| Anxiety | GAD-7 ≥ 10 | CBT, SSRIs, Exposure therapy, Breathing exercises |
| ADHD | likelyADHD = true | Stimulants, CBT for ADHD, Coaching, Structure tools |
| PTSD | PCL-5 ≥ 31 | EMDR, CPT, Prolonged Exposure, Prazosin (nightmares) |
| Trauma history | ACE ≥ 4 | Trauma-focused therapy, Somatic work, IFS |

## Implementation Order

1. Update individual mode in `analyze/route.ts` with comprehensive treatment table
2. Add couple mental health section to comparison mode in `analyze/route.ts`
3. Mirror changes in `analyze-parallel/route.ts`
4. Test with sample profiles that have flags (Sam has mild symptoms, Alex has some flags)
