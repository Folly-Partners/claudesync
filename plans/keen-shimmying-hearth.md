# Add Pre-Publish Preview with Ads

**Goal:** See the final newsletter with all ads/fallbacks filled BEFORE publishing to Beehiiv.

---

## Current Workflow (Problem)

```
/research → /write → /preview → /publish --html
                        ↓              ↓
                  HTML without     Checks sponsorships,
                  ads filled       fills ads, publishes
                                   (no preview of final result)
```

**Problem:** User can't see which ads will be inserted until after publishing.

---

## Proposed Workflow

```
/research → /write → /preview → /prepare → /publish
                        ↓           ↓           ↓
                  Basic HTML   Check sponsors,  Just sends the
                  preview      fill ads,        prepared HTML
                               show final       to Beehiiv
                               preview
```

---

## Implementation Options

### Option A: New `/prepare` Command

Create a new command that:
1. Runs sponsorship checker (browser agent)
2. Fills ad slots with 3-tier fallback
3. Saves prepared HTML to `output/{pub}/{date}-prepared.html`
4. Opens in browser for review
5. Logs decisions to revenue-log.json (but doesn't mark partners as "used" yet)

Then `/publish` just sends the prepared file.

### Option B: Modify `/preview` to Include Ads

Add `--with-ads` flag to existing preview command:
- `/preview` - Basic preview (current behavior)
- `/preview --with-ads` - Runs sponsorship check, fills slots, shows final preview

### Option C: Add `--prepare` flag to `/publish`

- `/publish --prepare` - Check sponsors, fill ads, show preview, DON'T send
- `/publish --send` - Send previously prepared HTML
- `/publish` (no flags) - Current behavior (prepare + send in one step)

---

## Recommendation: Option A (New `/prepare` Command)

Clearest separation of concerns:
- `/preview` = See your content layout
- `/prepare` = Finalize ads and see what will actually be sent
- `/publish` = Send to Beehiiv

---

## Implementation Plan

### 1. Create `/prepare` Command

**File:** `.claude/commands/prepare.md`

```markdown
# Prepare Command

Finalize newsletter by checking for booked sponsorships and filling ad slots.
Generates final preview for review BEFORE publishing.

## What It Does

1. Check Beehiiv for booked Direct Sponsorships (browser agent)
2. Fill empty ad slots with goodwill partners or house ads
3. Generate final HTML with all ads in place
4. Save to `output/{pub}/{date}-prepared.html`
5. Open in browser for review
6. Show ad slot summary

## Usage

/prepare [publication] [date]
/prepare                      # Active publication, today
/prepare oak-bay-local        # Specific publication

## Output

- Prepared HTML file
- Console summary of ad decisions
- Browser preview opens automatically
```

### 2. Create `scripts/prepare.py`

New script that:
1. Loads the preview HTML from `/preview`
2. Calls sponsorship checker agent (Browserbase)
3. Loads sponsorship data from JSON
4. Runs ad slot filling (without marking partners as used)
5. Saves prepared HTML
6. Opens in browser

```python
def prepare_newsletter(pub_slug: str, date_str: str):
    # Load preview HTML
    preview_html = load_preview_html(pub_slug, date_str)

    # Check for sponsorships (triggers browser agent)
    # Agent saves to data/sponsorships/{pub}/{date}-sponsorships.json
    run_sponsorship_check(pub_slug, date_str)

    # Load sponsorship data
    sponsorships = load_sponsorships_from_file(pub_slug, date_str)

    # Fill ad slots (preview mode - don't update partner tracking yet)
    manager = AdSlotManager(preview_mode=True)
    prepared_html, decisions = manager.fill_all_slots(preview_html, sponsorships)

    # Save prepared HTML
    output_path = save_prepared_html(pub_slug, date_str, prepared_html)

    # Save decisions (for /publish to use)
    save_ad_decisions(pub_slug, date_str, decisions)

    # Open in browser
    open_in_browser(output_path)

    # Print summary
    print_ad_summary(decisions)
```

### 3. Modify `scripts/ad_slots.py`

Add `preview_mode` parameter:
- `preview_mode=True` - Don't update `last_featured` or `use_count`
- `preview_mode=False` - Update tracking (used by /publish)

### 4. Modify `/publish` Command

Change to use prepared HTML:
1. Look for `{date}-prepared.html` first
2. If not found, warn user to run `/prepare` first
3. When publishing, THEN update partner/house-ad tracking
4. Log to revenue-log.json

### 5. Update Workflow Docs

Update CLAUDE.md and command docs to reflect new flow.

---

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `.claude/commands/prepare.md` | Create | New command documentation |
| `scripts/prepare.py` | Create | Preparation script |
| `scripts/ad_slots.py` | Modify | Add `preview_mode` parameter |
| `scripts/publish.py` | Modify | Use prepared HTML, update tracking on publish |
| `.claude/commands/publish.md` | Modify | Update docs for new workflow |
| `CLAUDE.md` | Modify | Update quick start workflow |

---

## User Experience

### Before (Current)

```
User: /publish oak-bay-local --html

[Sponsorships checked, ads filled, published]
✓ Published to Beehiiv!

User: Wait, what ads did it use? Can I see it first?
```

### After (New)

```
User: /prepare oak-bay-local

Checking for booked sponsorships...
  → Navigating to Beehiiv dashboard...
  → Found 1 booked sponsorship

Filling ad slots...
  primary_sponsor: PAID (Oak Bay Beach Hotel)
  mid_newsletter: Neighbour Spotlight (Ottavio Italian Bakery)
  featured_event: Empty
  business_spotlight: House Ad (sell-business-spotlight)
  bulletin_board: 3 Facebook posts + 1 paid

✓ Prepared HTML saved to output/oak-bay-local/2024-12-20-prepared.html
✓ Opening in browser...

Review the newsletter. When ready, run /publish to send.

---

User: /publish oak-bay-local

Publishing prepared newsletter...
  → Using output/oak-bay-local/2024-12-20-prepared.html
  → Pushing to Beehiiv...

✓ Published to Beehiiv!
  Post ID: post_abc123
  Status: draft
  Preview: https://...
```

---

## Testing Checklist

- [ ] `/prepare` runs sponsorship checker
- [ ] `/prepare` fills ad slots correctly
- [ ] `/prepare` opens browser preview
- [ ] `/prepare` doesn't mark partners as used
- [ ] `/publish` uses prepared HTML
- [ ] `/publish` updates partner tracking
- [ ] `/publish` warns if no prepared file exists
- [ ] Full workflow works end-to-end

---

## Complete Newsletter Workflow (Step-by-Step)

This is the full end-to-end workflow for generating and publishing a newsletter.

### Phase 1: Set Publication Context

**Command:** `/publication oak-bay-local`

**What happens:**
1. Validates publication against `publications/config.json`
2. Writes slug to `.active-publication`
3. Loads publication config (ID, brand color, geography, schedule)
4. Confirms the switch with publication details

**Files involved:**
- `publications/config.json` - All publication IDs & settings
- `.active-publication` - Current context file

---

### Phase 2: Research Content

**Command:** `/research`

**What happens:**
1. **Load context**
   - Read `.active-publication` for current publication
   - Load `publications/{slug}/sources.md` for publication-specific sources
   - Load `data/story-log.json` for deduplication (last 7 days, this pub only)
   - Load `data/source-registry.json` for verification tiers

2. **Gather content by type**
   - **Weather:** Fetch for publication geography (Victoria/Oak Bay/Langford)
   - **Events:** Check official sources, venue calendars, community calendars
   - **Local News:** Tavily search, established media, official sources
   - **Facebook Groups:** (if configured) Apify scraper for community posts
   - **Special sections:** Ship tracker, restaurant news, etc.

3. **Process each story**
   - Generate fingerprint (entities, numbers, verbs, category)
   - Check against URL index (skip duplicates)
   - Calculate similarity score against recent stories
   - Classify claim risk (HIGH/MEDIUM/LOW)
   - Verify against source tier requirements
   - Log fact-check to `data/fact-check-archive/`

4. **Classify Facebook posts** (Oak Bay Local)
   - Filter for bulletin board candidates (3+ engagements, last 7 days)
   - Categorize: ISO, For Sale, Services, Lost, Found, Recs, Jobs
   - Extract author, neighbourhood, truncated text

5. **Save research output**
   - `research/{publication}/{DATE}-research.json`
   - Includes: weather, events, news, facebook_posts, bulletin_board_posts
   - Verification summary and skipped duplicates

**Files involved:**
- `publications/{slug}/sources.md` - Source registry
- `data/story-log.json` - Deduplication index
- `data/source-registry.json` - Verification tiers
- `data/fact-check-archive/` - Verification logs
- `research/{publication}/{DATE}-research.json` - Output

---

### Phase 3: Write Newsletter

**Command:** `/write`

**What happens:**
1. **Load required data**
   - Read `.active-publication`
   - Load `publications/{slug}/brand.md` (voice, tone, sections)
   - Load research JSON from Phase 2
   - Load `data/story-log.json` for context

2. **Content selection (deduplication)**
   - Check each story's `dedup_analysis` classification
   - Skip duplicates, include updates with new info
   - Frame updates as "Update:" or "As we reported..."

3. **Fact-checking validation**
   - Verify names, numbers, dates, locations, quotes
   - Check confidence levels (HIGH/MEDIUM/LOW)
   - Flag LOW confidence items for human review

4. **Liability check**
   - Avoid accusations without charges
   - Use safe language ("Police are investigating...")
   - No defamatory language

5. **Write newsletter**
   - Apply publication voice (greeting, tone, sign-off)
   - Structure: Greeting → Briefing → Main Story → Events → Closing
   - Include publication-specific sections

6. **Save outputs**
   - `output/{publication}/{DATE}-newsletter.md` - Main content
   - `output/{publication}/{DATE}-fact-check.json` - Verification log
   - Update `data/story-log.json` with stories used

**Files involved:**
- `publications/{slug}/brand.md` - Voice guidelines
- `research/{publication}/{DATE}-research.json` - Input
- `output/{publication}/{DATE}-newsletter.md` - Output
- `output/{publication}/{DATE}-fact-check.json` - Verification log
- `data/story-log.json` - Updated with new stories

---

### Phase 4: Generate HTML Preview

**Command:** `/preview`

**What happens:**
1. Load newsletter markdown from `output/{publication}/{DATE}-newsletter.md`
2. Load HTML template from `publications/{slug}/template.html`
3. Parse content and populate placeholders:
   - `{{WEATHER_SUMMARY}}` - Weather block
   - `{{BRIEFING_ITEMS}}` - Bullet points
   - `{{MAIN_STORY_HEADLINE}}` - Main story
   - `{{EVENTS_SECTION}}` - Formatted events
   - `{{DATE}}` - Today's date
4. Save HTML to `output/{publication}/{DATE}-preview.html`
5. Open in browser

**Note:** At this stage, ad slot placeholders are still empty:
- `{{SPONSOR_CONTENT}}`
- `{{MID_NEWSLETTER_AD}}`
- `{{FEATURED_EVENT}}`
- `{{BUSINESS_SPOTLIGHT}}`
- `{{BULLETIN_FEATURED}}`

**Files involved:**
- `output/{publication}/{DATE}-newsletter.md` - Input
- `publications/{slug}/template.html` - Template
- `output/{publication}/{DATE}-preview.html` - Output

---

### Phase 5: Prepare for Publishing (NEW)

**Command:** `/prepare`

**What happens:**
1. **Load preview HTML**
   - Read `output/{publication}/{DATE}-preview.html`

2. **Check for booked sponsorships**
   - Trigger browser agent (Browserbase + Playwright)
   - Navigate to Beehiiv Direct Sponsorships dashboard
   - Scrape any booked placements for today's date
   - Save to `data/sponsorships/{publication}/{DATE}-sponsorships.json`

3. **Load sponsorship data**
   - Read sponsorship JSON file
   - Parse slot → advertiser mappings

4. **Fill ad slots (3-tier fallback)**
   For each empty slot:
   ```
   Tier 1: Paid (from Beehiiv)
   Tier 2: Goodwill partner (from data/goodwill-partners.json)
   Tier 3: House ad (from data/house-ads.json)
   ```

   **Slot-specific behavior:**
   | Slot | Paid | Goodwill | House |
   |------|------|----------|-------|
   | `primary_sponsor` | "Together With" | "Neighbour Spotlight" | "This could be you" |
   | `mid_newsletter` | Native ad | Partner spotlight | Cross-promo |
   | `featured_event` | Featured event | (leave empty) | Sister pub event |
   | `business_spotlight` | Spotlight | Partner in Open & Closed | Referral program |
   | `bulletin_board` | Featured pin ($49) | Facebook posts | "Pin to board" CTA |

5. **Save prepared HTML** (without updating tracking)
   - `output/{publication}/{DATE}-prepared.html`

6. **Save ad decisions**
   - `data/sponsorships/{publication}/{DATE}-decisions.json`

7. **Open in browser for review**

8. **Print summary to console**
   ```
   Filling ad slots...
     primary_sponsor: PAID (Oak Bay Beach Hotel)
     mid_newsletter: Neighbour Spotlight (Ottavio Italian Bakery)
     featured_event: Empty
     business_spotlight: House Ad (sell-business-spotlight)
   ```

**Files involved:**
- `output/{publication}/{DATE}-preview.html` - Input
- `data/sponsorships/{publication}/{DATE}-sponsorships.json` - Beehiiv data
- `data/goodwill-partners.json` - Tier 2 fallback
- `data/house-ads.json` - Tier 3 fallback
- `output/{publication}/{DATE}-prepared.html` - Output
- `data/sponsorships/{publication}/{DATE}-decisions.json` - Decision log

---

### Phase 6: Publish to Beehiiv

**Command:** `/publish`

**What happens:**
1. **Load prepared HTML**
   - Look for `output/{publication}/{DATE}-prepared.html`
   - If not found, warn user to run `/prepare` first

2. **Update tracking** (NOW, not before)
   - Mark goodwill partners as used (`last_featured`, `feature_count`)
   - Mark house ads as used (`last_used`, `use_count`)
   - Save updated JSON files

3. **Log revenue decisions**
   - Append to `data/revenue-log.json`
   - Record which slots got paid vs fallback

4. **Prepare API payload**
   - Extract title from content
   - Calculate scheduled send time from publication config
   - Build `content_html` payload

5. **Push to Beehiiv API**
   ```
   POST /v2/publications/{pub_id}/posts
   {
     "title": "Oak Bay Local - December 21, 2024",
     "content_html": "<full HTML>",
     "status": "draft",
     "scheduled_at": "2024-12-21T07:30:00"
   }
   ```

6. **Confirm success**
   - Print Post ID, status, preview URL
   - Remind user to review draft in Beehiiv before scheduling

**Files involved:**
- `output/{publication}/{DATE}-prepared.html` - Input
- `data/goodwill-partners.json` - Updated with tracking
- `data/house-ads.json` - Updated with tracking
- `data/revenue-log.json` - Append new entry
- Beehiiv API - Create draft post

---

### Summary: Full Command Sequence

```
/publication oak-bay-local    # 1. Set context
/research                     # 2. Gather content
/write                        # 3. Generate newsletter markdown
/preview                      # 4. Create HTML preview (no ads)
/prepare                      # 5. Fill ads, show final preview
/publish                      # 6. Push to Beehiiv
```

### Data Flow Diagram

```
                    publications/config.json
                           ↓
/publication  →  .active-publication
                           ↓
/research     →  research/{pub}/{date}-research.json
                           ↓
/write        →  output/{pub}/{date}-newsletter.md
                           ↓
/preview      →  output/{pub}/{date}-preview.html
                           ↓
/prepare      →  output/{pub}/{date}-prepared.html  ←  data/sponsorships/
              ↓                                     ←  data/goodwill-partners.json
              ↓                                     ←  data/house-ads.json
              ↓
/publish      →  Beehiiv API (draft)
              →  data/revenue-log.json (updated)
              →  data/goodwill-partners.json (tracking updated)
              →  data/house-ads.json (tracking updated)
```
