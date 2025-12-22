# Overstory Dashboard Redesign Plan

## Problem Summary

The current UI is confusing because:
1. **Too many steps** - 5 separate stages when users just want to create and send
2. **Tabs duplicate the stepper** - both show the same workflow redundantly
3. **"Stories" shows 0** - Bug: UI looks for `stories` field but data has `news`
4. **Events show only dates** - No titles, venues, or useful details
5. **No clear "what's next"** - User doesn't know what to do

## Solution: 3-Step Workflow

Simplify to THREE steps:

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   CREATE    │  →   │   PREVIEW   │  →   │    SEND     │
│   DRAFT     │      │   & EDIT    │      │             │
└─────────────┘      └─────────────┘      └─────────────┘
     │                     │                    │
     │                     │                    │
     ▼                     ▼                    ▼
  Automated:            Interactive:         Final:
  • Gather stories      • Edit content       • Confirm
  • Write draft         • Swap ads in/out    • Publish
  • Fill ad slots       • Tweak copy
```

---

## Part 1: Critical Bug Fix

### Fix `news` vs `stories` Field Mismatch

**Files to modify:**
- `web/app/[pub]/page.tsx` (lines 60-62)
- `web/app/[pub]/publication-tabs.tsx` (line 119)

**Change:**
```typescript
// Before (broken)
const storyCount = researchData?.stories?.length || 0;

// After (fixed)
const storyCount = researchData?.news?.length || 0;
```

---

## Part 2: New 3-Step Architecture

### Component Structure
```
components/newsletter/
├── newsletter-flow.tsx         # Main 3-step container
├── flow-progress.tsx           # Simple 3-dot progress indicator
├── activity-panel.tsx          # Shows what's happening during Create
└── steps/
    ├── create-step.tsx         # Step 1: Automated draft creation
    ├── preview-step.tsx        # Step 2: Interactive editing
    └── send-step.tsx           # Step 3: Final confirmation
```

---

## Part 3: Step 1 - Create Draft

**What it does (automated):**
1. Gather stories from news sources
2. Gather events from calendars
3. Write newsletter draft using AI
4. Fill ad slots (booked ads + house ads for empty slots)

**UI During Creation:**
```
┌─────────────────────────────────────────────────────────────────┐
│                    Creating Today's Newsletter                   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ ✓ Gathered 5 stories from local sources                     ││
│  │ ✓ Found 13 upcoming events                                  ││
│  │ ● Writing newsletter draft...                               ││
│  │ ○ Filling ad slots                                          ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  [═══════════════════════════════════░░░░░░░░░░░] 65%           │
└─────────────────────────────────────────────────────────────────┘
```

**UI After Creation (shows what was gathered):**
```
┌─────────────────────────────────────────────────────────────────┐
│  ✓ Draft Ready                          5 Stories • 13 Events   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  STORIES INCLUDED                                                │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ Free New Year's Events at Oak Bay Rec Centre                ││
│  │ Oak Bay Recreation announces family-friendly programs...    ││
│  │ [OAK BAY NEWS] • Community                                  ││
│  └─────────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ Artistry of Hope in Oak Bay                                 ││
│  │ Exploring public art and sculptures around the village...   ││
│  │ [TWEED MAGAZINE] • Arts & Culture                           ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  EVENTS                                                          │
│  ┌───────────────────┐ ┌───────────────────┐ ┌─────────────────┐│
│  │ Dec 24 • 5pm      │ │ Dec 25 • Evening  │ │ Dec 26 • 10am   ││
│  │ Community         │ │ Christmas Dinner  │ │ Boxing Day      ││
│  │ Caroling          │ │ Oak Bay Beach     │ │ Swim            ││
│  │ FREE              │ │ Hotel • $85       │ │ $5              ││
│  └───────────────────┘ └───────────────────┘ └─────────────────┘│
│                                                                  │
│  RULED OUT (2 duplicates)                          [Show ▼]     │
│                                                                  │
│  AD SLOTS                                          $224 revenue  │
│  ✓ Primary Sponsor: Acme Co                                      │
│  ✓ Mid-Newsletter: Local Cafe                                    │
│  ○ Featured Event: (house ad)                                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
│  [══════════════ PREVIEW & EDIT ══════════════]                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Part 4: Step 2 - Preview & Edit (Interactive)

**What user can do:**
- View the email as it will appear
- Edit text directly (inline or modal editor)
- Swap ads in/out (toggle paid ads, choose different house ads)
- Re-order sections
- Toggle mobile/desktop preview

**UI Layout:**
```
┌─────────────────────────────────────────────────────────────────┐
│  Preview & Edit                    [Desktop] [Mobile] [Edit]    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                                                              ││
│  │                    [Email Preview Iframe]                    ││
│  │                                                              ││
│  │    Click any section to edit                                 ││
│  │                                                              ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  AD SLOTS                                                        │
│  ┌─────────────────────┐ ┌─────────────────────┐                │
│  │ Primary Sponsor     │ │ Mid-Newsletter      │                │
│  │ ✓ Acme Co - $125    │ │ ✓ Local Cafe - $75  │                │
│  │ [Swap] [Remove]     │ │ [Swap] [Remove]     │                │
│  └─────────────────────┘ └─────────────────────┘                │
│  ┌─────────────────────┐ ┌─────────────────────┐                │
│  │ Featured Event      │ │ Business Spotlight  │                │
│  │ ○ House Ad          │ │ ○ Empty             │                │
│  │ [Choose Ad]         │ │ [Add Ad]            │                │
│  └─────────────────────┘ └─────────────────────┘                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
│  [══════════════ SEND NEWSLETTER ══════════════]                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Part 5: Step 3 - Send

**What it shows:**
- Final confirmation checklist
- Subscriber count
- Revenue summary
- Send button

**UI Layout:**
```
┌─────────────────────────────────────────────────────────────────┐
│                      Ready to Send                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                   [Thumbnail Preview]                        ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  Checklist:                                                      │
│  ✓ 5 stories included                                            │
│  ✓ 13 events listed                                              │
│  ✓ 2 paid sponsors ($200)                                        │
│  ✓ 2 house ads for empty slots                                   │
│                                                                  │
│  Sending to: 4,521 subscribers                                   │
│  Scheduled: 7:00 AM PT                                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
│  [══════════════ PUBLISH NOW ══════════════]                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Part 6: Content Cards (Friendly Visual Design)

### Story Card
```
┌─────────────────────────────────────────────────────────────────┐
│ Free New Year's Events at Oak Bay Rec Centre                    │
│ Oak Bay Recreation announces family-friendly programs for...    │
│                                                                  │
│ [OAK BAY NEWS]  •  Community  •  Feature                        │
└─────────────────────────────────────────────────────────────────┘
```

### Event Card
```
┌───────────────────────┐
│ Dec 24 • 5:00 PM      │
│ ───────────────────── │
│ Community Caroling    │  ← Event NAME (prominent!)
│ Dryfe Street          │
│ [FREE]                │  ← Green badge for free
└───────────────────────┘
```

### Duplicate Card (grayed out, collapsible section)
```
┌─────────────────────────────────────────────────────────────────┐
│ ✗ Oak Bay Rec Centre Holiday Events                    [SKIPPED]│
│   87% similar to "Free New Year's Events..."                    │
│   Matching: oak-bay-rec-centre, new-years, family-friendly      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Part 7: Facebook Scraping Investigation

### Current Status
```json
"facebook_posts": [],
"facebook_note": "Facebook scraping requires authentication"
```

### Fix Options
1. **Configure Apify with FB credentials** - Add Facebook login cookies
2. **Manual FB input** - Paste posts into UI
3. **Skip FB** - Rely on other sources

---

## Implementation Order

### Phase 1: Bug Fix (5 min)
1. Fix `news` vs `stories` field mismatch
2. Verify stories display correctly

### Phase 2: New 3-Step Flow (2 hours)
1. Create `components/newsletter/` directory
2. Build `NewsletterFlow` container with 3 steps
3. Build `FlowProgress` (3 dots)

### Phase 3: Create Step (1 hour)
1. Build `CreateStep` with progress UI
2. Combine existing pipeline calls (research + write + prepare)
3. Show summary after completion with story/event cards

### Phase 4: Preview Step (1.5 hours)
1. Build `PreviewStep` with iframe
2. Add inline editing capability
3. Add ad slot management (swap/remove/add)
4. Desktop/mobile toggle

### Phase 5: Send Step (30 min)
1. Build `SendStep` with checklist
2. Confirmation UI
3. Connect to publish API

### Phase 6: Integration (30 min)
1. Replace old components in `page.tsx`
2. Remove `publication-tabs.tsx` and `workflow-controller.tsx`
3. Test full flow

---

## Files to Modify

### Delete
- `web/app/[pub]/publication-tabs.tsx`
- `web/components/pipeline/workflow-controller.tsx`

### Modify
- `web/app/[pub]/page.tsx` - New 3-step flow, fix news/stories bug

### Create
- `web/components/newsletter/newsletter-flow.tsx`
- `web/components/newsletter/flow-progress.tsx`
- `web/components/newsletter/activity-panel.tsx`
- `web/components/newsletter/steps/create-step.tsx`
- `web/components/newsletter/steps/preview-step.tsx`
- `web/components/newsletter/steps/send-step.tsx`
- `web/components/newsletter/cards/story-card.tsx`
- `web/components/newsletter/cards/event-card.tsx`
- `web/components/newsletter/cards/ad-slot-card.tsx`

---

## API Changes

### New Combined Endpoint
`POST /api/pipeline/create-draft`
- Runs: research → write → prepare (all in sequence)
- Returns: combined status with all content
- Streams progress updates via SSE

This replaces calling 3 separate endpoints.
