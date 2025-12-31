# Things MCP Enhancement Plan

## Overview
Three deliverables:
1. **Fork Things MCP** - Fix focus-stealing by replacing URL schemes with AppleScript
2. **/thingsinbox** - Clean up inbox titles + suggest project assignments
3. **/gtd** - Find actionable tasks in Computer/Deep Work, do research in background

---

## Part 1: Fork Things MCP (Silent Mode)

### Problem
Write operations use URL schemes (`things:///add?...`) which activate Things and steal focus.

### Solution
Replace URL scheme calls with AppleScript. Things' AppleScript interface works without activating the app.

### Files to Modify
```
hildersantos/things-mcp/
├── src/tools/add.ts           # things_add_todo, things_add_project
├── src/tools/update-json.ts   # things_update_*, things_add_items_to_project
├── src/tools/show.ts          # things_show (navigation)
└── src/lib/urlscheme.ts       # Remove or refactor
```

### New AppleScript Files
```
src/scripts/
├── create-todo.applescript
├── create-project.applescript
├── update-todo.applescript
├── update-project.applescript
└── add-items-to-project.applescript
```

### AppleScript Example (Silent Create)
```applescript
tell application "Things3"
    set newToDo to make new to do ¬
        with properties {name:"Task title", notes:"Notes here"}
    move newToDo to list "Inbox"
end tell
```

### Hosting
- Fork to Andrew's GitHub: `awilkinson/things-mcp-silent`
- Update `claude_desktop_config.json` to point to fork

---

## Part 2: /thingsinbox Command

### Location
`~/.claude/commands/thingsinbox.md`

### Workflow
1. Fetch inbox via `things_get_inbox`
2. For each task:
   - **URL tasks**: Fetch URL with Firecrawl/WebFetch, extract title + summarize content
   - **Clear tasks**: Categorize and suggest project
   - **Unclear/cryptic tasks**: Leave title unchanged, still suggest project if possible
3. Apply project assignment rules
4. Present table of suggestions
5. On confirmation, batch update via `things_update_todo`

### Title Cleanup Rules
| Input Pattern | Output |
|---------------|--------|
| `https://youtu.be/xyz` | "Watch: [Video Title] - [Creator]" |
| `https://github.com/...` | "Review: [Repo Name] - [Description]" |
| `https://maps.app.goo.gl/...` | "Visit: [Place Name]" |
| `https://x.com/...` or Twitter | "Read: [Tweet summary]" |
| Clear actionable text | Keep as-is |
| **Unclear/ambiguous** | **Leave unchanged** (don't guess) |

### Project Assignment Rules

**Default: 💻 Computer** - Almost everything goes here. If a task can be done on a computer OR delegated, it's Computer.

| Task Pattern | Project |
|--------------|---------|
| **💻 Computer (DEFAULT)** | Research, Build, Email, Intro, Follow up, Draft, Buy, Book, Schedule, Review, Check, Order, Delegate, Send, Create, Find, Watch, Read, Fix (delegated) |
| ☎️ Call | ONLY if phone call explicitly required |
| 🚗 Out and About | ONLY physical in-person errands |
| 👦 Kids/Activities | ONLY kid-specific activities |
| ⏳ Deep Work | Computer tasks requiring 1+ hour of focused time (writing, building, creative) |

**Rules**:
- When in doubt → 💻 Computer
- **NEVER assign to 🕒 Someday** unless user explicitly asks
- **Fix/maintenance tasks** → Reformat as "Delegate to Brianna: [original task]" and assign to 💻 Computer
- **Research tasks** → Always 💻 Computer (never Deep Work)

### Delegation Formatting
Any task involving home fixes, maintenance, scheduling appointments, or admin work:
- Original: "Fix fireplace in library"
- Reformatted: "Delegate to Brianna: Fix fireplace in library"
- Project: 💻 Computer

### Output Format
```
Inbox Triage (44 items)

| # | Current | Suggested Title | Project | Action |
|---|---------|-----------------|---------|--------|
| 1 | https://youtu.be/pE3K... | Watch: Naval on AI startups | 💻 Computer | Update |
| 2 | Jennifer Crane - Karen | Call Jennifer Crane re: Karen from Purdys | ☎️ Call | Update |
| 3 | Research Creatine Use | [Good as-is] | ⏳ Deep Work | Move only |

Reply with numbers to approve (e.g., "1,2,5-10,all")
```

---

## Part 3: /gtd Command

### Location
`~/.claude/commands/gtd.md`

### Workflow
1. Fetch tasks from:
   - 💻 Computer (`LDhUsibk3dp2ZPioQySSiu`)
   - ⏳ Deep Work (`WamuBi2sFwbUwpXz9NZetP`)
2. Categorize by Claude-helpability:
   - **Research**: Pattern `Research X`, `Find X`, `Look up X`
   - **Writing**: Pattern `Draft X`, `Write X`, `Finish X blog post`
   - **Email**: Pattern `Email X`, `Send X email`, `Reply to X`
   - **Intro**: Pattern `Intro X to Y`, `Connect X with Y`
   - **Not helpable**: Physical tasks, calls, meetings

3. Present summary:
```
GTD Review: 45 tasks in Computer + Deep Work

Research Tasks (12) - can research now
Email Tasks (8) - can draft + send via Zapier
Intro Tasks (5) - can draft intro emails
Writing Tasks (3) - can help draft

Ready to work. Which category? (research/email/intro/all)
```

4. **Launch MAX parallel agents** (all at once, not batched):
   - Research: Each uses Firecrawl/Tavily/WebSearch
   - Emails: Draft using context from task
   - Intros: Draft intro email connecting the people mentioned
   - All agents run simultaneously

5. For completed work:
   - **Research**: Show findings → Save to Things notes → Ask to mark complete
   - **Emails/Intros**: Show draft → Confirm/Edit → Send via Zapier MCP → Mark complete

### Email/Intro Task Workflow

**Example: "Intro Shiraz to Greg Burberry via email"**

1. Parse task to extract names: Shiraz, Greg Burberry
2. **Search Gmail via Zapier** for each person:
   - "Shiraz" → Find who they are, company, relationship context
   - "Greg Burberry" → Find who they are, why Andrew knows them
3. Use Gmail context to draft informed intro email:
```
Subject: Introduction: Shiraz <> Greg Burberry

Hi Greg,

I wanted to introduce you to Shiraz [context from any notes/prior knowledge].

[Shiraz], meet Greg Burberry [context].

I'll let you two take it from here.

Best,
Andrew
```
3. Present draft: "Here's the intro email. Send/Edit/Skip?"
4. On "Send": Use Zapier MCP `gmail_send_email` action
5. On success: Mark Things task complete via `things_update_todo`

### Zapier MCP Integration

Tools to use:
- `mcp__zapier__gmail_send_email` - Send drafted emails
- `mcp__zapier__gmail_create_draft` - Save as draft if user wants to review in Gmail first

Email context gathering:
- Check if names mentioned have associated emails in prior context
- If not, ask user for email addresses before sending

### Research Tool Strategy

**Use Tavily first** (optimized for AI search):
- Fast, clean results for open-ended research queries
- Use for: "Research X", "Find out about X", "What is X"

**Use Firecrawl second** (deep scraping):
- When Tavily finds a relevant page that needs full content extraction
- When you need structured data from specific URLs
- Agent mode for complex multi-page research

**Workflow**:
1. Tavily search → get top results
2. If more depth needed → Firecrawl scrape specific URLs
3. Synthesize findings

### Gmail Context for Person-Related Tasks

**For Intro/Email/Person tasks**, search Gmail via Zapier before drafting:

```
Task: "Intro Shiraz to Greg Burberry"

1. Search Gmail for "Shiraz" → get context on who Shiraz is
2. Search Gmail for "Greg Burberry" → get context on Greg
3. Use context to write informed intro email
```

**Zapier Gmail Search Tool**: `mcp__zapier__gmail_search`
- Search query: person's name
- Extract: relationship context, prior conversations, company/role

### Research Agent Template
```markdown
Research task: "{task_name}"

1. Tavily search for current information on topic
2. If top result looks comprehensive, Firecrawl scrape for full content
3. Synthesize into actionable summary

Return:
- Key findings (3-5 bullets)
- Relevant links with brief descriptions
- Recommended next action
- Estimated time to complete (if applicable)
```

---

## Implementation Order

1. **Fork Things MCP** (enables silent operations)
   - Clone repo
   - Write AppleScript files
   - Modify TypeScript handlers
   - Test locally
   - Push to GitHub

2. **/thingsinbox command**
   - Create command file
   - Implement URL resolution logic
   - Implement project assignment rules
   - Test with real inbox

3. **/gtd command**
   - Create command file
   - Implement task categorization
   - Implement parallel research agents
   - Implement Things notes update
   - Test with real projects

---

## Files to Create/Modify

### New Files
- `~/Projects/things-mcp-silent/` (forked repo)
- `~/.claude/commands/thingsinbox.md`
- `~/.claude/commands/gtd.md`

### Modified Files
- `~/Library/Application Support/Claude/claude_desktop_config.json` (point to fork)
- `~/.claude/settings.local.json` (add new tool permissions)
