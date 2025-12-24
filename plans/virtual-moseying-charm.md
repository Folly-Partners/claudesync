# Fix Overstory Stories Tab Display

## Problem Summary

The Stories tab after "Gather Stories" is confusing and incomplete:
1. **0 Stories found** - but 4 news stories exist in the research JSON
2. **Events show only dates** - no event titles, times, venues, or descriptions
3. **Facebook posts not displayed** - 5 posts exist but aren't shown

## Root Cause

Field name mismatches between the UI component and the research JSON:

| UI Code Expects | JSON Actually Has |
|-----------------|-------------------|
| `research.stories` | `research.news` |
| `story.title` | `story.headline` |
| `event.title` | `event.name` |
| `event.location` | `event.venue` |

Plus the UI only displays a subset of available data (missing time, price, description, category).

## Files to Modify

**Primary file:** `/Users/andrewwilkinson/overstory/web/app/[pub]/publication-tabs.tsx`

## Implementation Plan

### 1. Fix News Stories Display (lines 119, 131-138)

Change:
```tsx
const stories = (research.stories as Array<...>) || [];
```
To:
```tsx
const stories = (research.news as Array<{ headline: string; source: string; summary?: string; category?: string; url?: string }>) || [];
```

Update rendering to use `story.headline` instead of `story.title`.

### 2. Fix Events Display (lines 120, 150-160)

Update type definition:
```tsx
const events = (research.events as Array<{
  name: string;
  date: string;
  time?: string;
  venue?: string;
  price?: string;
  description?: string;
  category?: string;
  family_friendly?: boolean;
}>) || [];
```

Redesign event cards to show:
- **Name** (title) - prominently displayed
- **Date & Time** - on same line
- **Venue** - location with address
- **Price** - Free or cost
- **Category badge** - community, religious, dining, etc.
- **Description** - truncated with option to expand

### 3. Add Facebook Posts Section (new section ~line 161)

Add new section after Events:
```tsx
{facebookPosts.length > 0 && (
  <div>
    <h3>Community Posts ({facebookPosts.length})</h3>
    {/* Display posts with text, newsletter_potential badge, suggested_angle */}
  </div>
)}
```

### 4. UI/UX Improvements

- Events: Change from 2-column grid to single-column cards with more detail
- Add category badges (color-coded: community=blue, religious=purple, dining=orange)
- Add "Free" badge for free events
- Add family-friendly indicator icon
- Truncate long descriptions with "Show more" expansion

## Expected Result

After fix:
- **4 Stories found** with headlines, sources, summaries
- **9 Events** with full details (name, date, time, venue, price, category)
- **5 Community Posts** from Facebook with newsletter potential indicators

## Visual Mockup

### Event Card (proposed):
```
┌────────────────────────────────────────────────┐
│ [community]                              [Free] │
│ 7th Annual Dryfe Street Christmas Eve Singalong │
│ Dec 24 • 5:00 PM                               │
│ 2414 Dryfe Street, Estevan                     │
│ Stephanie Greaves leads Christmas carols...    │
│                                     [Show more] │
└────────────────────────────────────────────────┘
```

### Story Card (proposed):
```
┌────────────────────────────────────────────────┐
│ [crime]                                        │
│ 98-Year-Old Oak Bay Resident Robbed of $3,000  │
│ Gold Necklace                                  │
│ Vancouver Island Free Daily / Oak Bay Police   │
│ A thief snatched a gold chain necklace from... │
└────────────────────────────────────────────────┘
```
