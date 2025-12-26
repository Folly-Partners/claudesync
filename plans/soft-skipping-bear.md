# Evidence-Based Treatment Recommendations

## Problem
The "Your Next Steps" section has a fixed structure: therapy first, medication as "complement". This is incorrect for conditions like ADHD where medication is significantly more effective than therapy alone.

**Current structure (lines 795-809):**
1. "Start here" - self-help practice
2. "Therapy to explore" - always positions therapy as primary
3. "Medication consideration" - framed as secondary, "complement to therapy"

**Should be:** Present the **top 2 most effective treatments** for each condition, based on evidence - whether that's medication, therapy, or something else.

## Evidence by Condition

| Condition | Most Effective | Efficacy | Second Most Effective | Efficacy |
|-----------|----------------|----------|----------------------|----------|
| **ADHD** | Stimulant medication | 70-80% | CBT + medication | +30-50% additional |
| **Depression** | Therapy + medication combined | 85% | CBT alone | 50-75% |
| **Anxiety** | CBT | 60-80% | SSRIs | 40-60% |
| **PTSD** | EMDR | 77-90% | Trauma-focused CBT | 70-80% |
| **Emotional dysregulation** | DBT | 70-80% | Medication | varies |

## File to Modify
`/Users/andrewwilkinson/Deep-Personality/app/api/analyze-parallel/route.ts` (lines 795-809)

## Changes

### Replace the fixed therapy-first structure with evidence-based guidance

**Before (current):**
```markdown
• **Therapy to explore:** [Name the SPECIFIC modality...]
• **Medication consideration:** [If depression/anxiety is moderate-severe...]
```

**After (new):**
```markdown
• **Most effective treatment for your patterns:** [Based on their PRIMARY clinical flag, recommend the #1 evidence-based treatment]:
  - For ADHD: "Medication evaluation with a psychiatrist - stimulants (Adderall, Vyvanse, Ritalin) help 70-80% of people, often from the first dose. This is first-line treatment for ADHD."
  - For depression (moderate-severe): "Combined therapy + medication shows the best outcomes (up to 85% improvement). SSRIs help 40-60% of people; CBT helps 50-75%."
  - For anxiety: "Cognitive Behavioral Therapy (CBT) - research shows 60-80% see significant improvement. SSRIs can help if anxiety is severe."
  - For PTSD: "EMDR (Eye Movement Desensitization and Reprocessing) - 77-90% no longer meet PTSD criteria after 3-12 sessions"
  - For emotional dysregulation: "Dialectical Behavior Therapy (DBT) - 70-80% see significant improvement in emotion regulation"

• **Complementary approach:** [Add the #2 most effective treatment to enhance outcomes]:
  - For ADHD: "Once medication stabilizes attention, ADHD-focused CBT or coaching builds organization and time management skills (+30-50% additional improvement)"
  - For depression: "If starting with therapy, medication can accelerate progress. If starting with medication, therapy builds lasting coping skills."
  - For anxiety: "Medication (SSRIs) can reduce baseline anxiety enough to engage more fully with CBT techniques"
  - For PTSD: "Trauma-focused CBT or somatic therapies complement EMDR for complex trauma"
  - For emotional dysregulation: "Individual therapy alongside DBT skills group deepens the work"
```

## Summary
- Remove the bias toward therapy-first for all conditions
- Present treatments in order of effectiveness for each specific condition
- ADHD leads with medication; anxiety leads with CBT; depression leads with combined approach
- Each condition gets evidence-based, condition-specific guidance
