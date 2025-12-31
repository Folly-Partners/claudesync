# Conditional Relationship Assessment Questions for Deep Personality

## Summary
Add conditional relationship questions that trigger when:
1. **User is in any relationship** → 38-item Relationship Deep-Dive
2. **CSI-16 satisfaction < 64** → 18-item Problem Probe expansion

Total additional questions: 38-56 items depending on satisfaction score.

---

## Files to Modify

| File | Purpose |
|------|---------|
| `services/data.ts` | Add RELATIONSHIP_DEEP_DIVE and RELATIONSHIP_PROBLEMS test definitions |
| `components/Wizard.tsx` | Add conditional step logic (follow HCP Extended pattern) |
| `services/scoring.ts` | Add scoring functions for new assessments |
| `types.ts` | Add type definitions for new assessment results |
| `config/wizard-sections.ts` | Add section meta (emoji, colors, time estimates) |
| `services/analyze/prompts.ts` | Add scoring context + relationship dynamics report section |

---

## Implementation Steps

### Step 1: Add Test Definitions (`services/data.ts`)

**RELATIONSHIP_DEEP_DIVE** (38 items) - Shown when relationship status indicates "in a relationship"

```typescript
export const RELATIONSHIP_DEEP_DIVE: TestDefinition = {
  id: 'relationship_deep_dive',
  name: 'Relationship Patterns',
  description: 'These questions help us understand the dynamics of your current relationship.',
  items: [
    // Communication Patterns (CPQ-SF adapted) - 11 items
    { id: 'cpq_1', text: 'When a conflict arises, we discuss the problem together calmly.', subscale: 'constructive' },
    { id: 'cpq_2', text: 'We both try to see the other person\'s point of view during disagreements.', subscale: 'constructive' },
    { id: 'cpq_3', text: 'We work out solutions that satisfy both of us.', subscale: 'constructive' },
    { id: 'cpq_4', text: 'We can express our feelings openly without fear of judgment.', subscale: 'constructive' },
    { id: 'cpq_5', text: 'I try to start a discussion while my partner tries to avoid it.', subscale: 'self_demand' },
    { id: 'cpq_6', text: 'I criticize while my partner becomes defensive.', subscale: 'self_demand' },
    { id: 'cpq_7', text: 'I nag or push for change while my partner withdraws.', subscale: 'self_demand' },
    { id: 'cpq_8', text: 'I bring up issues more often than my partner does.', subscale: 'self_demand' },
    { id: 'cpq_9', text: 'My partner tries to discuss issues while I try to avoid the topic.', subscale: 'partner_demand' },
    { id: 'cpq_10', text: 'My partner criticizes while I become defensive.', subscale: 'partner_demand' },
    { id: 'cpq_11', text: 'My partner nags while I withdraw into silence.', subscale: 'partner_demand' },

    // Intimacy Dimensions (PAIR-inspired) - 12 items
    { id: 'pair_1', text: 'My partner truly understands my feelings and emotions.', subscale: 'emotional' },
    { id: 'pair_2', text: 'I can share my deepest fears and vulnerabilities with my partner.', subscale: 'emotional' },
    { id: 'pair_3', text: 'My partner is my primary source of emotional support.', subscale: 'emotional' },
    { id: 'pair_4', text: 'I feel emotionally connected to my partner most of the time.', subscale: 'emotional' },
    { id: 'pair_5', text: 'My partner and I enjoy discussing ideas and thoughts together.', subscale: 'intellectual' },
    { id: 'pair_6', text: 'We have stimulating conversations that I look forward to.', subscale: 'intellectual' },
    { id: 'pair_7', text: 'We enjoy many of the same leisure activities together.', subscale: 'recreational' },
    { id: 'pair_8', text: 'We make time for fun and play in our relationship.', subscale: 'recreational' },
    { id: 'pair_9', text: 'We have hobbies or interests we share.', subscale: 'recreational' },
    { id: 'pair_10', text: 'I am satisfied with our physical/sexual connection.', subscale: 'sexual' },
    { id: 'pair_11', text: 'We can openly discuss our physical needs and desires.', subscale: 'sexual' },
    { id: 'pair_12', text: 'Physical affection is a regular part of our relationship.', subscale: 'sexual' },

    // Trust & Security - 6 items
    { id: 'trust_1', text: 'I can count on my partner to be there when I need them.', subscale: 'trust' },
    { id: 'trust_2', text: 'I believe my partner is honest with me about important things.', subscale: 'trust' },
    { id: 'trust_3', text: 'I trust my partner\'s commitment to our relationship.', subscale: 'trust' },
    { id: 'trust_4', text: 'I feel secure that our relationship will last.', subscale: 'security' },
    { id: 'trust_5', text: 'My partner respects my boundaries and autonomy.', subscale: 'security' },
    { id: 'trust_6', text: 'We can repair quickly after disagreements.', subscale: 'security' },

    // Shared Values & Goals - 5 items
    { id: 'values_1', text: 'My partner and I share similar life goals.', subscale: 'alignment' },
    { id: 'values_2', text: 'We agree on how to handle money and finances.', subscale: 'alignment' },
    { id: 'values_3', text: 'We are aligned on whether and how to raise children.', subscale: 'alignment' },
    { id: 'values_4', text: 'Our views on work-life balance are compatible.', subscale: 'alignment' },
    { id: 'values_5', text: 'We support each other\'s career and personal goals.', subscale: 'alignment' },

    // Power Dynamics - 4 items
    { id: 'power_1', text: 'Decisions in our relationship are made fairly and jointly.', subscale: 'power' },
    { id: 'power_2', text: 'I feel my voice is equally valued in our relationship.', subscale: 'power' },
    { id: 'power_3', text: 'My partner tries to control my behavior or choices.', subscale: 'power', reverseScored: true },
    { id: 'power_4', text: 'We have balanced responsibilities in the relationship.', subscale: 'power' },
  ]
};
```

**RELATIONSHIP_PROBLEMS** (18 items) - Shown when CSI-16 < 64

```typescript
export const RELATIONSHIP_PROBLEMS: TestDefinition = {
  id: 'relationship_problems',
  name: 'Relationship Challenges',
  description: 'Let\'s explore what might be causing friction in your relationship.',
  items: [
    // Communication Breakdown - 4 items
    { id: 'rp_comm_1', text: 'I often feel unheard or dismissed when expressing my needs.', subscale: 'communication_breakdown' },
    { id: 'rp_comm_2', text: 'Our conversations frequently turn into arguments.', subscale: 'communication_breakdown' },
    { id: 'rp_comm_3', text: 'We avoid talking about important issues to keep the peace.', subscale: 'communication_breakdown' },
    { id: 'rp_comm_4', text: 'There are topics we simply cannot discuss without fighting.', subscale: 'communication_breakdown' },

    // Trust Issues - 4 items
    { id: 'rp_trust_1', text: 'I have concerns about my partner\'s honesty or fidelity.', subscale: 'trust_issues' },
    { id: 'rp_trust_2', text: 'My partner has broken my trust in significant ways.', subscale: 'trust_issues' },
    { id: 'rp_trust_3', text: 'I find myself checking up on my partner\'s activities.', subscale: 'trust_issues' },
    { id: 'rp_trust_4', text: 'Past betrayals still affect how I feel about my partner.', subscale: 'trust_issues' },

    // Intimacy Problems - 3 items
    { id: 'rp_intim_1', text: 'We rarely have physical intimacy anymore.', subscale: 'intimacy_problems' },
    { id: 'rp_intim_2', text: 'I feel emotionally disconnected from my partner.', subscale: 'intimacy_problems' },
    { id: 'rp_intim_3', text: 'One of us wants more intimacy than the other.', subscale: 'intimacy_problems' },

    // External Stressors - 3 items
    { id: 'rp_stress_1', text: 'Financial pressures are straining our relationship.', subscale: 'external_stressors' },
    { id: 'rp_stress_2', text: 'Family obligations (in-laws, children) create conflict between us.', subscale: 'external_stressors' },
    { id: 'rp_stress_3', text: 'Work demands leave little energy for our relationship.', subscale: 'external_stressors' },

    // Compatibility Concerns - 4 items
    { id: 'rp_compat_1', text: 'We have grown apart over time.', subscale: 'compatibility' },
    { id: 'rp_compat_2', text: 'I question whether we are fundamentally compatible.', subscale: 'compatibility' },
    { id: 'rp_compat_3', text: 'We want different things from life.', subscale: 'compatibility' },
    { id: 'rp_compat_4', text: 'I sometimes imagine being happier with someone else.', subscale: 'compatibility' },
  ]
};
```

---

### Step 2: Add Conditional Logic (`components/Wizard.tsx`)

Follow the HCP Extended pattern (lines 942-1019).

```typescript
// Check if user is in any relationship
const isInRelationship = useMemo(() => {
  const status = basicInfo.relationshipStatus?.toLowerCase() || '';
  const relationshipStatuses = ['dating', 'in a relationship', 'in-relationship', 'engaged', 'married', 'partnered', 'domestic partnership'];
  return relationshipStatuses.some(s => status.includes(s));
}, [basicInfo.relationshipStatus]);

// Check if CSI-16 shows below-average satisfaction (< 64)
const hasLowRelationshipSatisfaction = useMemo(() => {
  const csiItems = CSI_16.items.map(i => i.id);
  const csiCompleted = csiItems.every(id => answers[id] !== undefined);
  if (!csiCompleted) return false;

  const csiTotal = csiItems.reduce((sum, id) => sum + ((answers[id] as number) || 0), 0);
  return csiTotal < 64; // Below average threshold
}, [answers]);

// In steps useMemo, after ECR_S and CSI_16:
if (isInRelationship) {
  baseSteps.push({ type: 'test', data: RELATIONSHIP_DEEP_DIVE });
}

if (isInRelationship && hasLowRelationshipSatisfaction) {
  baseSteps.push({ type: 'test', data: RELATIONSHIP_PROBLEMS });
}
```

---

### Step 3: Add Types (`types.ts`)

```typescript
// Add to IndividualProfile.assessments:
relationship_deep_dive?: {
  communication: {
    constructive: number;
    selfDemand: number;
    partnerDemand: number;
    demandWithdrawPattern: 'self_demands' | 'partner_demands' | 'mutual' | 'healthy';
  };
  intimacy: {
    emotional: number;
    intellectual: number;
    recreational: number;
    sexual: number;
    primaryGap: 'emotional' | 'intellectual' | 'recreational' | 'sexual' | null;
  };
  trust: number;
  security: number;
  valuesAlignment: number;
  powerBalance: number;
};

relationship_problems?: {
  communicationBreakdown: { score: number; flagged: boolean };
  trustIssues: { score: number; flagged: boolean };
  intimacyProblems: { score: number; flagged: boolean };
  externalStressors: { score: number; flagged: boolean };
  compatibilityConcerns: { score: number; flagged: boolean };
  primaryIssues: string[];
};
```

---

### Step 4: Add Scoring (`services/scoring.ts`)

Add scoring functions following existing patterns (see CSI-16 scoring around line 473):
- Score each subscale as average of items (1-5 scale)
- Handle reverse-scored items (power_3)
- Identify demand/withdraw pattern based on self_demand vs partner_demand scores
- Identify intimacy gap (lowest scoring dimension)
- Flag problem areas where score > 3.0

---

### Step 5: Add Section Meta (`config/wizard-sections.ts`)

```typescript
relationship_deep_dive: {
  displayName: 'Relationship Dynamics',
  emoji: '💑',
  icon: Heart,
  color: 'pink',
  insight: 'Understanding how you and your partner connect and communicate.',
  timeEstimate: '5-7 min',
  scalePrompt: 'Rate how much each statement applies to your current relationship.'
},

relationship_problems: {
  displayName: 'Relationship Challenges',
  emoji: '🔍',
  icon: AlertTriangle,
  color: 'amber',
  insight: 'Identifying specific areas that could benefit from attention.',
  timeEstimate: '3-4 min',
  scalePrompt: 'Rate how much each statement applies.',
  timeframeHeader: 'Think about the past few months.'
},
```

---

### Step 6: Update AI Prompts (`services/analyze/prompts.ts`)

Add to SCORING_CONTEXT:
```
**Relationship Deep-Dive (Conditional - when in relationship):**
- Communication: constructive (1-5), selfDemand (1-5), partnerDemand (1-5)
  - demandWithdrawPattern: who pursues vs withdraws in conflict
- Intimacy: emotional, intellectual, recreational, sexual (each 1-5)
  - primaryGap: which dimension is most lacking
- Trust & Security: 1-5 scale; < 3.0 = concerning
- Values Alignment: 1-5 scale; < 3.0 = significant misalignment
- Power Balance: 1-5 scale; < 3.0 = imbalanced

**Relationship Problems (Conditional - when CSI-16 < 64):**
- communicationBreakdown, trustIssues, intimacyProblems, externalStressors, compatibilityConcerns
- Each flagged if score > 3.0
- primaryIssues: array of flagged areas sorted by severity
```

Add relationship dynamics section to report generation:
- "Your Relationship Dynamics" section when relationship_deep_dive data present
- "What's Actually Going Wrong" subsection when relationship_problems data present
- Frame constructively: patterns not blame, understanding not judgment
- Connect to attachment style (ECR-S) and rejection sensitivity (RSQ)
- Provide 1-2 concrete interventions for flagged problem areas

---

## Psychological Grounding

| Area | Source |
|------|--------|
| Communication patterns | CPQ-SF (Communication Patterns Questionnaire) - validated demand/withdraw assessment |
| Intimacy dimensions | PAIR Inventory (Schaefer & Olson) - emotional, intellectual, recreational, sexual |
| Trust & Security | Attachment theory research |
| CSI-16 thresholds | Validated: < 51.5 clinical distress, < 64 below average |
| Problem categories | Gottman research, couples therapy literature |

---

## User Experience

- **In relationship + happy (CSI ≥ 64)**: Sees 38 relationship questions (~5-7 min)
- **In relationship + below average (CSI < 64)**: Sees 56 relationship questions (~8-10 min)
- **Not in relationship**: Skips both sections entirely

Report expands dynamically with relationship-specific insights based on data collected.
