# Capital Daily Newsletter Design Improvement Plan

## Focus: Automatic Image Integration

User direction: Add image slots AND automatically find/insert appropriate images.

---

## Emotional Goals

A local community newsletter should evoke:
- **Belonging** — "I'm part of this community"
- **Informed** — "I know what's happening before anyone else"
- **Connected** — "I care about this place and its people"
- **Anticipation** — "I'm excited to check what's happening today"
- **Trust** — "This is my reliable morning ritual"
- **Pride** — "Victoria is a great place to live"

---

## Current State Analysis

### What's Working Well
1. **Strong brand identity** — The yellow (#f8df29) is distinctive and memorable
2. **Clear section structure** — Labeled headers create predictable rhythm
3. **Excellent voice** — Warm, local, conversational copy
4. **Yellow highlight boxes** — "The One Thing" commands attention
5. **"The Number"** — Large typography draws the eye, tells a story
6. **Open & Closed color dots** — Green/red/yellow provide instant parsing
7. **P.S. engagement** — Proven conversion tactic
8. **Cream background** — Warmer than stark white, feels local/artisanal

### Critical Issues

| Issue | Impact | Emotion Blocked |
|-------|--------|-----------------|
| **Zero images** | Wall of text fatigue | Connection, Pride |
| **Yellow overload** (3 boxes) | Nothing stands out | Hierarchy confusion |
| **Cramped sections** | Visual overwhelm | Calm, Trust |
| **No CTA buttons** | Weak click-through | Action, Anticipation |
| **Events are text blocks** | Can't scan quickly | Anticipation |
| **Sections look identical** | Hard to navigate | Informed |
| **Plain footer** | Missed engagement | Belonging |

---

## Design Improvements

### 1. HERO IMAGE CAPABILITY (High Impact)

**Problem:** The entire newsletter has zero images. This creates a cold, text-heavy experience.

**Solution:** Add optional hero image slot after the hook or at the main story.

```html
<!-- Add after weather-inline -->
<div class="hero-image" style="margin: 25px 0;">
    <img src="{{HERO_IMAGE_URL}}" alt="{{HERO_IMAGE_ALT}}"
         style="width: 100%; border-radius: 8px;">
    <p class="image-caption" style="font-size: 13px; color: #666;
       margin-top: 8px; text-align: center;">{{HERO_IMAGE_CAPTION}}</p>
</div>
```

**When to use:** Orca sightings, community events, local landmarks, breaking news visuals.

---

### 2. YELLOW HIERARCHY FIX (High Impact)

**Problem:** Three yellow boxes compete (header, The One Thing, Featured Event). The eye doesn't know where to focus.

**Solution:** Reserve yellow for ONE highlight only.

**Changes:**
- **Header** — Keep yellow (brand anchor)
- **"The One Thing"** — Keep yellow (the hero moment)
- **"If You Do One Thing" event** — Change to white background with yellow left border + subtle cream background

```css
.featured-event {
    background: #fffef5;
    border-left: 4px solid #f8df29;
    padding: 25px;
    border-radius: 0 8px 8px 0;
}
```

**Result:** "The One Thing" becomes the singular visual priority.

---

### 3. WHITE SPACE & BREATHING ROOM (High Impact)

**Problem:** Sections feel cramped. 30px margins blend together.

**Changes:**
- Section margins: `30px` → `40px`
- Dividers: Add more visual weight or remove in favor of space
- Content padding: `30px` → `35px`

```css
.divider {
    border: none;
    height: 40px; /* Pure whitespace divider */
}

.section-break {
    margin: 45px 0;
    border-top: 1px solid #e5e5e5;
}
```

---

### 4. CTA BUTTONS (High Impact)

**Problem:** Links are just underlined text. "Check the outage map →" doesn't invite clicking.

**Solution:** Add yellow button style for primary CTAs.

```css
.btn-primary {
    display: inline-block;
    background: #f8df29;
    color: #1a1a1a;
    padding: 12px 24px;
    border-radius: 6px;
    font-weight: 700;
    font-size: 14px;
    text-decoration: none;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.btn-secondary {
    display: inline-block;
    border: 2px solid #1a1a1a;
    color: #1a1a1a;
    padding: 10px 20px;
    border-radius: 6px;
    font-weight: 600;
    font-size: 14px;
    text-decoration: none;
}
```

**Usage:**
- "Get tickets" → `.btn-primary`
- "Check outage map" → `.btn-secondary`
- "Read more" → text link (keep subtle)

---

### 5. EVENT CARDS REDESIGN (High Impact)

**Problem:** "Also Great This Week" events are text paragraphs. Hard to scan.

**Solution:** Visual card format with clear hierarchy.

```css
.event-card {
    display: flex;
    gap: 15px;
    padding: 18px 0;
    border-bottom: 1px solid #e5e5e5;
}

.event-card-icon {
    width: 48px;
    height: 48px;
    background: #f5f5f0;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 24px;
    flex-shrink: 0;
}

.event-card-content {
    flex: 1;
}

.event-card-title {
    font-family: 'Domine', Georgia, serif;
    font-weight: 700;
    font-size: 17px;
    margin-bottom: 4px;
}

.event-card-meta {
    font-size: 13px;
    color: #666;
    margin-bottom: 6px;
}

.event-card-desc {
    font-size: 15px;
    color: #444;
    line-height: 1.5;
}
```

**HTML Structure:**
```html
<div class="event-card">
    <div class="event-card-icon">🎹</div>
    <div class="event-card-content">
        <div class="event-card-title">A Charlie Brown Christmas</div>
        <div class="event-card-meta">Hermann's Jazz Club · Tonight 7pm · $40</div>
        <div class="event-card-desc">The Vince Guaraldi score performed live...</div>
    </div>
</div>
```

---

### 6. SECTION DIFFERENTIATION (Medium Impact)

**Problem:** "The Number", "One Thing We're Into", "This Day in Victoria" all look identical.

**Solution:** Give each section a unique visual signature.

| Section | Treatment |
|---------|-----------|
| **The Number** | Gray background, centered (keep current) |
| **One Thing We're Into** | White bg, yellow left border, food emoji prominent |
| **This Day in Victoria** | Subtle sepia/parchment tint (#faf8f0), vintage feel |
| **Parting Shot** | Current cream gradient (keep) |

```css
.history-section {
    background: #faf8f0;
    border-left: 3px solid #c9a961; /* Aged gold instead of yellow */
    padding: 20px 25px;
    border-radius: 0 8px 8px 0;
}

.into-section {
    background: #fff;
    border-left: 4px solid #f8df29;
    padding: 20px 25px;
}
```

---

### 7. WEATHER MODULE UPGRADE (Medium Impact)

**Problem:** Weather bar is subtle gray. Doesn't feel useful or prominent.

**Solution:** Make it a proper forecast widget.

```css
.weather-widget {
    background: linear-gradient(135deg, #e8f4fc 0%, #f0f7fa 100%);
    border: 1px solid #d4e5ed;
    padding: 15px 20px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    gap: 15px;
    margin-bottom: 25px;
}

.weather-icon {
    font-size: 32px;
}

.weather-temp {
    font-family: 'Domine', Georgia, serif;
    font-size: 28px;
    font-weight: 700;
}

.weather-desc {
    font-size: 15px;
    color: #444;
    line-height: 1.4;
}
```

---

### 8. FOOTER ENHANCEMENT (Medium Impact)

**Problem:** Plain dark footer misses engagement opportunities.

**Additions:**
- Social media icons
- "Share with a friend" CTA
- Subscriber count (social proof)

```html
<div class="footer">
    <div class="footer-logo">Capital Daily</div>

    <p class="footer-cta">
        Love this newsletter? <a href="#" class="share-link">Share with a friend</a>
    </p>

    <div class="footer-social">
        <a href="#">Instagram</a> · <a href="#">Twitter</a> · <a href="#">Facebook</a>
    </div>

    <p class="footer-count">Join 50,000+ Victorians who start their day with us</p>

    <div class="footer-links">
        <a href="#">Website</a>
        <a href="#">Manage Preferences</a>
        <a href="#">Unsubscribe</a>
    </div>
</div>
```

---

### 9. ENGAGEMENT MICRO-INTERACTIONS (Lower Priority)

Add quick feedback/poll at end:

```html
<div class="quick-poll">
    <p class="poll-question">Was today's newsletter helpful?</p>
    <div class="poll-options">
        <a href="#" class="poll-btn">👍 Yes</a>
        <a href="#" class="poll-btn">👎 Could be better</a>
    </div>
</div>
```

---

### 10. TYPOGRAPHY REFINEMENTS (Lower Priority)

| Element | Current | Recommended |
|---------|---------|-------------|
| Body text | 18px | 17px (slightly tighter) |
| Story headline | 26px | 28px (more contrast) |
| Section headers | 13px | 11px (smaller, more refined) |
| Line height | 1.65 | 1.7 (more breathing room) |

---

## Implementation Plan: Automatic Image Integration

### Image Slot Locations

| Slot | Purpose | Size | When to Use |
|------|---------|------|-------------|
| **Hero Image** | After hook, before The One Thing | 600x300px | Major visual stories (orcas, storms, events) |
| **Story Image** | Within main story section | 600x250px | Always if story has visual element |
| **Featured Event** | Inside the event highlight box | 600x200px | Events with compelling venues/visuals |

### Automatic Image Sourcing Strategy

**Option A: Unsplash API (Recommended)**
- Free for commercial use with attribution
- High-quality editorial photos
- Search by keyword (e.g., "victoria bc", "orca whale", "christmas market")
- API: `https://api.unsplash.com/search/photos?query=...`

**Option B: Google Custom Search API**
- More specific results for local Victoria content
- Requires API key + Custom Search Engine ID
- Can restrict to specific domains (Tourism Victoria, etc.)

**Option C: Firecrawl Image Extraction**
- Already have Firecrawl MCP
- Extract images from source articles during research phase
- Most contextually relevant but may have licensing issues

### Recommended Approach: Hybrid

1. **During research phase**, extract image URLs from source articles using Firecrawl
2. **Store in research JSON** with source attribution
3. **For generic topics**, fall back to Unsplash search
4. **For events**, scrape event page for official promotional images

### Image Selection Logic

```
For each story/event:
1. Check if source article has a relevant image → use it (with attribution)
2. If no source image, search Unsplash for:
   - Story topic keywords + "victoria bc" or "british columbia"
   - Event venue name
   - General category (e.g., "ferry", "city council", "christmas lights")
3. If no good match, omit image for that section
```

### Research JSON Schema Update

```json
{
  "stories": [
    {
      "headline": "...",
      "content": "...",
      "image": {
        "url": "https://...",
        "alt": "Description for accessibility",
        "caption": "Photo credit or context",
        "source": "unsplash|scraped|manual",
        "attribution": "Photo by X on Unsplash"
      }
    }
  ]
}
```

### Template Updates Needed

1. Add `.hero-image` CSS class with responsive styling
2. Add `.story-image` CSS class
3. Add `.event-image` CSS class
4. Add image caption styling
5. Add conditional rendering (show image div only if image exists)

---

## Files to Modify

1. **`templates/newsletter-v2.html`** — Add image slots and CSS
2. **`.claude/skills/research.md`** — Update to extract/source images during research
3. **`.claude/skills/writer-v2.md`** — Guidelines for image selection and alt text
4. **Research workflow** — Add Unsplash API integration or enhanced Firecrawl image extraction

---

## Before/After Vision

**Before:** Dense wall of text with competing yellow boxes, no visual variety, hard to scan.

**After:** Clean, scannable newsletter with ONE yellow hero moment, visual event cards, CTA buttons that invite clicks, breathing room that feels calm and trustworthy.

The goal: Make readers feel like they're getting a curated morning briefing from a smart friend — not reading a text document.
