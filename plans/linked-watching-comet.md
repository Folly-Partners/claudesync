# Agent-Native Journal App Transformation

## Summary

Transform the journal app from a traditional UI-driven app with read-only AI tools into a full agent-native architecture where the agent can achieve any outcome the user describes.

**Key insight:** The storage layer already has write operations (`savePerson`, `mergePeople`, `saveEntry`). The main work is exposing these as MCP tools and adding a chat interface.

## Current State → Target State

| Aspect | Current | Target |
|--------|---------|--------|
| MCP Tools | 6 read-only | 15+ read/write (full parity) |
| User Interaction | Structured UI only | UI + agent chat |
| Features | Coded in React | Prompts + atomic tools |
| Context | None | Persistent context.json |
| Vercel | ✅ Works | ✅ Still works |

---

## Phase 1: Tool Parity (Expose Write Operations)

Add write tools to `/web/app/api/mcp/tools/`:

### People Tools (storage layer exists)
| Tool | Wraps | Parameters |
|------|-------|------------|
| `journal_update_person` | `savePerson()` | name, photoUrl?, notes?, relationship?, aliases? |
| `journal_delete_person` | `deletePerson()` | name |
| `journal_merge_people` | `mergePeople()` | sourceName, targetName |

### Entry Tools
| Tool | New/Exists | Parameters |
|------|------------|------------|
| `journal_get_entry` | new | date |
| `journal_update_entry` | new | date, section, content, append? |
| `journal_regenerate_entry` | wraps generate API | date, force? |

### Project Tools
| Tool | New/Exists | Parameters |
|------|------------|------------|
| `journal_update_project` | new | name, category?, status?, notes? |
| `journal_create_project` | new | name, category, status? |

### Context Tools (new storage)
| Tool | Purpose | Parameters |
|------|---------|------------|
| `journal_get_context` | Read agent memory | - |
| `journal_update_context` | Update goals/watchlist | goals?, watchlist?, preferences? |

**Files to modify:**
- `/web/app/api/mcp/route.ts` - Register new tools
- `/web/app/api/mcp/tools/index.ts` - Export new tools
- New files: `journal-update-person.ts`, `journal-delete-person.ts`, etc.

---

## Phase 2: Context/State Management

Add persistent agent context to Vercel Blob:

**New file:** `journal/context.json`
```json
{
  "lastUpdated": "2026-01-09T10:00:00Z",
  "activeGoals": ["Close Acme deal by Q1"],
  "watchlist": {
    "people": [{"name": "John Smith", "reason": "weekly check-in"}],
    "projects": [{"name": "Fund III", "reason": "fundraising"}]
  },
  "preferences": {
    "defaultDateRange": 30,
    "verbosity": "medium"
  }
}
```

**Files to create:**
- `/web/lib/context.ts` - Context CRUD operations
- `/web/app/api/mcp/tools/journal-context.ts` - Context tools

---

## Phase 3: Chat Interface

Add agent chat as a slide-over panel (keeps existing UI).

**New route:** `/web/app/api/chat/route.ts`
```typescript
// Streaming chat with tool use
export const runtime = 'edge';
export const maxDuration = 60;

// Uses Anthropic SDK with all MCP tools as Anthropic tools
// Injects context + recent entries into system prompt
```

**New components:**
- `/web/components/ChatPanel.tsx` - Slide-over chat UI
- `/web/components/ChatMessage.tsx` - Message with tool call visibility
- `/web/components/ToolCallBadge.tsx` - Shows what tools were used

**UI integration:**
- Floating chat button in bottom-right
- Opens slide-over panel (doesn't replace calendar/people views)
- Shows tool calls inline with toggle to expand/collapse

---

## Phase 4: Data Structure Enhancements

Enhance entry frontmatter (backward compatible):

```yaml
# Existing fields preserved
date: '2026-01-06'
day_of_week: Tuesday
people: [...]
type: daily_journal

# New optional fields
tags: [conference, networking]
projects:
  - name: Fund III
    category: internal
mood: productive
energy: high
key_topics: [AI automation, portfolio review]
```

**Files to modify:**
- `/web/lib/entries.ts` - Extend `JournalEntry` type
- `/journal/summarizer.py` - Generate new fields during entry creation
- `/web/lib/blob-storage.ts` - Add tags index support

---

## Phase 5: Prompt-Driven Features

These become system prompts + existing tools instead of coded features:

| Feature | Implementation |
|---------|----------------|
| Weekly Review | Prompt: "Summarize my week, highlighting key people, projects, and decisions" |
| Morning Briefing | Prompt: "What's on my plate today based on recent context and goals?" |
| Relationship Insights | Prompt: "How's my relationship with X? Recent interactions and follow-ups?" |
| Pattern Recognition | Prompt: "What patterns do you see in my energy/mood over the past month?" |

---

## Critical Files

| File | Purpose |
|------|---------|
| `/web/app/api/mcp/route.ts` | MCP handler - add new tools here |
| `/web/lib/blob-storage.ts` | Storage layer - already has write ops |
| `/web/lib/entries.ts` | Type definitions - extend for new fields |
| `/web/app/api/generate/route.ts` | Entry generation - enhance output |

---

## Verification

After implementation, test these scenarios:

1. **Tool Parity Test:**
   - "Merge John Smith and J. Smith into one person" → agent uses `journal_merge_people`
   - "Mark Project X as dormant" → agent uses `journal_update_project`

2. **Chat Interface Test:**
   - Open chat panel, ask "Who did I meet last week?"
   - Verify streaming response with tool calls visible

3. **Context Persistence Test:**
   - "Add 'close Acme deal' to my goals"
   - Close browser, reopen chat
   - Ask "What are my goals?" → should include Acme deal

4. **Emergent Capability Test:**
   - "Cross-reference my meetings with investors against my fund goals"
   - Agent should compose search + context tools to answer

---

## Vercel Compatibility

- ✅ All API routes work on Vercel
- ✅ Streaming chat uses Edge runtime (60s max)
- ✅ Blob storage already in use
- ⚠️ Long entry generation may need background function (already 60s limit)

---

## Estimated Scope

- **Phase 1:** ~8 new tool files, modify 2 existing
- **Phase 2:** ~2 new files
- **Phase 3:** ~4 new files (route + components)
- **Phase 4:** ~3 file modifications
- **Phase 5:** System prompt updates only
