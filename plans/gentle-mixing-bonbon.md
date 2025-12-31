# Plan: Enhance Relationship Sections with Complete Assessment Data

## Problem Summary

The relationship-focused chunks in both individual and comparison reports have access to rich relationship assessment data but don't explicitly guide the AI to USE it. The conditional assessments (`relationship_deep_dive` and `relationship_problems`) provide detailed data that isn't being leveraged.

### Data Available (not currently used in prompts)

**`relationship_deep_dive`** (conditional - if user is in a relationship):
| Category | Subscales | What It Reveals |
|----------|-----------|-----------------|
| Communication | constructive, selfDemand, partnerDemand, demandWithdrawPattern | How they handle conflict, who pursues/withdraws |
| Intimacy | emotional, intellectual, recreational, sexual, primaryGap | Which connection dimensions are strong/weak |
| Foundation | trust, security, valuesAlignment, powerBalance | Core relationship health indicators |

**`relationship_problems`** (conditional - if CSI-16 < 64):
| Subscale | What It Detects |
|----------|-----------------|
| communicationBreakdown | Feeling unheard, arguments, avoidance |
| trustIssues | Honesty concerns, broken trust, past betrayals |
| intimacyProblems | Physical/emotional distance, desire mismatch |
| externalStressors | Financial pressure, family, work demands |
| compatibilityConcerns | Growing apart, questioning compatibility |
| primaryIssues[] | Sorted array of flagged areas |

### Current State
- **Individual report**: `current-relationship` chunk only mentions CSI-16 score and attachment label
- **Comparison report**: `romantic`, `conflict`, `toolkit` chunks use Big Five/attachment/values but ignore relationship_deep_dive data

## Files to Modify

**`/Users/andrewwilkinson/Deep-Personality/app/api/analyze-parallel/route.ts`**

| Lines | Chunk | What to Add |
|-------|-------|-------------|
| 634-742 | `current-relationship` | Use relationship_deep_dive + relationship_problems |
| 1433-1522 | `romantic` (comparison) | Use both partners' relationship data if available |
| 1525-1554 | `conflict` (comparison) | Use demand-withdraw patterns from both partners |
| 1556-1582 | `toolkit` (comparison) | Tailor advice based on specific relationship issues |

## Implementation Plan

### Part 1: Individual Report - `current-relationship` chunk (lines 634-742)

#### 1A. Add data extraction at start of buildPrompt
```typescript
const hasDeepDive = !!profile.relationship_deep_dive;
const hasProblems = !!profile.relationship_problems;
const deepDive = profile.relationship_deep_dive;
const problems = profile.relationship_problems;
```

#### 1B. Inject relationship data into prompt context
```typescript
${hasDeepDive ? `
RELATIONSHIP DEEP-DIVE DATA:
Communication Pattern: ${deepDive.communication.demandWithdrawPattern}
- Constructive communication: ${deepDive.communication.constructive}/5
- Self demands (you pursue): ${deepDive.communication.selfDemand}/5
- Partner demands: ${deepDive.communication.partnerDemand}/5

Intimacy Scores:
- Emotional: ${deepDive.intimacy.emotional}/5
- Intellectual: ${deepDive.intimacy.intellectual}/5
- Recreational: ${deepDive.intimacy.recreational}/5
- Sexual: ${deepDive.intimacy.sexual}/5
- Primary Gap: ${deepDive.intimacy.primaryGap || 'None identified'}

Foundation Scores:
- Trust: ${deepDive.trust}/5 ${deepDive.trust < 3 ? '⚠️ CONCERNING' : ''}
- Security: ${deepDive.security}/5 ${deepDive.security < 3 ? '⚠️ CONCERNING' : ''}
- Values Alignment: ${deepDive.valuesAlignment}/5 ${deepDive.valuesAlignment < 3 ? '⚠️ CONCERNING' : ''}
- Power Balance: ${deepDive.powerBalance}/5 ${deepDive.powerBalance < 3 ? '⚠️ CONCERNING' : ''}
` : ''}

${hasProblems ? `
FLAGGED RELATIONSHIP PROBLEMS (from low-satisfaction screening):
Primary Issues: ${problems.primaryIssues.join(', ')}

Problem Area Details:
- Communication Breakdown: ${problems.communicationBreakdown.score}/5 ${problems.communicationBreakdown.flagged ? '🚨 FLAGGED' : ''}
- Trust Issues: ${problems.trustIssues.score}/5 ${problems.trustIssues.flagged ? '🚨 FLAGGED' : ''}
- Intimacy Problems: ${problems.intimacyProblems.score}/5 ${problems.intimacyProblems.flagged ? '🚨 FLAGGED' : ''}
- External Stressors: ${problems.externalStressors.score}/5 ${problems.externalStressors.flagged ? '🚨 FLAGGED' : ''}
- Compatibility Concerns: ${problems.compatibilityConcerns.score}/5 ${problems.compatibilityConcerns.flagged ? '🚨 FLAGGED' : ''}

YOU MUST address the flagged issues specifically in your analysis.
` : ''}
```

#### 1C. Update each satisfaction scenario with specific guidance

**HIGH SATISFACTION (CSI >= 68) with deep-dive data:**
```
### What's Working

Use the relationship data to explain WHY this relationship succeeds:

1. **Communication Analysis**: Reference their demandWithdrawPattern ('${deepDive?.communication.demandWithdrawPattern}').
   - If 'healthy': "Your conflict style is genuinely healthy - neither of you pursues aggressively or shuts down defensively."
   - Reference their constructive score (${deepDive?.communication.constructive}/5)

2. **Intimacy Profile**: Identify their strongest connection dimensions from the intimacy scores.
   - Highlight their top 2 intimacy areas
   - Note if all areas are balanced (all 4+) vs one standout

3. **Foundation Strengths**:
   - If trust/security/values/power are all 4+: "You've built a secure foundation"
   - Identify which foundation element is their superpower

### Example output:
"Your relationship satisfaction score of 73/81 isn't luck - the data shows exactly why this works. Your communication pattern is 'healthy' - rare and valuable. When conflict arises, you scored 4.3/5 on constructive resolution, meaning you engage without attacking or withdrawing.

Your intimacy profile shows particular strength in emotional (4.6/5) and intellectual (4.4/5) connection - you feel deeply understood and mentally stimulated. With trust at 4.7/5, you've created a rare sense of safety."
```

**MODERATE SATISFACTION (CSI 57-67) with deep-dive data:**
```
### Where You Stand

Use the data to identify SPECIFIC growth areas:

1. **Intimacy Gap Analysis**: Check primaryGap field and corresponding score
   - If primaryGap = 'recreational': "Your primary gap is recreational intimacy (${deepDive?.intimacy.recreational}/5) - you've built routine but lost play"
   - If primaryGap = 'sexual': "Physical intimacy (${deepDive?.intimacy.sexual}/5) has become disconnected - often a symptom of emotional distance"

2. **Demand-Withdraw Detection**: If pattern isn't 'healthy'
   - 'self_demands': "You're the pursuer in conflicts - you bring up issues, they shut down. This exhausting cycle is the #1 predictor of relationship deterioration."
   - 'partner_demands': "Your partner pursues while you withdraw. Combined with your ${profile.ecr_s?.attachmentStyleLabel} attachment, you may feel overwhelmed by their need for resolution."
   - 'mutual': "Both of you alternate between demanding and withdrawing - a chaotic pattern that prevents resolution"

3. **Foundation Concerns**: Any score below 3.0 should be highlighted
   - powerBalance < 3: "Power balance (${deepDive?.powerBalance}/5) suggests unequal voice in decisions"
   - valuesAlignment < 3: "Values alignment (${deepDive?.valuesAlignment}/5) indicates fundamental differences in life direction"

### Example output:
"Your score of 61/81 suggests a 'fine' relationship masking specific friction points. The data reveals:

Your primary intimacy gap is **recreational** - you scored just 2.6/5 on shared activities and fun. This often creeps up slowly: dates become logistics, spontaneity becomes scheduling. You've built a functional partnership but may be losing the friendship underneath it.

The demand-withdraw pattern shows 'partner_demands' - your partner brings up issues while you tend to shut down. Your dismissive-avoidant attachment makes this particularly painful for both: their pursuit feels overwhelming, your withdrawal feels rejecting. Neither of you is wrong, but the pattern is destructive.

Power balance sits at 2.8/5 - just below healthy threshold. Worth examining: whose voice dominates decisions about time, money, and lifestyle?"
```

**DISTRESSED (CSI < 57) with deep-dive AND problems data:**
```
### What Your Profile Reveals

MANDATORY: Address each flagged item from primaryIssues array specifically.

1. **Lead with Primary Issues**: Start with the most severely flagged problems
   - "Your data flagged [primaryIssues[0]] and [primaryIssues[1]] as core wounds in this relationship."

2. **Map Problems to Patterns**: Connect flagged issues to deep-dive data
   - If trustIssues flagged + trust < 3: "Trust scored ${deepDive?.trust}/5 - your responses indicate active distrust, not just unease"
   - If communicationBreakdown flagged + demandWithdrawPattern != 'healthy': "Communication breakdown (flagged) + your '${deepDive?.communication.demandWithdrawPattern}' conflict pattern = a relationship where issues can't get resolved"

3. **Intimacy Collapse**: Show which dimensions are suffering
   - Identify scores below 2.5 - these represent active distress, not just absence

4. **Attachment Integration**: Connect to their attachment style
   - Anxious + trustIssues: "For someone with anxious attachment, trust wounds are devastating - they confirm your deepest fear"
   - Avoidant + intimacyProblems: "Your avoidant attachment may be both cause and effect here"

### Example output:
"Your satisfaction score of 42/81 places you in clear distress. The data shows why - this isn't vague unhappiness, it's specific dysfunction.

**Your flagged problems: trustIssues, communicationBreakdown, intimacyProblems**

**Trust Issues (flagged, 4.1/5 severity)**: Your responses indicated concerns about honesty, reliability, or past betrayals. Trust scored just 2.1/5 in your deep-dive - meaning this isn't paranoia, it's pattern recognition. For someone with your anxious attachment, trust wounds are uniquely devastating. They confirm the fear you carry: that others can't be counted on.

**Communication Breakdown (flagged, 3.7/5 severity)**: You're not being heard. The data shows a 'self_demands' pattern - you're the pursuer, bringing up issues repeatedly while your partner shuts down. You scored just 2.4/5 on constructive communication. This combination - unresolved issues + your NEED to resolve them + their refusal to engage - creates the most painful dynamic in relationships.

**The Intimacy Picture**:
- Emotional intimacy: 2.2/5 (you don't feel understood)
- Sexual intimacy: 1.9/5 (physical connection has collapsed)
This isn't about libido - physical disconnection almost always signals emotional disconnection. The bedroom has become a symptom.

**The Pattern**: Your data shows a relationship where safety has eroded. You can't trust, so you pursue reassurance. They can't handle the intensity, so they withdraw. Their withdrawal confirms your fear, so you pursue harder. This cycle can't be broken without professional help or fundamental change."
```

### Part 2: Comparison Report - `romantic`, `conflict`, `toolkit` chunks

#### 2A. Update `romantic` chunk (lines 1433-1522)

Add data extraction for BOTH profiles:
```typescript
const deepDiveA = profileA.assessments?.relationship_deep_dive;
const deepDiveB = profileB.assessments?.relationship_deep_dive;
const hasDeepDiveA = !!deepDiveA;
const hasDeepDiveB = !!deepDiveB;
```

Add to prompt context:
```typescript
${hasDeepDiveA ? `
${nameA}'s RELATIONSHIP PATTERNS:
- Demand-Withdraw: ${deepDiveA.communication.demandWithdrawPattern}
- Constructive communication: ${deepDiveA.communication.constructive}/5
- Intimacy gaps: ${deepDiveA.intimacy.primaryGap || 'None'}
- Trust: ${deepDiveA.trust}/5, Power: ${deepDiveA.powerBalance}/5
` : ''}

${hasDeepDiveB ? `
${nameB}'s RELATIONSHIP PATTERNS:
- Demand-Withdraw: ${deepDiveB.communication.demandWithdrawPattern}
- Constructive communication: ${deepDiveB.communication.constructive}/5
- Intimacy gaps: ${deepDiveB.intimacy.primaryGap || 'None'}
- Trust: ${deepDiveB.trust}/5, Power: ${deepDiveB.powerBalance}/5
` : ''}

${hasDeepDiveA && hasDeepDiveB ? `
PATTERN INTERACTION ANALYSIS:
Use the demand-withdraw patterns from BOTH partners to predict conflict dynamics:
- If ${nameA} is 'self_demands' and ${nameB} is avoidant attachment → predict pursue-withdraw cycle
- If both have 'self_demands' → predict explosive conflicts
- If both have low constructive scores → predict unresolved issues accumulating
- If one has trust < 3 and other has avoidant attachment → predict spiral of suspicion and withdrawal

Cross-reference their intimacy gaps - do they align or conflict?
` : ''}
```

#### 2B. Update `conflict` chunk (lines 1525-1554)

Add specific guidance for using demand-withdraw data:
```typescript
${hasDeepDiveA || hasDeepDiveB ? `
CONFLICT PATTERN DATA TO USE:
${nameA}'s conflict style: ${deepDiveA?.communication.demandWithdrawPattern || 'unknown'}
${nameB}'s conflict style: ${deepDiveB?.communication.demandWithdrawPattern || 'unknown'}

Map these patterns:
- self_demands + partner withdraws = classic pursue-withdraw (predict ${nameA} escalating, ${nameB} shutting down)
- Both demand = explosive escalation
- Both withdraw = issues never get addressed, resentment builds
- healthy + healthy = conflicts resolve (focus on their specific triggers instead)
` : ''}
```

#### 2C. Update `toolkit` chunk (lines 1556-1582)

Tailor advice based on identified issues:
```typescript
${hasDeepDiveA && deepDiveA.intimacy.primaryGap ? `
For ${nameA}: Address their primary intimacy gap (${deepDiveA.intimacy.primaryGap})
` : ''}

${hasDeepDiveA && deepDiveA.communication.demandWithdrawPattern !== 'healthy' ? `
For ${nameA}: Include advice for their '${deepDiveA.communication.demandWithdrawPattern}' pattern
` : ''}
```

## Detailed Output Examples

### Scenario A: HIGH Satisfaction (CSI 73/81) + Deep Dive Data

**Input data:**
```json
{
  "csi_16": { "score": 73, "label": "High Satisfaction" },
  "ecr_s": { "attachmentStyleLabel": "Secure" },
  "relationship_deep_dive": {
    "communication": {
      "constructive": 4.3,
      "selfDemand": 2.1,
      "partnerDemand": 1.8,
      "demandWithdrawPattern": "healthy"
    },
    "intimacy": {
      "emotional": 4.6,
      "intellectual": 4.4,
      "recreational": 3.9,
      "sexual": 4.2,
      "primaryGap": null
    },
    "trust": 4.7,
    "security": 4.4,
    "valuesAlignment": 4.1,
    "powerBalance": 4.3
  }
}
```

**Expected AI output:**
> ## 💑 Your Current Relationship
>
> ### What's Working
>
> Your relationship satisfaction score of 73/81 isn't luck - the data shows exactly why this partnership thrives.
>
> **Your Communication Superpower**: Your conflict pattern registered as "healthy" - genuinely rare. When disagreements arise, you scored 4.3/5 on constructive resolution. Neither of you escalates into aggressive pursuit nor retreats into stony withdrawal. You can disagree without either person feeling attacked or abandoned.
>
> **Where You Connect**: Your intimacy profile shows balanced strength across all dimensions:
> - Emotional intimacy (4.6/5) - you feel genuinely seen and understood
> - Intellectual connection (4.4/5) - conversations stimulate rather than bore
> - Sexual intimacy (4.2/5) - physical connection remains alive
> - Recreational (3.9/5) - you still have fun together
>
> This balance is significant. Many couples excel in one dimension while starving others. You've cultivated the full spectrum.
>
> **Your Foundation**: Trust (4.7/5), security (4.4/5), values alignment (4.1/5), and power balance (4.3/5) all sit firmly in healthy territory. You've built what attachment researchers call "earned security" - a relationship that serves as a safe base from which you both can grow.
>
> ### Nurturing Your Bond
>
> Even thriving relationships need intentional cultivation:
>
> 1. **Protect your recreational connection** (3.9/5 - your lowest dimension). As life gets busier, play is often the first casualty. Schedule novelty: a new restaurant, an adventure neither has tried.
>
> 2. **Maintain the repair habit.** Your healthy conflict pattern exists because you've practiced it. Don't let minor irritations accumulate without resolution just because major conflicts are rare.
>
> 3. **Express the gratitude you feel.** Secure attachment can make appreciation invisible - you expect reliability so stop noticing it. Your partner's consistency is a gift worth naming.

---

### Scenario B: MODERATE Satisfaction (CSI 61/81) + Deep Dive Data

**Input data:**
```json
{
  "csi_16": { "score": 61, "label": "Moderate Satisfaction" },
  "ecr_s": { "attachmentStyleLabel": "Dismissive-Avoidant" },
  "relationship_deep_dive": {
    "communication": {
      "constructive": 3.1,
      "selfDemand": 1.9,
      "partnerDemand": 3.8,
      "demandWithdrawPattern": "partner_demands"
    },
    "intimacy": {
      "emotional": 3.4,
      "intellectual": 4.0,
      "recreational": 2.6,
      "sexual": 3.2,
      "primaryGap": "recreational"
    },
    "trust": 3.5,
    "security": 3.2,
    "valuesAlignment": 3.8,
    "powerBalance": 2.8
  }
}
```

**Expected AI output:**
> ## 💑 Your Current Relationship
>
> ### Where You Stand
>
> Your score of 61/81 places you in "moderate satisfaction" - the relationship equivalent of "fine." Not bad enough to leave, not good enough to stop that quiet wondering. Your data reveals specifically where the friction lives.
>
> **The Communication Dynamic**
>
> Your pattern shows "partner_demands" - your partner tends to pursue issues while you withdraw. Combined with your dismissive-avoidant attachment, this creates a predictable and painful cycle:
>
> They bring something up. You feel overwhelmed by the intensity. You pull back - physically leaving, going quiet, or deflecting with logic. They feel dismissed and push harder. You retreat further.
>
> Your constructive communication score (3.1/5) confirms issues aren't getting resolved - they're getting buried. Neither of you is wrong here. They need connection through processing; you need space to regulate. But without bridging this gap, resentment accumulates.
>
> **Your Primary Intimacy Gap: Recreation**
>
> At 2.6/5, recreational intimacy is your weakest dimension. When did dates become logistics? When did spontaneity become scheduling?
>
> You've built a functional partnership - intellectual connection (4.0/5) keeps conversations engaging - but may be losing the friendship underneath it. Couples who play together stay together. This isn't frivolous; it's foundational.
>
> **Foundation Concerns**
>
> Power balance sits at 2.8/5 - below healthy threshold. Examine honestly: whose preferences dominate decisions about time, money, social life? For someone with avoidant attachment, you may be withdrawing from influence rather than fighting for it. That's not peace; it's disengagement.
>
> ### The Honest Question
>
> Is this relationship growing, or just stable? Your secure attachment partner (if that's who's "demanding") may be asking the same question. Stability without growth eventually becomes stagnation.

---

### Scenario C: DISTRESSED (CSI 42/81) + Deep Dive + Problems Data

**Input data:**
```json
{
  "csi_16": { "score": 42, "label": "Potential Distress" },
  "ecr_s": { "attachmentStyleLabel": "Anxious-Preoccupied" },
  "relationship_deep_dive": {
    "communication": {
      "constructive": 2.4,
      "selfDemand": 4.1,
      "partnerDemand": 1.9,
      "demandWithdrawPattern": "self_demands"
    },
    "intimacy": {
      "emotional": 2.2,
      "intellectual": 3.0,
      "recreational": 2.4,
      "sexual": 1.9,
      "primaryGap": "sexual"
    },
    "trust": 2.1,
    "security": 2.3,
    "valuesAlignment": 2.6,
    "powerBalance": 3.4
  },
  "relationship_problems": {
    "communicationBreakdown": { "score": 3.7, "flagged": true },
    "trustIssues": { "score": 4.1, "flagged": true },
    "intimacyProblems": { "score": 3.4, "flagged": true },
    "externalStressors": { "score": 2.8, "flagged": false },
    "compatibilityConcerns": { "score": 2.9, "flagged": false },
    "primaryIssues": ["trustIssues", "communicationBreakdown", "intimacyProblems"]
  }
}
```

**Expected AI output:**
> ## 💑 Your Current Relationship
>
> ### The Truth About Where You Are
>
> Your satisfaction score of 42/81 places you in clear distress. This isn't the data being dramatic - your responses consistently indicated unhappiness, disconnection, and unmet needs. Let's look at what the specifics reveal.
>
> ### What Your Profile Reveals
>
> **Your flagged problems: Trust Issues, Communication Breakdown, Intimacy Problems**
>
> This isn't a relationship with minor friction. These are the three pillars of partnership - and all three are flagged.
>
> ---
>
> **🚨 Trust Issues (4.1/5 severity - HIGHEST)**
>
> Your responses indicated significant concerns about honesty, reliability, or past betrayals. Trust scored just 2.1/5 in your deep-dive assessment - this isn't vague unease, it's active distrust.
>
> For someone with your anxious-preoccupied attachment, trust wounds are uniquely devastating. Your attachment system is already wired for hypervigilance - scanning for signs of rejection or abandonment. When trust is broken, it doesn't just hurt; it confirms the fear you've carried since before you could name it: *people leave. People lie. People can't be counted on.*
>
> What happens when you can't trust: You seek reassurance constantly. You analyze texts for hidden meaning. You feel relief when they answer the phone, then shame for needing to check. This is exhausting - for you and for them.
>
> ---
>
> **🚨 Communication Breakdown (3.7/5 severity)**
>
> You're not being heard. Your responses indicated conversations that go nowhere, topics you've learned to avoid, and the lonely feeling of talking without being understood.
>
> Your demand-withdraw pattern registered as "self_demands" - you're the pursuer. You bring up issues. You try to fix things. You want to talk it through. And they... shut down. Leave the room. Give you the wall.
>
> Your constructive communication score (2.4/5) confirms issues aren't resolving - they're cycling. You raise it, they withdraw, you feel abandoned, you raise it harder, they withdraw further.
>
> *This pattern - pursue-withdraw - is the single strongest predictor of relationship deterioration in couples research.* Gottman's lab can predict divorce with 93% accuracy largely from watching this cycle.
>
> ---
>
> **🚨 Intimacy Problems (3.4/5 severity)**
>
> The intimacy picture tells the story of a relationship where connection has eroded across multiple dimensions:
>
> | Dimension | Score | What This Means |
> |-----------|-------|-----------------|
> | Sexual | 1.9/5 | Physical connection has collapsed |
> | Emotional | 2.2/5 | You don't feel seen or understood |
> | Recreational | 2.4/5 | You've stopped having fun together |
> | Intellectual | 3.0/5 | Still able to have surface conversations |
>
> Sexual intimacy at 1.9/5 is flagged as your primary gap - but this isn't really about sex. Physical disconnection almost always signals emotional disconnection first. The bedroom becomes a symptom of the broader distance. It's hard to want someone you don't trust, or to be vulnerable with someone who doesn't hear you.
>
> ---
>
> **The Pattern**
>
> Here's what your data shows happening:
>
> You don't trust your partner. Maybe something happened, maybe it's accumulated small betrayals, maybe their avoidance feels like rejection. So you seek reassurance - you pursue, you ask, you need confirmation they're still there. They feel suffocated by the intensity and withdraw. Their withdrawal confirms your fear. You pursue harder. They withdraw further.
>
> Meanwhile, emotional intimacy starves. You can't be vulnerable with someone who won't engage. Sexual intimacy follows - who wants to be physically open with someone who feels emotionally distant? The relationship becomes a shell where two people coexist but don't connect.
>
> Security sits at 2.3/5 - you don't feel safe in this relationship. Not physically threatened, but emotionally unsafe. You can't relax, can't trust, can't just *be*.
>
> ---
>
> ### Questions Worth Sitting With
>
> - Are you staying because you want to, or because leaving feels harder?
> - Does this relationship bring out your best self, or your most anxious, exhausted self?
> - If your best friend described exactly this situation, what would you tell them?
> - What would need to change for you to feel genuinely safe and satisfied?
> - Have you told your partner how serious this is? Do they know you're this unhappy?
>
> ### Evaluating Your Path Forward
>
> **The 90-Day Experiment**: Give yourself a defined period of genuine effort. But "effort" means both people trying - not just you pursuing harder. Track how you feel weekly. If nothing improves after real mutual effort, that's data.
>
> **The Solo Reflection**: Spend a weekend completely alone. Notice: Do you feel relief or longing? Your nervous system knows things your mind argues with.
>
> **The Honest Conversation**: Consider sharing these results with your partner. Not as an attack - as information. Their response will tell you whether change is possible. Do they get defensive, or curious? Do they dismiss your data, or acknowledge your pain?
>
> **The Professional Mirror**: One session with a couples therapist can clarify years of confusion. They're trained to spot patterns you're too close to see.
>
> ### A Note on Safety
>
> This analysis assumes a relationship between two well-meaning people who may simply be stuck in destructive patterns or incompatible. If there's any form of abuse - physical, emotional, financial, or sexual - the calculus changes entirely. Your safety comes first, always.
>
> ---
>
> *You deserve a relationship where trust is the foundation, not the wound. Where being heard is the norm, not the fight. Where intimacy is connection, not obligation. Whether that means transforming this relationship or having the courage to move on - only you can decide. But your data is clear: something needs to change.*

---

### Scenario D: Comparison Report - Both Partners Have Deep-Dive Data

**When both partners in a comparison have relationship_deep_dive data, the romantic chunk should produce:**

> ### The Relationship Dance
>
> **Your Conflict Choreography**
>
> Sarah's pattern: "self_demands" - she pursues, raises issues, needs to process verbally
> Michael's pattern: "partner_demands" - but wait, he ALSO pursues in conflicts
>
> Two demanders in the same relationship creates a specific dynamic: explosive conflicts that escalate quickly, but also resolve rather than fester. Neither of you withdraws - you both engage. This is better than pursue-withdraw, but brings its own risks:
>
> | Risk | What Happens | Prevention |
> |------|--------------|------------|
> | Escalation spirals | Both keep raising the stakes | Agree on a pause signal before reaching contempt |
> | Saying things you regret | Heat of the moment + two verbal processors | 24-hour rule on major decisions during conflict |
> | Exhausting arguments | Neither backs down | Set time limits ("We table this at 9pm") |
>
> **Intimacy Gap Alignment**
>
> Sarah's primary gap: recreational (2.4/5)
> Michael's primary gap: emotional (2.8/5)
>
> These gaps tell a story. Sarah wants more *fun* - dates, adventures, novelty. Michael wants more *depth* - feeling truly understood. If Michael interprets Sarah's activity-seeking as avoidance of emotional intimacy, and Sarah interprets Michael's depth-seeking as heaviness, you'll each feel the other is pulling away.
>
> **The Bridge**: Fun that creates emotional intimacy. Adventures that include vulnerability. New experiences you process together afterward.

## Testing Checklist

| Test Case | Data Present | Expected Behavior |
|-----------|--------------|-------------------|
| High CSI + deep-dive | relationship_deep_dive only | Explain WHY relationship works using specific scores |
| Moderate CSI + deep-dive | relationship_deep_dive only | Identify specific friction points, intimacy gaps |
| Low CSI + deep-dive + problems | Both datasets | Address each flagged issue, connect to patterns |
| Has CSI but NO deep-dive | Single user, not in relationship | Graceful fallback to attachment-only analysis |
| Comparison: both have data | Both profileA and profileB | Cross-reference patterns, predict interactions |
| Comparison: one has data | Only profileA has deep-dive | Use available data, don't break on missing |
| Comparison: neither has data | Standard comparison | Works as before (Big Five + attachment only) |

## Success Criteria

1. **Data utilization**: Every available relationship data point should appear in output when relevant
2. **Scenario differentiation**: High/moderate/distressed outputs should be clearly different in tone and content
3. **Flagged issue handling**: In distressed scenario, primaryIssues array items must each be explicitly addressed
4. **Graceful degradation**: Missing data should not cause errors; prompts should work with partial data
5. **Comparison insights**: When both partners have data, output should show pattern INTERACTIONS, not just individual descriptions
