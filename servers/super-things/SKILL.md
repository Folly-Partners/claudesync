---
name: superthings
description: Use when triaging Things inbox, creating tasks, or managing todos. Learns from corrections to improve title suggestions and project assignments over time.
---

# SuperThings - Intelligent Task Management

SuperThings learns from your corrections to get better at suggesting titles and projects for Things tasks.

## Learning System

### Pattern Storage
Learned patterns are stored in `~/claudesync/servers/super-things/data/patterns.json`:

```json
{
  "title_transforms": [
    {
      "match": "^Fix ",
      "transform": "Delegate to Brianna: {original}",
      "confidence": 12,
      "examples": ["Fix fireplace", "Fix garage door"]
    }
  ],
  "project_hints": {
    "build": {"Deep Work": 15, "Computer": 2},
    "research": {"Computer": 23, "Deep Work": 1},
    "call": {"Call": 18}
  },
  "exact_overrides": {}
}
```

### How to Use Learned Patterns

**Before triaging inbox**, load patterns:
```bash
cat ~/claudesync/servers/super-things/data/patterns.json
```

**When suggesting titles/projects:**
1. Check `exact_overrides` for exact title matches (highest priority)
2. Apply `title_transforms` if regex pattern matches
3. Extract keywords from title and check `project_hints` for weighted suggestions
4. Fall back to hardcoded defaults if no pattern matches

**Show learning indicator** when a suggestion comes from learned patterns:
```
"Fix dishwasher" → "Delegate to Brianna: Fix dishwasher" [learned: 12x]
```

### Logging Corrections

After user confirms/modifies suggestions, log to `~/claudesync/servers/super-things/data/history.jsonl`:

```json
{"ts": "2025-12-30T10:00:00Z", "original": "Fix fireplace", "suggested_title": "Delegate to Brianna: Fix fireplace", "final_title": "Delegate to Brianna: Fix fireplace", "suggested_project": "Computer", "final_project": "Computer", "title_accepted": true, "project_accepted": true}
```

### Updating Patterns

After logging, update `patterns.json`:

**If suggestion accepted:** Increment confidence
```json
// Before: "confidence": 12
// After:  "confidence": 13
```

**If title corrected:** Learn new transform pattern
- Extract the transformation (what changed?)
- Add new `title_transforms` entry or update existing
- Add example to `examples` array

**If project corrected:** Update project_hints
```json
// User changed "Build X" from Computer to Deep Work
"project_hints": {
  "build": {"Deep Work": 16, "Computer": 2}  // +1 to Deep Work
}
```

## Confidence Thresholds

- **confidence < 3**: Show suggestion, ask for confirmation
- **confidence >= 3**: Auto-apply but show `[learned: Nx]` indicator
- **confidence >= 10**: High confidence, apply silently

## Projects Reference

Current Things projects:
- `5LwYiPJAkWGSCMHML8xaXb` - Out and About
- `7n14Jusf7nCrLADfAANabW` - Kids/Activities
- `EZ5uJWRtcrvJ4U852NkNQ8` - Someday
- `Er67bc9YAur6ZeKTCBLC4c` - Call
- `LDhUsibk3dp2ZPioQySSiu` - Computer
- `NsSR9HR3pd2bVi2z4QHFfM` - Home
- `WamuBi2sFwbUwpXz9NZetP` - Deep Work

## External Tools

SuperThings uses three external MCP tools for research and actions:

### Firecrawl - Quick Research / URL Scraping
**When to use**: URL tasks, single-page reads, video metadata
**MCP Function**: `mcp__firecrawl-mcp__firecrawl_scrape`
**Best for**:
- Scraping URLs from Things tasks
- YouTube video summaries
- GitHub repos, articles, product pages
- Quick single-source lookups

### Tavily - Deep Research
**When to use**: "Research X" tasks, DD (Deep Dive), competitive analysis
**MCP Function**: `mcp__tavily__tavily_search`
**Best for**:
- Multi-source comprehensive research
- Company research, market analysis
- Current events and news
- When you need synthesis from multiple sources

### BrowserBase - Browser Automation
**When to use**: Login-required sites, JavaScript-heavy pages, interactive tasks, screenshots
**MCP Functions**: `mcp__browserbase__*` (navigate, click, type, screenshot, etc.)
**Best for**:
- Tasks requiring authentication/login
- JavaScript-heavy or dynamic pages
- Form filling and submissions
- Taking screenshots for verification
- Social media monitoring
- Complex web apps that don't scrape well

### Zapier Gmail - Email Operations
**When to use**: Email tasks, intro tasks, delegation
**MCP Functions**:
- `mcp__zapier__gmail_send_email` - Send drafted emails
- `mcp__zapier__gmail_create_draft` - Save as draft for review
- `mcp__zapier__gmail_find_email` - Search inbox for context
**Best for**:
- "Email X" tasks
- "Intro X to Y" tasks
- "D [person]" delegation commands
- Finding prior conversation context

### Tool Selection Logic

| Task Type | Tool | Action |
|-----------|------|--------|
| URL in task | Firecrawl | Scrape and summarize |
| "Research X" | Tavily | Deep multi-source search |
| "DD" command | Tavily | Expanded deep research |
| Login-required site | BrowserBase | Navigate, authenticate, interact |
| "Screenshot X" | BrowserBase | Capture visual state |
| Dashboard/analytics | BrowserBase | Navigate and extract data |
| "Email X" | Zapier | Find context → Draft → Send |
| "Intro X to Y" | Zapier | Draft intro email → Send |
| "D [person]" | Zapier | Draft delegation email → Send |

## Research Cache System

GTD research results are cached to `~/claudesync/servers/super-things/data/research-cache.json`:

```json
{
  "last_updated": "ISO-timestamp",
  "sessions": {
    "session-id": {
      "started_at": "ISO-timestamp",
      "tasks_researched": 32,
      "results": [
        {
          "task_id": "Things-UUID",
          "task_title": "Research competitor pricing",
          "researched_at": "ISO-timestamp",
          "findings": "Full research text...",
          "sources": ["url1", "url2"],
          "user_decision": "complete|delegate|deepdive|pending",
          "notes_updated": true
        }
      ]
    }
  }
}
```

### Cache Behavior
- Results persist for 7 days
- Use `/gtd resume` to continue a previous session
- Say "details N" to expand cached findings

### URL Task Handling (Firecrawl)
When a task contains a URL, use `mcp__firecrawl-mcp__firecrawl_scrape`:
1. Scrape the URL to get page content
2. Extract title, description, key content
3. Summarize with TLDR bullets
4. Mark source as "Firecrawl (visited link)"

## GTD Triage Commands

After research display, respond with commands:

| Command | Action | Example |
|---------|--------|---------|
| `C` | Complete task | `1: C` |
| `C [note]` | Complete with note | `1: C already handled` |
| `D [person]` | Delegate via Zapier email | `2: D Brianna` |
| `D [person] [modifier]` | Delegate with context | `2: D Brianna within the next week` |
| `DD` | Deep Dive - more research | `3: DD` |
| `DD [focus]` | Deep Dive with focus | `3: DD focus on enterprise pricing` |

## Commands

This plugin provides these slash commands:
- `/thingsinbox` - Triage inbox with learning-based suggestions
- `/gtd` - Get Things Done workflow with research caching
