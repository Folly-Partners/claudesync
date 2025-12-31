# SuperThings - Context Management & Public Release Plan

## Part 1: Research Results Context Management

### Current Problem
GTD research results are ephemeral - when Claude researches 30+ tasks, results are displayed once then lost. This wastes tokens if user needs to reference them later.

### Solution: Research Cache System

Add `data/research-cache.json` to store research results:

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
          "recommended_action": "...",
          "user_decision": "complete|keep|skip|pending",
          "notes_updated": true
        }
      ]
    }
  }
}
```

### Context Management Strategy

**During Research:**
1. Before launching research agents, create session entry in cache
2. Each agent writes results directly to cache as they complete
3. Display summarized findings (not full text) to user
4. User can say "show full details for #3" to load from cache

**Batched Display (TLDR bullets, as many as needed):**
```
Research Complete: 32 tasks processed

┌─ 1 ─────────────────────────────────────────────────────────
│  Research competitor pricing
│
│  • Found 5 direct competitors: Acme ($15/mo), Beta ($25/mo),
│    Gamma ($10/mo), Delta ($50/mo), Echo (freemium)
│  • Most offer annual discounts (15-25% off)
│  • Acme and Beta have enterprise tiers ($100+/seat)
│  • Key differentiator: Gamma is only one with API access at base tier
│  • Sources: G2, Capterra, competitor pricing pages
│
├─ 2 ─────────────────────────────────────────────────────────
│  https://youtu.be/abc123 (AI trends video)
│
│  • 45-min talk by Sam Altman on GPT-5 roadmap
│  • Key points: multimodal by default, 10x context window
│  • Prediction: AGI capabilities within 2 years
│  • Discusses compute scaling laws plateau concerns
│  • Source: YouTube (visited link, summarized content)
│
├─ 3 ─────────────────────────────────────────────────────────
│  Market size for productivity tools
│
│  • Global market: $4.2B (2024), projected $8.1B by 2028
│  • CAGR: 15.2%
│  • Fastest growing segment: AI-powered automation (32% CAGR)
│  • North America leads (42% market share)
│  • Sources: Statista, Grand View Research
```

**Triage Commands:**

| Command | Action | Example |
|---------|--------|---------|
| `C` | Complete task | `1: C` |
| `C [note]` | Complete with note | `1: C already done last week` |
| `D [person]` | Delegate - draft email via Zapier | `2: D Brianna` |
| `D [person] [modifier]` | Delegate with context | `2: D Brianna within the next week` |
| `DD` | Deep Dive - get more details | `3: DD` |
| `DD [focus]` | Deep Dive with specific focus | `3: DD focus on enterprise pricing` |

**Example triage response:**
```
1: C
2: D Brianna please handle by Friday
3: DD focus on North American competitors only
4-6: C
7: D John can you review this contract
```

**URL/Link Handling:**
- If task contains a URL, research agent MUST visit the link first
- Summarize actual content from the page (not just title)
- Include key points, takeaways, and why it was saved
- Mark source as "visited link" vs "web search"

**After Session:**
- Cache persists for 7 days (configurable)
- User can run `/gtd resume` to continue previous session
- Notes updates reference cache instead of regenerating

### Files to Modify

| File | Change |
|------|--------|
| `data/research-cache.json` | Create (new) |
| `commands/gtd.md` | Add cache read/write, summarized display, "details" command |
| `SKILL.md` | Document research caching |

---

## Part 2: Current Feature Summary

### MCP Server (19 tools)

| Category | Tools |
|----------|-------|
| **Read** | get_inbox, get_today, get_upcoming, get_anytime, get_someday, get_logbook, get_trash, get_projects, get_areas, get_tags, get_project, get_area, get_list, get_todo_details |
| **Create** | add_todo (with checklists), add_project (with headings) |
| **Update** | update_todo, update_project, add_items_to_project |
| **Navigate** | show |

### Claude Commands

| Command | Description |
|---------|-------------|
| `/thingsinbox` | Inbox triage with URL resolution, project assignment, learning system |
| `/gtd` | Research/email/intro task execution with batched agents |

### Learning System

| Component | Purpose |
|-----------|---------|
| `patterns.json` | Title transforms, project hints, exact overrides |
| `history.jsonl` | Correction log for pattern updates |
| Confidence scoring | Auto-apply at high confidence |

### Caching

| Cache | Location | Purpose |
|-------|----------|---------|
| Inbox cache | `~/.claude/cache/things-inbox.json` | Avoid re-fetching inbox |
| Research cache | `data/research-cache.json` | **NEW** - Store research results |

---

## Part 3: Public Release Checklist

### Must Have (blocks release)

| Item | Status | Action |
|------|--------|--------|
| LICENSE | Missing | Add MIT license (matches original fork) |
| Clear fork attribution | Partial | Add "Forked from hildersantos/things-mcp" to README |
| Installation guide | Exists | Expand with troubleshooting |
| Auth token setup | Exists | Add screenshots |

### Should Have (quality)

| Item | Status | Action |
|------|--------|--------|
| CHANGELOG.md | Missing | Document v2.0 changes from original |
| CONTRIBUTING.md | Missing | Add contribution guidelines |
| Example workflows | Missing | Add real-world usage examples |
| Video demo | Missing | Record setup + usage walkthrough |

### Nice to Have (polish)

| Item | Status | Action |
|------|--------|--------|
| SECURITY.md | Missing | Add security disclosure process |
| Formal API docs | Partial | Generate from Zod schemas |
| Integration tests | Minimal | Add E2E test suite |
| npm publish | Not done | Publish to npm registry |

---

## Part 4: Implementation Steps

### Phase 1: Research Context Management
1. Create `data/research-cache.json` with empty structure
2. Update `commands/gtd.md`:
   - Add session creation at start
   - Write results to cache during research
   - **URL handling**: If task has URL, visit and summarize actual content
   - **Rich display**: TLDR bullets with as many points as needed
   - **C/D/DD commands**: Complete, Delegate (via Zapier email), Deep Dive
   - **Modifiers**: Support added context like "D Brianna within the next week"
   - Add "resume" capability for continuing sessions
3. Add cache cleanup (7-day retention)
4. Integrate Zapier MCP for delegation emails

### Phase 2: Documentation for Public Release
1. Add LICENSE (MIT)
2. Create CHANGELOG.md with v2.0 highlights
3. Update README.md:
   - Clear fork attribution at top
   - Better installation steps
   - Add screenshots for auth token
4. Add example workflows section

### Phase 3: Optional Polish
1. CONTRIBUTING.md
2. SECURITY.md
3. npm publish preparation

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `data/research-cache.json` | Create |
| `commands/gtd.md` | Add caching + summarized display |
| `SKILL.md` | Document research caching |
| `LICENSE` | Create (MIT) |
| `CHANGELOG.md` | Create |
| `README.md` | Update with fork attribution + better install |
