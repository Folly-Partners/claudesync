# Physical Health Assessment Module for Deep Personality

## Summary
Add a "short but valuable" sleep/exercise/physical health assessment to the Deep Personality questionnaire, with corresponding AI analysis integration and dashboard visualizations.

## Proposed Assessments (~20 items, ~4-5 min)

### 1. Sleep Health: ISI (Insomnia Severity Index) - 7 items
- **Why ISI**: Gold standard for insomnia screening, 97% sensitivity, validated cutoffs
- **Scale**: 0-4 per item (mapped from Likert), total 0-28
- **Thresholds**: 0-7 (No insomnia), 8-14 (Subthreshold), 15-21 (Moderate), 22-28 (Severe)
- **Clinical flag**: Score >= 15 triggers AI section

**Items:**
1. Difficulty falling asleep
2. Difficulty staying asleep
3. Problem waking up too early
4. Sleep pattern satisfaction
5. How noticeable is your sleep problem to others
6. How worried about your sleep problem
7. Interference with daily functioning

### 2. Physical Activity: Godin Leisure-Time Exercise - 4 items
- **Why Godin**: Simplest validated measure, 1 min, excellent test-retest reliability
- **Scoring**: Leisure Score = (9 × strenuous) + (5 × moderate) + (3 × mild)
- **Thresholds**: <14 (Sedentary), 14-23 (Moderate), 24+ (Active)
- **Clinical flag**: Score < 14 triggers AI section

**Items:**
1. Strenuous exercise (running, sports, vigorous swimming) - times/week
2. Moderate exercise (fast walking, tennis, easy cycling) - times/week
3. Mild exercise (yoga, golf, easy walking) - times/week
4. How often do you work up a sweat? (validation item)

### 3. Physical Health Patterns: Custom Screener - 9 items
- **Domains**: Circadian rhythm, symptoms, energy, nutrition, substances, sedentary behavior
- **Scoring**: Domain averages (1-5), overall composite
- **Flags**: Chronic pain, low energy, caffeine dependence, alcohol for sleep, highly sedentary

**Items:**
1. I am naturally a "morning person" (chronotype)
2. I go to bed and wake up at roughly the same time each day (consistency)
3. I experience physical pain that affects my daily life (reverse)
4. I have enough energy to do what I want most days
5. I eat regular meals at consistent times
6. I drink enough water throughout the day
7. I rely on caffeine to get through my day (reverse)
8. I use alcohol to help me sleep or relax (reverse)
9. I spend most of my day sitting (reverse)

---

## Visualization Components (3 new components)

### SleepQualityChart.tsx
- **Type**: CircularGauge (global score) + horizontal bars (components)
- **Colors**: Green (0-7), Amber (8-14), Orange (15-21), Red (22-28)
- **Features**: Sleep duration badge, "Sleep Debt Warning" banner if <6h average
- **Comparison**: Side-by-side score cards with paired bars

### PhysicalActivityDisplay.tsx
- **Type**: RadialBarChart (MET-minutes) + stacked horizontal bar (activity breakdown)
- **Colors**: Red (vigorous), Orange (moderate), Green (walking), Gray (sitting)
- **Features**: Weekly goal progress (600 MET-min), sedentary warning banner
- **Comparison**: Paired radial bars with legend

### PhysicalHealthGauges.tsx
- **Type**: Score card grid + horizontal progress bars (like ResilienceMeters)
- **Domains**: Energy, Pain (inverted), Functioning, Sleep Impact, Activity Impact
- **Features**: Symptom flag pills, chronic conditions list, BMI badge (if available)
- **Comparison**: Paired domain bars

### Dashboard Placement
New "Physical Health" section in Wellbeing & Resilience area:
- Sleep Quality (2 cols) + Activity Level (1 col)
- Physical Health Overview (full width below)

---

## AI Assessment Integration

### Triggered Clinical Sections (5)

| Section | Title | Trigger |
|---------|-------|---------|
| Sleep Difficulties | "Your Sleep Patterns" | ISI >= 10 |
| Sedentary Lifestyle | "Your Body in Motion" | Godin < 14 |
| Physical-Mental Disconnect | "The Mind-Body Gap" | PERMA health < 4 + mental health flags |
| Chronic Fatigue | "Running on Empty (Physical)" | Low sleep + low exercise + low PERMA energy |
| Exercise-Mood Connection | "Movement as Medicine" | Mental health flag + sedentary |

### Cross-Integration with Existing Assessments

| Physical Factor | Mental Factor | Connection |
|----------------|---------------|------------|
| Poor sleep | Depression (PHQ-9) | Bidirectional causation |
| Poor sleep | Anxiety (GAD-7) | Hyperarousal preventing rest |
| Poor sleep | ADHD | Delayed circadian rhythm common |
| Sedentary | Depression | Both cause and effect |
| Sedentary | ADHD | Missed dopamine regulation opportunity |
| Low physical health | Trauma (ACE) | Somatic symptoms, body as container |
| Alcohol for sleep | Anxiety, low DTS | Maladaptive coping pattern |

### Treatment Tables Include
- CBT-I (70-80% response rate for insomnia)
- Exercise prescriptions by condition (depression, anxiety, ADHD)
- Minimum effective doses (30 min 3x/week = significant mental health benefit)
- Apps: Sleepio, VA CBT-I Coach, Apple Fitness+, Couch to 5K
- Books: *Why We Sleep*, *Spark*, *The Body Keeps the Score*
- Podcasts: Huberman Lab sleep/exercise episodes

---

## Files to Modify

### Core Data & Scoring
1. `/services/data.ts` - Add ISI, GODIN, PHYSICAL_HEALTH test definitions
2. `/services/scoring.ts` - Add scoreISI(), scoreGodin(), scorePhysicalHealth()
3. `/types.ts` - Add ISIResult, GodinResult, PhysicalHealthResult interfaces

### Configuration
4. `/config/wizard-sections.ts` - Add section metadata (icons, colors, time estimates)

### Visualization
5. `/components/visualizations/SleepQualityChart.tsx` - New component
6. `/components/visualizations/PhysicalActivityDisplay.tsx` - New component
7. `/components/visualizations/PhysicalHealthGauges.tsx` - New component
8. `/components/Dashboard.tsx` - Add Physical Health section

### AI Integration
9. `/services/analyze/prompts.ts` - Add SCORING_CONTEXT, clinical templates
10. `/services/analyze/helpers.ts` - Add detection thresholds and flags

---

## Wizard Placement Options

**Recommended**: After PERMA (wellbeing) section, before custom multiple-choice sections
- Natural flow: PERMA asks about subjective health → physical health section provides objective patterns
- Positions physical health as part of wellbeing block
- Adds ~5 min to ~70 min questionnaire (~7% increase)

---

## Implementation Order

### Phase 1: Data Layer
1. Add type definitions to `/types.ts`
2. Add test definitions to `/services/data.ts`
3. Add scoring functions to `/services/scoring.ts`

### Phase 2: Wizard Integration
4. Add section config to `/config/wizard-sections.ts`
5. Update wizard step count and flow

### Phase 3: Visualizations
6. Create `SleepQualityChart.tsx`
7. Create `PhysicalActivityDisplay.tsx`
8. Create `PhysicalHealthGauges.tsx`
9. Add Physical Health section to `Dashboard.tsx`

### Phase 4: AI Integration
10. Add scoring context to prompts
11. Add clinical section templates
12. Add detection thresholds to helpers
13. Update cross-integration instructions

---

## Decisions Confirmed
- **Length**: 20 items (~4-5 min) - validated instruments
- **Priority**: Equal weight to sleep, exercise, and overall health in AI narrative
- **Comparison Mode**: Yes - supports two-profile comparison like all other visualizations

## Status: READY FOR IMPLEMENTATION
