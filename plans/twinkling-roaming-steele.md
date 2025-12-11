# Plan: Unify Question Wording Across All Sections

## Problem
The assessment has jarring transitions between sections due to inconsistent question formats:
- Most sections use first-person statements ("I often feel blue")
- **O*NET Career**: Uses imperative tasks ("Build kitchen cabinets")
- **PVQ-21 Values**: Uses third-person descriptions ("This person thinks...")
- **WEIMS Motivation**: Uses sentence fragments ("Because I derive...")

This creates a disjointed user experience and may confuse respondents.

## Goal
Unify all sections to use **first-person statements** while preserving clinical validity.

---

## File to Modify
`services/data.ts`

---

## Section-by-Section Analysis

### Already Consistent (No Changes Needed)
| Section | Format | Status |
|---------|--------|--------|
| IPIP-50 | "I often feel blue." | ✅ Good |
| Personality Styles | "I often feel like others are watching me." | ✅ Good |
| ECR-S | "I worry about being abandoned." | ✅ Good |
| DERS-16 | "When I'm upset, I have difficulty..." | ✅ Good |

### Needs Minor Cleanup
| Section | Issue | Fix |
|---------|-------|-----|
| CSI-16 | Mixed formats (some questions, some statements) | Standardize to statements |

### Needs Rewording (Major)
| Section | Current Format | Target Format |
|---------|---------------|---------------|
| O*NET Career | "Build kitchen cabinets." | "I would enjoy building things like cabinets or furniture." |
| PVQ-21 Values | "This person thinks..." | "I think it is important that..." |
| WEIMS Motivation | "Because I derive..." | "I work because I derive..." or "I find pleasure in learning new things at work." |

---

## Detailed Changes

### 1. O*NET Career Items (30 items)
**Current:** Task-based imperatives
**New:** First-person enjoyment statements

Update description:
```
'Rate how much you agree with each statement about work activities you would enjoy.'
```

Example rewrites:
| Current | New (First-Person) |
|---------|-------------------|
| Build kitchen cabinets. | I would enjoy building things with my hands. |
| Repair household appliances. | I would enjoy fixing and repairing equipment. |
| Study the structure of the human body. | I would enjoy studying how biological systems work. |
| Write scripts for movies or television shows. | I would enjoy writing creative content like scripts or stories. |
| Manage a clothing store. | I would enjoy managing a retail business. |
| Develop a spreadsheet using computer software. | I would enjoy organizing data using spreadsheets. |

### 2. PVQ-21 Values Items (21 items)
**Current:** Third-person portraits ("This person thinks...")
**New:** First-person value statements

Update description:
```
'Indicate how much each statement reflects what is important to you.'
```

Example rewrites:
| Current | New (First-Person) |
|---------|-------------------|
| Thinking up new ideas and being creative is important to this person. They like to do things in their own original way. | I value thinking up new ideas and being creative. I like to do things in my own original way. |
| It is important to this person to be rich. They want to have a lot of money and expensive things. | It is important to me to be financially successful. I want to have money and nice things. |
| This person believes that people should do what they are told. They think people should follow rules at all times. | I believe people should follow rules and do what they are told. |

### 3. WEIMS Motivation Items (18 items)
**Current:** "Because..." sentence fragments
**New:** Complete first-person statements

Update description:
```
'Indicate how much each statement reflects why you work or pursue your goals.'
```

Example rewrites:
| Current | New (First-Person) |
|---------|-------------------|
| Because I derive much pleasure from learning new things. | I find great pleasure in learning new things through my work. |
| For the satisfaction I experience from taking on interesting challenges. | I feel satisfied when I take on interesting challenges at work. |
| Because it has become a fundamental part of who I am. | My work has become a fundamental part of who I am. |
| For the income it provides me. | I work primarily for the income it provides. |
| I don't know why, we are provided with unrealistic working conditions. | I'm not sure why I work; the conditions often feel unrealistic. |

### 4. CSI-16 Cleanup (16 items)
**Current:** Mixed questions and statements
**New:** All statements

Example:
| Current | New |
|---------|-----|
| Please indicate the degree of happiness, all things considered, in your relationship. | All things considered, I feel happy in my relationship. |
| How rewarding is your relationship with your partner? | My relationship with my partner is rewarding. |
| How often do you and your partner have fun together? | My partner and I have fun together often. |

---

## Clinical Validity Notes

### Why These Changes Are Safe:
1. **O*NET**: The official O*NET Interest Profiler uses "Like/Dislike/Unsure" ratings for activities. Converting to "I would enjoy..." preserves the same construct (occupational interests) while using clearer language.

2. **PVQ-21**: Schwartz's original PVQ uses third-person to reduce social desirability bias. However, first-person versions have been validated (e.g., SVS - Schwartz Value Survey uses first-person). The key is measuring relative value priorities, which is preserved.

3. **WEIMS**: The original scale uses "Because..." format tied to the stem "Why do you do your work?" Converting to complete sentences that contain the same meaning preserves the motivational constructs from Self-Determination Theory.

4. **General**: Research shows response format changes (third-person vs first-person) have minimal impact on factor structure when the semantic content is preserved (Podsakoff et al., 2003).

---

## Implementation Order

1. Update **section descriptions** to match new format
2. Reword **O*NET items** (30 items)
3. Reword **PVQ-21 items** (21 items)
4. Reword **WEIMS items** (18 items)
5. Clean up **CSI-16 items** (16 items)
6. Test to ensure all items render correctly

---

## Complete Item Rewrites

### O*NET (30 items) - Full List
```
// Realistic
R_1: "I would enjoy building things with my hands, like cabinets or furniture."
R_2: "I would enjoy fixing and repairing mechanical or electrical equipment."
R_3: "I would enjoy doing hands-on installation work."
R_4: "I would enjoy operating machinery or power tools."
R_5: "I would enjoy working in physically demanding outdoor environments."

// Investigative
I_1: "I would enjoy studying how the human body works."
I_2: "I would enjoy conducting scientific research."
I_3: "I would enjoy observing and analyzing behavior patterns."
I_4: "I would enjoy examining data or samples under close analysis."
I_5: "I would enjoy developing new treatments or procedures."

// Artistic
A_1: "I would enjoy writing scripts, stories, or creative content."
A_2: "I would enjoy composing or arranging music."
A_3: "I would enjoy designing visual artwork or graphics."
A_4: "I would enjoy creating digital media or visual effects."
A_5: "I would enjoy building sets, props, or art installations."

// Social
S_1: "I would enjoy teaching children."
S_2: "I would enjoy helping people with personal or emotional problems."
S_3: "I would enjoy planning and leading group activities."
S_4: "I would enjoy teaching adults new skills."
S_5: "I would enjoy coordinating care or activities for others."

// Enterprising
E_1: "I would enjoy managing a store or business."
E_2: "I would enjoy selling products or services."
E_3: "I would enjoy negotiating deals and contracts."
E_4: "I would enjoy managing teams or departments."
E_5: "I would enjoy starting and running my own business."

// Conventional
C_1: "I would enjoy working with spreadsheets and data."
C_2: "I would enjoy maintaining detailed records and logs."
C_3: "I would enjoy calculating finances or budgets."
C_4: "I would enjoy proofreading and checking for accuracy."
C_5: "I would enjoy organizing filing systems and records."
```

### PVQ-21 (21 items) - Full List
```
// Self-Direction
pvq_1: "I value thinking up new ideas and being creative. I like doing things my own way."
pvq_11: "It is important to me to make my own decisions. I like to be free to plan and choose my activities."

// Stimulation
pvq_6: "I like surprises and always look for new things to do. I think it's important to do many different things in life."
pvq_15: "I look for adventures and like to take risks. I want to have an exciting life."

// Hedonism
pvq_10: "Having a good time is important to me. I like to treat myself."
pvq_21: "I seek every chance to have fun. Doing things that give me pleasure is important."

// Achievement
pvq_4: "It is important to me to show my abilities. I want people to admire what I do."
pvq_13: "Being very successful is important to me. I hope people will recognize my achievements."

// Power
pvq_2: "It is important to me to be financially successful. I want to have money and nice things."
pvq_17: "It is important to me to be in charge and tell others what to do."

// Security
pvq_5: "It is important to me to live in secure surroundings. I avoid anything that might endanger my safety."
pvq_14: "It is important to me that my safety is protected. I want to feel secure."

// Conformity
pvq_7: "I believe people should do what they are told and follow rules at all times."
pvq_16: "It is important to me to always behave properly and avoid doing anything wrong."

// Tradition
pvq_9: "It is important to me to be humble and modest. I try not to draw attention to myself."
pvq_20: "Tradition is important to me. I try to follow customs from my religion or family."

// Benevolence
pvq_12: "It is very important to me to help the people around me and care for their well-being."
pvq_18: "It is important to me to be loyal to my friends and devote myself to people close to me."

// Universalism
pvq_3: "I think it is important that every person be treated equally with equal opportunities."
pvq_8: "It is important to me to listen to people who are different. I want to understand them even when I disagree."
pvq_19: "I strongly believe people should care for nature. Looking after the environment is important to me."
```

### WEIMS (18 items) - Full List
```
// Intrinsic
weims_1: "I find great pleasure in learning new things through my work."
weims_2: "I feel satisfied when taking on interesting challenges."
weims_3: "I feel accomplished when I succeed at difficult tasks."

// Integrated
weims_4: "My work has become a fundamental part of who I am."
weims_5: "My work is part of how I have chosen to live my life."
weims_6: "My job is an important part of my life."

// Identified
weims_7: "I chose this type of work to achieve my career goals."
weims_8: "I chose this work to attain a certain lifestyle."
weims_9: "I chose this work to pursue my career plan."

// Introjected
weims_10: "I want to succeed at my job; otherwise I would feel ashamed."
weims_11: "I want to be very good at my work; otherwise I would be disappointed in myself."
weims_12: "I want to be a 'winner' in life."

// External
weims_13: "I work for the income it provides."
weims_14: "I work because it allows me to earn money."
weims_15: "I work because it provides me with security."

// Amotivation
weims_16: "I'm not sure why I work; the conditions often feel unrealistic."
weims_17: "I'm not sure why I work; too much is expected of me."
weims_18: "I question why I work; I struggle to manage the important tasks."
```

### CSI-16 Cleanup (16 items)
```
csi_1: "Overall, I feel happy in my relationship."
csi_2: "Things between me and my partner generally go well."
csi_3: "Our relationship is strong."
csi_4: "My relationship makes me happy."
csi_5: "I have a warm and comfortable relationship with my partner."
csi_6: "I feel like part of a team with my partner."
csi_7: "My relationship is rewarding."
csi_8: "My partner meets my needs well."
csi_9: "My relationship has met my original expectations."
csi_10: "I am satisfied with my relationship."
csi_11: "My relationship is better than most."
csi_12: "I enjoy my partner's company."
csi_13: "My partner and I have fun together often."
csi_14: "I still feel a strong connection with my partner."
csi_15: "If I could do it over, I would choose the same partner."
csi_16: "I can confide in my partner about virtually anything."
```
