# Capital Daily Automated Monetization Plan

## Context
- **Platform:** beehiiv (Overstory Media Group - 35 publications)
- **Publication ID:** `pub_48e0979b-d529-4b99-97f4-346e6872a0b0`
- **Subscribers:** 50,000
- **Open rate:** 50% (25k daily engaged readers)
- **Revenue potential:** $9,100 - $35,800/month
- **API Key:** Configured (tested and working)

---

## beehiiv API Automation (The Big Unlock)

The beehiiv API enables **fully automated end-to-end newsletter generation and publishing**. This changes everything - Claude generates content, API publishes it, ads are inserted programmatically.

### Key API Endpoints

| Endpoint | Purpose | Automation Value |
|----------|---------|------------------|
| `POST /posts` | Create & publish newsletters | **100% hands-off publishing** |
| `GET /segments` | Target subscriber segments | Premium ads to high-value segments |
| `GET /automations` | Trigger automation workflows | Auto-welcome, re-engagement |
| `GET /custom_fields` | Personalize content | Interest-based recommendations |
| `Webhooks` | React to subscriber events | Track conversions, upgrades |

### Available Segments for Targeting
- **Super Readers** (4,733): 80% opens, 25% CTR - premium ad inventory
- **Insider Members** (1,034): Paid subscribers - highest value
- **Business emails** (4,787): B2B ad potential
- **Open 50%+** (19,902): Engaged free readers

### Automated Publishing Workflow

```
Claude AI generates content (existing workflow)
       ↓
Convert to beehiiv blocks format
       ↓
Insert advertisement blocks (opportunity_id)
       ↓
POST /v2/publications/{pub_id}/posts
       ↓
Set scheduled_at for morning delivery
       ↓
Newsletter published automatically
```

### Create Post API Capabilities
```python
# Example: Fully automated newsletter publish
POST /v2/publications/pub_48e0979b.../posts
{
  "title": "Capital Daily - Dec 18",
  "blocks": [
    {"type": "paragraph", "text": "..."},
    {"type": "advertisement", "opportunity_id": "ad_xxx"},  # Auto-inserted ad
    {"type": "paragraph", "text": "..."}
  ],
  "scheduled_at": "2024-12-19T07:00:00Z",
  "recipients": {
    "email": {
      "tier_ids": ["free", "premium"],
      "include_segment_ids": ["seg_407a3787..."]  # Target Super Readers
    }
  }
}
```

---

## Priority 1: Zero-Touch Revenue (Day 1)

### 1. Enable beehiiv Ad Network
**Est. Revenue: $3,000-12,000/month | Effort: 30 min | 100% automated**

- Enable in beehiiv Dashboard > Monetization > Ad Network
- Set minimum CPM floor ($5+ for local content premium)
- Add 3-4 ad slot placeholders to template

**File:** `templates/newsletter-v2.html`
```html
<!-- Add after "The One Thing" section -->
{{AD_SLOT_1}}

<!-- Add after briefing section -->
{{AD_SLOT_2}}

<!-- Add before events section -->
{{AD_SLOT_3}}
```

### 2. Enable beehiiv Boosts
**Est. Revenue: $1,500-5,000/month | Effort: 15 min | 100% automated**

- Enable in beehiiv Dashboard > Monetization > Boosts
- Filter out competitor newsletters
- Place at end of newsletter before footer

**File:** `templates/newsletter-v2.html`
```html
<!-- Add before Parting Shot -->
{{BOOST_PLACEMENT}}
```

---

## Priority 2: Semi-Automated Revenue (Week 2-3)

### 3. Self-Serve Business Listings ("Open & Closed")
**Est. Revenue: $1,000-4,000/month | 75% automated**

**Pricing:**
- "Now Open" featured: $149/listing
- "Coming Soon" premium: $199/listing
- "Closing Sale" promo: $99/listing

**Implementation:**
1. Create Typeform/Tally submission form
2. Integrate Stripe payment links
3. Output to Google Sheet/Airtable
4. AI workflow pulls paid listings daily

**Files to modify:**
- `.claude/skills/writer-v2.md` - Add instructions to check submissions database
- `.claude/commands/write.md` - Add step to pull paid listings

### 4. Affiliate Links in Recommendations
**Est. Revenue: $500-2,000/month | 90% automated**

**Sign up for:**
- Amazon Associates Canada (products)
- OpenTable Affiliate (restaurants)
- Viator/GetYourGuide (experiences)
- Eventbrite Creator Network (events)

**Files to modify:**
- `.claude/skills/writer-v2.md` - Add affiliate link insertion logic for "One Thing We're Into"
- Create `data/affiliates.json` - Local business → affiliate link mapping

---

## Priority 3: Premium Tier (Month 2)

### 5. Premium Subscriptions
**Est. Revenue: $2,000-10,000/month | 95% automated**

**Pricing:** $8/month or $80/year

**Premium-only content:**
- Full main story (free gets truncated)
- "Victoria Insider" exclusive section
- Extended events list
- Ad-free experience

**Files to modify:**
- `.claude/skills/writer-v2.md` - Add premium content markers
- `templates/newsletter-v2.html` - Add premium section wrappers

---

## Revenue Timeline

| Month | Ad Network | Boosts | Listings | Affiliates | Premium | **Total** |
|-------|------------|--------|----------|------------|---------|-----------|
| 1 | $3,000 | $1,500 | - | - | - | **$4,500** |
| 3 | $5,000 | $2,500 | $1,500 | $500 | $1,000 | **$10,500** |
| 6 | $8,000 | $3,500 | $3,000 | $1,000 | $4,000 | **$19,500** |
| 12 | $12,000 | $5,000 | $4,000 | $2,000 | $8,000 | **$31,000** |

---

## Implementation Phases

### Phase 1: Enable beehiiv Monetization (Today)
- [ ] Enable Ad Network in beehiiv dashboard
- [ ] Enable Boosts in beehiiv dashboard
- [ ] Update `templates/newsletter-v2.html` with ad slot placeholders

### Phase 2: Self-Serve Listings (Week 2)
- [ ] Create Typeform submission form for business listings
- [ ] Set up Stripe payment links ($99, $149, $199)
- [ ] Create Google Sheet to collect submissions
- [ ] Update `writer-v2.md` to pull from submissions database

### Phase 3: Affiliate Integration (Week 3)
- [ ] Sign up for affiliate programs
- [ ] Create `data/affiliates.json` with Victoria business mappings
- [ ] Update `writer-v2.md` with affiliate link insertion logic

### Phase 4: Premium Launch (Month 2)
- [ ] Enable premium subscriptions in beehiiv
- [ ] Define premium-only content sections
- [ ] Update writer skill for premium content generation

---

## Critical Files

| File | Changes |
|------|---------|
| `templates/newsletter-v2.html` | Add ad slots, boost placement, premium wrappers |
| `.claude/skills/writer-v2.md` | Add monetization instructions, affiliate logic, premium markers |
| `.claude/commands/write.md` | Add step to check paid submissions before generating |
| `data/affiliates.json` | NEW - Local business to affiliate link mapping |
| `data/paid-listings.json` | NEW - Paid business listing submissions |
| `scripts/publish.py` | **NEW - API publishing script** |
| `.env.local` | Add BEEHIIV_API_KEY, BEEHIIV_PUB_ID |

---

## Full Automation: API Publishing Script

Create `scripts/publish.py` to fully automate the publish workflow:

```python
#!/usr/bin/env python3
"""
Automated beehiiv publishing for Capital Daily.
Converts generated newsletter to beehiiv blocks and publishes via API.
"""
import os
import json
import requests
from datetime import datetime, timedelta

BEEHIIV_API_KEY = os.getenv("BEEHIIV_API_KEY")
PUBLICATION_ID = "pub_48e0979b-d529-4b99-97f4-346e6872a0b0"
API_BASE = "https://api.beehiiv.com/v2"

def publish_newsletter(markdown_path: str, schedule_time: str = None):
    """
    1. Read generated markdown
    2. Convert to beehiiv blocks format
    3. Insert ad blocks at designated positions
    4. POST to beehiiv API
    5. Return post ID and web URL
    """
    # Convert markdown to beehiiv blocks
    blocks = convert_md_to_blocks(markdown_path)

    # Insert ad blocks after key sections
    blocks = insert_ad_blocks(blocks)

    # Schedule for tomorrow 7am if not specified
    if not schedule_time:
        tomorrow = datetime.now() + timedelta(days=1)
        schedule_time = tomorrow.replace(hour=7, minute=0).isoformat()

    # Create post via API
    response = requests.post(
        f"{API_BASE}/publications/{PUBLICATION_ID}/posts",
        headers={"Authorization": f"Bearer {BEEHIIV_API_KEY}"},
        json={
            "title": extract_title(markdown_path),
            "blocks": blocks,
            "scheduled_at": schedule_time,
            "recipients": {
                "email": {"tier_ids": ["free", "premium"]},
                "web": {"tier_ids": ["free", "premium"]}
            }
        }
    )
    return response.json()
```

### New Slash Command: `/publish`

Add `.claude/commands/publish.md`:
```markdown
After generating a newsletter with /write:
1. Run scripts/publish.py with the output file
2. Confirm scheduled time with user
3. POST to beehiiv API
4. Return confirmation with scheduled time and preview link
```

---

## Scalability: 35 Publications

This same automation can be extended to all Overstory publications:
- Victoria Tech Journal, The Westshore, Oak Bay Local
- Calgary Citizen, Fraser Valley Current
- Georgia Straight (and its Food/Music/Arts verticals)

Each publication just needs its own:
1. Research skill (local sources)
2. Writer skill (brand voice)
3. Publication ID in config

---

## Key Principle

**Automate the revenue, not the editorial.** Ads and boosts are fully programmatic. Affiliate links are templated. API handles publishing. But content selection and voice stay human-guided via the AI skills.
