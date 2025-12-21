# Overstory Web Interface Plan

## Overview

Build a web interface to manage the Overstory newsletter automation system, replacing Beehiiv's storefront with a Stripe-powered ad sales system and AI-powered ad moderation.

## Core Principle

**Claude Code remains the engine** - the web UI is an "observer + trigger" layer that:
- Displays pipeline status (reads JSON files)
- Manages ad sales and payments (Stripe)
- Moderates ad submissions (AI)
- Triggers Claude Code commands for content generation

---

## Tech Stack

- **Framework**: Next.js 15 (App Router)
- **Database**: SQLite via Turso (sync from existing JSON, add new tables)
- **UI**: Tailwind + shadcn/ui
- **Payments**: Stripe Checkout + Webhooks
- **AI Moderation**: Claude API (Haiku for speed/cost)
- **Auth**: Simple password or Clerk (single user initially)
- **Deploy**: Vercel

---

## Feature 1: Dashboard

**Purpose**: At-a-glance status of all publications

```
┌──────────────────────────────────────────────────────────┐
│ OVERSTORY                             Sat, Dec 21, 2024  │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Capital Daily    ━━━━━━━━━━━━○○○○  Research in 2h       │
│  Oak Bay Local    ━━━━━━━━━━━━━━●○  Ready to publish     │
│  The Westshore    ○○○○○○○○○○○○○○○○  Not scheduled        │
│  Tasting Victoria ━━━━━━━━━━━━━━━●  Published 8:00 AM    │
│                                                          │
├──────────────────────────────────────────────────────────┤
│  💰 Week: $325   📧 Sent: 4   👥 12,450 subs   🎯 3 ads  │
└──────────────────────────────────────────────────────────┘
```

**Data sources**:
- `data/story-log.json` (last_edition per pub)
- `output/{pub}/` (check for today's files)
- `publications/config.json` (schedule)

---

## Feature 2: Publication Pipeline

**Purpose**: Detailed view of each publication's workflow

**Stages**: Research → Write → Preview → Prepare → Publish

**Actions**:
- View stage outputs (research JSON, draft MD, preview HTML)
- Trigger next stage (invokes Claude Code)
- Edit content inline
- Skip stages / restart

**Files to read**:
- `research/{pub}/{date}-research.json`
- `output/{pub}/{date}-newsletter.md`
- `output/{pub}/{date}-preview.html`
- `output/{pub}/{date}-prepared.html`

---

## Feature 3: Stripe-Powered Ad Sales

**Purpose**: Replace Beehiiv storefront with our own system

### Ad Products (per publications/config.json)

| Product | Price | Inventory | Description |
|---------|-------|-----------|-------------|
| Primary Sponsor | $125 | 1/edition | "Together With" top placement |
| Mid-Newsletter | $75 | 1/edition | Native ad between sections |
| Featured Event | $50 | 1/edition | Top of events section |
| Business Spotlight | $99 | 1/edition | Enhanced business listing |
| Bulletin Board | $49 | 3/edition | Classified ad on pinboard |

### Self-Service Booking Flow

```
┌─────────────────────────────────────────────────────────┐
│ Advertise with Oak Bay Local                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. Select Ad Type                                      │
│     ○ Primary Sponsor ($125) - SOLD Dec 23             │
│     ● Mid-Newsletter ($75) - Available                  │
│     ○ Featured Event ($50) - Available                  │
│     ○ Bulletin Board ($49) - 2 of 3 available          │
│                                                         │
│  2. Select Date                                         │
│     [Calendar showing Dec 23, 25, 27 available]         │
│                                                         │
│  3. Your Ad Content                                     │
│     Business Name: [________________]                   │
│     Headline: [________________________]                │
│     Description: [____________________]                 │
│     CTA Text: [____________] URL: [__________]          │
│     Logo: [Upload]                                      │
│                                                         │
│  4. Review & Pay                                        │
│     [Stripe Checkout Button]                            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Database Schema (New Tables)

```sql
-- Ad bookings (replaces checking Beehiiv)
CREATE TABLE ad_bookings (
  id TEXT PRIMARY KEY,
  publication TEXT NOT NULL,
  edition_date DATE NOT NULL,
  slot_type TEXT NOT NULL,  -- primary_sponsor, mid_newsletter, etc.

  -- Advertiser info
  advertiser_name TEXT NOT NULL,
  advertiser_email TEXT NOT NULL,

  -- Ad content
  headline TEXT,
  body TEXT,
  cta_text TEXT,
  cta_url TEXT,
  logo_url TEXT,

  -- Payment
  stripe_checkout_id TEXT,
  stripe_payment_intent TEXT,
  amount_cents INTEGER,
  paid_at TIMESTAMP,

  -- Moderation
  status TEXT DEFAULT 'pending',  -- pending, approved, flagged, rejected
  ai_moderation_result JSON,
  moderated_at TIMESTAMP,
  moderator_notes TEXT,

  -- Tracking
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP
);

-- Bulletin board classifieds (higher volume)
CREATE TABLE classifieds (
  id TEXT PRIMARY KEY,
  publication TEXT NOT NULL,
  edition_date DATE NOT NULL,

  -- Submitter
  submitter_name TEXT NOT NULL,
  submitter_email TEXT NOT NULL,

  -- Content
  category TEXT,  -- for_sale, services, events, housing, jobs, etc.
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  contact_info TEXT,
  image_url TEXT,

  -- Payment
  stripe_checkout_id TEXT,
  amount_cents INTEGER DEFAULT 4900,
  paid_at TIMESTAMP,

  -- Moderation
  status TEXT DEFAULT 'pending',
  ai_moderation JSON,
  ai_rewrite_suggestion TEXT,
  final_content TEXT,  -- After human approval/edit

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Availability tracking
CREATE TABLE inventory (
  publication TEXT NOT NULL,
  edition_date DATE NOT NULL,
  slot_type TEXT NOT NULL,
  total INTEGER DEFAULT 1,
  booked INTEGER DEFAULT 0,
  PRIMARY KEY (publication, edition_date, slot_type)
);
```

### Stripe Integration

**Webhook events to handle**:
- `checkout.session.completed` → Mark booking as paid, trigger AI moderation
- `payment_intent.payment_failed` → Mark booking failed
- `charge.refunded` → Cancel booking

**Products in Stripe**:
- Create products for each ad type
- Use metadata for publication + slot_type
- Dynamic pricing by publication if needed

---

## Feature 4: AI Ad Moderation

**Purpose**: Auto-approve clean ads, flag/rewrite problematic ones

### Moderation Flow

```
Ad Submitted → AI Review → Decision
                  │
                  ├── APPROVE (auto) → Ready for edition
                  │
                  ├── SUGGEST_REWRITE → Show rewrite, advertiser approves
                  │
                  ├── FLAG → Human review queue
                  │
                  └── REJECT (auto) → Refund + notification
```

### AI Moderation Prompt

```typescript
const moderationPrompt = `
You are reviewing an ad submission for ${publication.name},
a local community newsletter in ${publication.geography}.

Brand voice: Professional, friendly, community-focused.
Audience: Local residents, families, small business owners.

Review this ad for:
1. **Appropriateness**: No adult content, hate speech, scams, MLM
2. **Brand fit**: Matches community newsletter tone
3. **Accuracy**: No misleading claims, fake urgency
4. **Quality**: Clear, well-written, professional

Ad submission:
- Business: ${ad.advertiser_name}
- Headline: ${ad.headline}
- Body: ${ad.body}
- CTA: ${ad.cta_text} → ${ad.cta_url}

Respond with JSON:
{
  "decision": "approve" | "suggest_rewrite" | "flag" | "reject",
  "confidence": 0.0-1.0,
  "issues": ["issue1", "issue2"],
  "rewrite": {
    "headline": "...",
    "body": "..."
  } | null,
  "reason": "Brief explanation"
}
`;
```

### Moderation Queue UI

```
┌──────────────────────────────────────────────────────────┐
│ Ad Moderation Queue                          3 pending   │
├──────────────────────────────────────────────────────────┤
│                                                          │
│ ⚠️ FLAGGED - Oak Bay Bikes                              │
│    "Best prices GUARANTEED!!!"                           │
│    Issue: Superlative claim needs verification           │
│    AI Suggestion: "Competitive prices on quality bikes"  │
│    [Approve Original] [Use Rewrite] [Edit] [Reject]      │
│                                                          │
│ ✏️ REWRITE SUGGESTED - Mary's Pet Sitting               │
│    Original: "ur pets r in gud hands lol"               │
│    Suggested: "Your pets are in caring hands"           │
│    [Approve Rewrite] [Edit] [Keep Original]              │
│                                                          │
│ ✅ AUTO-APPROVED (today: 5)                              │
│    Marina Restaurant, Village Books, Habit Coffee...     │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Bulletin Board Categories

```typescript
const classifiedCategories = [
  'for_sale',      // Furniture, cars, misc items
  'services',      // Contractors, tutors, pet care
  'events',        // Garage sales, community events
  'housing',       // Rentals, roommates
  'jobs',          // Local job postings
  'wanted',        // Looking for items/services
  'lost_found',    // Pets, items
  'free',          // Free items, giveaways
];
```

---

## Feature 5: Revenue & Analytics

**Purpose**: Track ad revenue, see what's working

### Revenue Dashboard

```
┌──────────────────────────────────────────────────────────┐
│ Revenue - December 2024                                  │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Total Revenue     $1,247                                │
│  ├─ Primary        $500  (4 bookings)                   │
│  ├─ Mid-Newsletter $225  (3 bookings)                   │
│  ├─ Events         $150  (3 bookings)                   │
│  ├─ Spotlight      $198  (2 bookings)                   │
│  └─ Classifieds    $196  (4 bookings)                   │
│                                                          │
│  Fill Rate                                               │
│  ├─ Paid           42%                                   │
│  ├─ Goodwill       31%                                   │
│  └─ House          27%                                   │
│                                                          │
│  By Publication                                          │
│  ├─ Capital Daily  $623                                 │
│  ├─ Oak Bay Local  $374                                 │
│  ├─ The Westshore  $150                                 │
│  └─ Tasting Vic    $100                                 │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Feature 6: Goodwill & House Ad Management

**Purpose**: Manage the fallback tiers when no paid ads

### Goodwill Partners

- View all partners with rotation stats
- Add new partners
- Edit partner content
- Set priority and category
- See last featured date

### House Ads

- View all house ads
- Edit copy/CTA
- Set slot targeting
- Track performance (if adding CTR later)

---

## Implementation Phases

### Phase 1: Foundation (MVP)
- [ ] Next.js app scaffold in `~/overstory/web/`
- [ ] Read-only dashboard (reads JSON files)
- [ ] Publication pipeline view
- [ ] Basic auth (password)

### Phase 2: Ad Sales
- [ ] Stripe products setup
- [ ] Public storefront pages
- [ ] Checkout flow
- [ ] Webhook handling
- [ ] Database for bookings

### Phase 3: AI Moderation
- [ ] Claude API integration (Haiku)
- [ ] Moderation queue UI
- [ ] Rewrite suggestions
- [ ] Approval workflow

### Phase 4: Classifieds
- [ ] Bulletin board submission form
- [ ] Category selection
- [ ] Higher volume moderation
- [ ] Inventory management (3 per edition)

### Phase 5: Integration
- [ ] Replace Beehiiv storefront links
- [ ] Update `/prepare` to read from DB instead of browser scraping
- [ ] Remove sponsorship-checker browser automation
- [ ] Update house ads CTAs to point to new storefront

### Phase 6: Analytics
- [ ] Revenue dashboard
- [ ] Fill rate tracking
- [ ] Per-publication breakdown

---

## File Structure

```
~/overstory/
├── web/                          # NEW
│   ├── app/
│   │   ├── page.tsx              # Dashboard
│   │   ├── [pub]/
│   │   │   └── page.tsx          # Publication pipeline
│   │   ├── advertise/
│   │   │   ├── page.tsx          # Public storefront
│   │   │   └── [pub]/page.tsx    # Per-publication booking
│   │   ├── classifieds/
│   │   │   └── page.tsx          # Bulletin board submissions
│   │   ├── moderation/
│   │   │   └── page.tsx          # AI moderation queue
│   │   ├── revenue/
│   │   │   └── page.tsx          # Revenue dashboard
│   │   ├── settings/
│   │   │   ├── partners/         # Goodwill partners
│   │   │   └── house-ads/        # House ad management
│   │   └── api/
│   │       ├── stripe/
│   │       │   └── webhook/      # Stripe webhooks
│   │       ├── moderation/
│   │       │   └── review/       # AI moderation endpoint
│   │       └── trigger/
│   │           └── [command]/    # Invoke Claude Code
│   ├── components/
│   ├── lib/
│   │   ├── db.ts                 # Turso/SQLite
│   │   ├── stripe.ts             # Stripe helpers
│   │   ├── claude.ts             # Claude Code bridge
│   │   └── moderation.ts         # AI moderation
│   └── ...
├── publications/                  # Existing
├── data/                         # Existing JSON
├── scripts/                      # Existing Python
└── ...
```

---

## Key Integration Points

### 1. Replace Beehiiv Storefront

**Before** (in house-ads.json):
```json
"cta_url": "{{BEEHIIV_STOREFRONT_URL}}"
```

**After**:
```json
"cta_url": "https://overstory.app/advertise/oak-bay-local"
```

### 2. Replace Sponsorship Checker

**Before** (`/prepare` command):
1. Run browser agent to scrape Beehiiv
2. Save to `{date}-sponsorships.json`
3. Fill slots from that file

**After** (`/prepare` command):
1. Query SQLite for paid bookings on that date
2. Fill slots from database
3. No browser automation needed

### 3. Revenue Logging

**Before**: Logs to `revenue-log.json` with source type only
**After**: Full payment data in SQLite with Stripe IDs

---

## Decisions Made

1. **Multi-publication bundles**: YES - Offer bundle pricing for booking across publications
2. **Advertiser accounts**: NO - Guest checkout only, keep it simple
3. **Beehiiv cutover**: HARD CUTOVER - Disable Beehiiv storefront when new system launches
4. **Auto-reject**: NO - AI flags only, human decides all rejections (no auto-refunds)

---

## Bundle Pricing Feature

Since advertisers can book across publications, add bundle options:

```
┌─────────────────────────────────────────────────────────┐
│ Bundle Deals                                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ 🎯 Regional Reach (all 4 publications)                  │
│    Primary Sponsor: $400 (save $100)                    │
│    Mid-Newsletter: $240 (save $60)                      │
│                                                         │
│ 🏘️ Victoria Core (Capital Daily + Oak Bay Local)       │
│    Primary Sponsor: $225 (save $25)                     │
│                                                         │
│ 🍽️ Food Focus (Capital Daily + Tasting Victoria)       │
│    Primary Sponsor: $225 (save $25)                     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Updated Database Schema

```sql
-- Bundle bookings
CREATE TABLE bundle_bookings (
  id TEXT PRIMARY KEY,
  bundle_type TEXT NOT NULL,  -- regional_reach, victoria_core, food_focus
  slot_type TEXT NOT NULL,
  edition_date DATE NOT NULL,

  -- Advertiser (guest checkout)
  advertiser_name TEXT NOT NULL,
  advertiser_email TEXT NOT NULL,

  -- Content (shared across publications)
  headline TEXT,
  body TEXT,
  cta_text TEXT,
  cta_url TEXT,
  logo_url TEXT,

  -- Payment
  stripe_checkout_id TEXT,
  amount_cents INTEGER,
  discount_cents INTEGER,
  paid_at TIMESTAMP,

  -- Moderation (one review covers all pubs)
  status TEXT DEFAULT 'pending',
  ai_moderation_result JSON,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Link bundles to individual publication slots
CREATE TABLE bundle_slots (
  bundle_id TEXT REFERENCES bundle_bookings(id),
  publication TEXT NOT NULL,
  edition_date DATE NOT NULL,
  slot_type TEXT NOT NULL,
  PRIMARY KEY (bundle_id, publication)
);
```

---

## Moderation Flow (Updated)

Since AI cannot auto-reject:

```
Ad Submitted → AI Review → Decision
                  │
                  ├── APPROVE (auto) → Ready for edition
                  │
                  ├── SUGGEST_REWRITE → Advertiser reviews suggestion
                  │
                  └── FLAG → Human review queue
                              │
                              ├── Human APPROVE
                              ├── Human EDIT + APPROVE
                              └── Human REJECT + Manual Refund
```

**All rejections require**:
1. Human review in moderation queue
2. Manual decision to reject
3. Manual Stripe refund trigger
4. Email notification to advertiser
