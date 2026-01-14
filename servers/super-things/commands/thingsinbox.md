---
model: haiku
---

# Things Inbox Triage

Triage and organize the Things inbox by cleaning up task titles and assigning them to appropriate projects. **Uses learned patterns from your corrections to get better over time.**

## Learning System Integration

**ALWAYS load learned patterns before processing:**

```bash
cat ~/andrews-plugin/servers/super-things/data/patterns.json
```

The patterns file contains:
- `title_transforms`: Regex patterns for rewriting titles (e.g., "Fix X" → "Delegate to Brianna: Fix X")
- `project_hints`: Keyword → project mappings with confidence scores
- `exact_overrides`: Specific title → transformation mappings

**Priority order for suggestions:**
1. `exact_overrides` (exact title match)
2. `title_transforms` (regex pattern match)
3. `project_hints` (keyword-based)
4. Hardcoded defaults (below)

## Model Escalation - Auto-Switch to Sonnet

Runs on Haiku, but **auto-escalates to Sonnet** when hitting speedbumps:

| Haiku (default) | Sonnet (escalate) |
|-----------------|-------------------|
| Fetch/cache tasks | Unclear/cryptic tasks |
| URL resolution | Clarification questions |
| Clear categorization | Judgment calls |
| Bulk updates | "Get stuff done" execution |

**How to escalate:** Use Task tool with `model: sonnet` for complex items.

## Workflow

1. **Fetch inbox** - Call `mcp__SuperThings__things_get_inbox` directly (server handles caching internally with 1-minute TTL)

2. **Process each task**:
   - **URL tasks**: Use Firecrawl/WebFetch to resolve URLs and create descriptive titles
     - YouTube: "Watch: [Video Title] - [Creator]"
     - GitHub: "Review: [Repo Name] - [Description]"
     - Google Maps: "Visit: [Place Name]"
     - Twitter/X: "Read: [Tweet summary]"
     - **IMPORTANT**: When updating a URL title, move the original URL to the notes field
   - **Clear tasks**: Keep title as-is, just categorize
   - **Unclear/cryptic tasks**: Leave title unchanged (don't guess)

3. **Assign projects** using these rules:

   **Default: Computer** - Almost everything goes here if it can be done on computer OR delegated.

   | Pattern | Project |
   |---------|---------|
   | Research, Email, Intro, Follow up, Draft, Buy, Book, Schedule, Review, Check, Order, Send, Create, Find, Watch, Read | Computer (`LDhUsibk3dp2ZPioQySSiu`) |
   | Fix, maintenance, home repairs | Computer - Reformat as "Delegate to Brianna: [task]" |
   | Call [person], Phone call required | Call (`Er67bc9YAur6ZeKTCBLC4c`) |
   | Physical in-person errands only | Out and About (`5LwYiPJAkWGSCMHML8xaXb`) |
   | Kid-specific activities | Kids/Activities (`7n14Jusf7nCrLADfAANabW`) |
   | **Build/Make [software]** - DEFAULT to Deep Work | Deep Work (`WamuBi2sFwbUwpXz9NZetP`) |
   | Long-form writing (1+ hour focused work) | Deep Work (`WamuBi2sFwbUwpXz9NZetP`) |

   **Build/Make → Deep Work Logic** (this is critical):

   Any task starting with "Build" or "Make" that involves creating SOFTWARE goes to **Deep Work**:
   - Apps, plugins, tools, bots, systems, integrations
   - Reviewers, analyzers, dashboards, automations
   - APIs, scrapers, workflows, pipelines
   - Anything that requires writing code for multiple hours

   **EXCEPTIONS** (these stay in Computer):
   - "Build a list of..." → just research/compilation
   - "Build rapport with..." → relationship, not software
   - "Make a reservation..." → booking task
   - "Make an intro..." → email task

   **Rules**:
   - When in doubt → Computer
   - NEVER assign to Someday unless user explicitly asks
   - Fix/maintenance → "Delegate to Brianna: [task]" → Computer
   - Research → Always Computer (never Deep Work)
   - Build/Make software → Deep Work (assume multi-hour unless obviously simple)

4. **Present results** using grouped card format showing before/after:
   ```
   Inbox (44) | C=Computer D=Deep O=Out P=Call

   ┌─ 1 ─────────────────────────────────────────────────── C ✎
   │  https://youtu.be/pE3KKUKXcTM...
   │  ↓
   │  Watch: Semiconductor Industry Works
   ├─ 2 ─────────────────────────────────────────────────── C ✎
   │  Fix fireplace
   │  ↓
   │  Delegate to Brianna: Fix fireplace        [learned: 12x]
   ├─ 3 ─────────────────────────────────────────────────── C
   │  Research competitor pricing
   ├─ 4 ─────────────────────────────────────────────────── P
   │  Call dentist
   ```

   **Format rules:**
   - Card header: `┌─ # ───...─── X ✎` where X is project code, ✎ if title changes
   - Continuation: `├─ # ───...───` for items 2+
   - Line 1 under header: original title (full, can wrap if needed)
   - Line 2 (if edit): `│  ↓` (down arrow separator)
   - Line 3 (if edit): `│  New title`
   - **Learning indicator**: Add `[learned: Nx]` when suggestion comes from patterns.json
   - No arrow/new title if no title change (just moving to project)
   - Project codes: C=Computer, D=Deep, O=Out&About, P=Call, K=Kids
   - Keep divider line ~60 chars wide

5. **Show preview summary** after the cards:
   ```
   ─────────────────────────────────────────────────────────────
   Preview: 12 items
   ├─ 3 title rewrites (✎)
   ├─ 8 project moves
   ├─ 1 delegation
   └─ 2 learned patterns applied

   Reply: numbers (1,3,5-8), "all", "skip N", or "S3" to snooze
   ```

   **Summary categories:**
   - **Title rewrites (✎)**: Count of items where title changes
   - **Project moves**: Items moving to a project (no title change)
   - **Delegations**: Items reformatted as "Delegate to..."
   - **Learned patterns**: Count of suggestions from patterns.json
   - **URLs resolved**: Count of URL tasks with new titles

6. **Wait for user approval**: User replies with:
   - Numbers: `1,3,5-8` - approve specific items
   - `all` - approve everything
   - `skip N` - approve all except item N
   - `S3` or `snooze 3` - snooze item 3 for 1 week (sets `when` to +7 days)
   - `S3 2w` - snooze item 3 for 2 weeks
   - `S3 1m` - snooze item 3 for 1 month

   **Snooze behavior:**
   - Snoozed items are NOT processed in current batch
   - Sets `when` to future date, removes from inbox
   - Item reappears in Today on the scheduled date

7. **Save undo state** BEFORE executing updates:
   ```bash
   # Save pre-triage state for undo capability
   echo '[
     {"id":"ID1","original_title":"ORIG1","original_list":"inbox"},
     {"id":"ID2","original_title":"ORIG2","original_list":"inbox"}
   ]' > ~/andrews-plugin/servers/super-things/data/last_triage.json
   ```

8. **Execute updates** using `mcp__SuperThings__things_update_todo` for approved items

   **For snoozed items**, calculate the date and update:
   ```
   # Snooze for 1 week (default)
   mcp__SuperThings__things_update_todo with:
     id: <item_id>
     when: <date 7 days from now in YYYY-MM-DD format>

   # Snooze durations:
   # 1w = 7 days, 2w = 14 days, 1m = 30 days
   ```

9. **MANDATORY: Log and Learn** - After executing updates, you MUST:

   a) **Append to history.jsonl** - For EACH processed item:
   ```bash
   echo '{"ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","original":"ORIGINAL_TITLE","suggested":"SUGGESTED_TITLE","final":"FINAL_TITLE","project":"PROJECT_NAME","accepted":true}' >> ~/andrews-plugin/servers/super-things/data/history.jsonl
   ```

   b) **Update patterns.json** if user made corrections:
   - Read current: `cat ~/andrews-plugin/servers/super-things/data/patterns.json`
   - If title was changed differently than suggested, add to `exact_overrides`
   - If pattern emerges (e.g., "Fix X" → "Delegate: Fix X"), add to `title_transforms`
   - Write updated JSON back to file

   **Example pattern to learn:**
   If user changed "Fix garage" → "Delegate to Brianna: Fix garage", add:
   ```json
   {"title_transforms": [{"match": "^Fix ", "replace": "Delegate to Brianna: Fix ", "confidence": 1}]}
   ```

   **Skip learning only if:** User explicitly cancels or no items were processed

## URL Resolution (Firecrawl)

For URL tasks, use **Firecrawl** to fetch and summarize content:

**Tool**: `mcp__firecrawl-mcp__firecrawl_scrape`

Launch parallel agents (using haiku model) to resolve URLs:
1. Scrape URL with `mcp__firecrawl-mcp__firecrawl_scrape`
2. Extract title, description, and key content
3. Create actionable task title based on content type:
   - YouTube: "Watch: [Video Title] - [Creator]"
   - GitHub: "Review: [Repo Name] - [Description]"
   - Article: "Read: [Article Title]"
   - Product: "Check out: [Product Name]"
4. Move original URL to notes field

## Project IDs Reference
- Computer: `LDhUsibk3dp2ZPioQySSiu`
- Deep Work: `WamuBi2sFwbUwpXz9NZetP`
- Call: `Er67bc9YAur6ZeKTCBLC4c`
- Home: `NsSR9HR3pd2bVi2z4QHFfM`
- Out and About: `5LwYiPJAkWGSCMHML8xaXb`
- Kids/Activities: `7n14Jusf7nCrLADfAANabW`
- Someday: `EZ5uJWRtcrvJ4U852NkNQ8`

## Learning System Details

The learning happens in Step 7 above. Here's how patterns work:

### Pattern Types

**1. exact_overrides** - Exact title → new title mappings
```json
{"exact_overrides": {"Fix fireplace": "Delegate to Brianna: Fix fireplace"}}
```

**2. title_transforms** - Regex-based transformations
```json
{"title_transforms": [
  {"match": "^Fix ", "replace": "Delegate to Brianna: Fix ", "confidence": 5}
]}
```

**3. project_hints** - Keyword → project mappings
```json
{"project_hints": {"dentist": {"project": "Call", "count": 3}}}
```

### Confidence Scoring

- New pattern starts at confidence=1
- Each time pattern is used and accepted: confidence++
- Patterns with confidence >= 3 show `[learned: Nx]`
- Higher confidence = higher priority when multiple patterns match

### Reading History

To see past decisions: `cat ~/andrews-plugin/servers/super-things/data/history.jsonl | tail -20`

## Undo Last Triage

If user says "undo" or "revert", restore the last triage batch:

1. **Read last_triage.json**:
   ```bash
   cat ~/andrews-plugin/servers/super-things/data/last_triage.json
   ```

2. **For each item**, restore original state:
   ```
   mcp__SuperThings__things_update_todo with:
     id: <item_id>
     title: <original_title>
     list: "inbox"  # Move back to inbox
   ```

3. **Confirm to user**: "Reverted N items to their original state"

4. **Clear the undo file** after successful revert:
   ```bash
   echo '[]' > ~/andrews-plugin/servers/super-things/data/last_triage.json
   ```

**Note:** Only the LAST triage batch can be undone. Running a new triage overwrites the undo state.

## Execution

Now execute the triage workflow:
1. **Load patterns first** - Read `~/andrews-plugin/servers/super-things/data/patterns.json`
2. **Fetch inbox** - Call `mcp__SuperThings__things_get_inbox` (server handles caching)
3. Apply learned patterns when generating suggestions
4. Show `[learned: Nx]` for pattern-based suggestions
5. Save undo state before executing
6. After user confirms, log to history.jsonl and update patterns.json
7. Keep responses concise to save context
8. Launch parallel haiku agents for URL resolution
