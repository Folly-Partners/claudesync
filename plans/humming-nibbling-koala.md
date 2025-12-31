# Plan: Update Deep Personality Marketing Test Count

## Summary
Update the marketing website to reflect the accurate count of 28 assessments (currently shows 22).

## File to Modify
`/Users/andrewwilkinson/Deep-Personality/components/LandingHero.tsx`

## Changes Required

### 1. Line 383 - Trust indicators section
**Current:** `22 clinical assessments`
**New:** `28 clinical assessments`

### 2. Line 666 - Scientific validity section
**Current:** `22 clinically validated assessments. The kind used in actual therapy and research—not "Which Disney Princess Are You?"`
**New:** `28 clinically validated assessments. The kind used in actual therapy and research—not "Which Disney Princess Are You?"`

### 3. Line 697 - "Plus X more" text
**Current:** `Plus 14 more validated assessments covering sensory processing, distress tolerance, self-compassion, wellbeing, and more.`
**New:** `Plus 20 more validated assessments covering sensory processing, distress tolerance, self-compassion, wellbeing, and more.`

(Math: 8 badges shown + 20 more = 28 total)

## No Changes Needed
- ASSESSMENTS array (lines 11-20) - keeping current 8 featured badges
- All other marketing content

## The 28 Assessments (for reference)
1. IPIP-50 (Personality/Big Five)
2. Personality Styles Inventory
3. ECR-S (Attachment)
4. CSI-16 (Relationship Satisfaction)
5. HCP Extended (Conflict Patterns)
6. DERS-16 (Emotional Regulation)
7. DTS (Distress Tolerance)
8. SCS-SF (Self-Compassion)
9. ONET-Mini (Career Interests)
10. PVQ-21 (Values)
11. WEIMS (Motivation)
12. ACE (Childhood Experiences)
13. GAD-7 (Anxiety)
14. PHQ-9 (Mood/Depression)
15. PCL-5 (Trauma/PTSD)
16. SWLS (Life Satisfaction)
17. PERMA (Wellbeing)
18. UCLA-3 (Loneliness)
19. RSQ (Rejection Sensitivity)
20. AQ-10 (Autism Screening)
21. RAADS-14 (Autism Extended)
22. CAT-Q (Masking)
23. Sensory Processing
24. Compulsive Behaviors
25. ASRS-18 (ADHD)
26. ISI (Sleep)
27. GODIN (Physical Activity)
28. Physical Health Habits
