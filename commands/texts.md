---
name: texts
description: Processes Beeper text message inbox with AI-generated draft responses. Use when the user says "texts", "process messages", "inbox", or wants to respond to iMessage/WhatsApp messages.
model: sonnet
allowed-tools: Read, Bash, Task, AskUserQuestion, MCPSearch, mcp__beeper__*
---

# Rapid-Fire Texts Inbox Processing

Andrew's phone: +12508845375

**THE ONE RULE: All computation in Phase 1. Phase 2 is pure print-ask-record-loop.**

## Phases

1. **Prep** - Fetch, resolve, generate, prepare (ALL work)
2. **Rapid-fire** - Print, ask, record, next (NO computation)
3. **Execute** - Batch send and archive

---

## Phase 1: Prep

### Step 1: Fetch Inbox

**PARALLEL:** Call both together:
- `mcp__beeper__search_messages` (sender: "others", limit: 20, chatType: "single")
- `mcp__beeper__search_messages` (sender: "others", limit: 20, chatType: "group")

### Step 2: Get Details

**PARALLEL:** Call ALL together:
- `~/.claude/scripts/contacts/search_by_phones_batch.sh "+1xxx" "+1yyy"...`
- `mcp__beeper__list_messages` for each chat (all in same message)

### Step 3: Filter

Skip if:
- Andrew sent last with no reply
- Last message is just a reaction/like

### Step 4: Generate Drafts

**PARALLEL:** Launch ALL Haiku tasks in ONE message:

```
Task (model: "haiku", subagent_type: "general-purpose", prompt: "...")
Task (model: "haiku", subagent_type: "general-purpose", prompt: "...")
```

**Haiku prompt (keep short):**
```
Draft text replies for Andrew. Voice: warm, proper grammar, concise.

SENDER: {name}
CONTEXT:
{last 3-5 messages}

4 options (shortest to longest):
1. Quick (1-5 words)
2. Brief (1 sentence)
3. Standard (1-2 sentences)
4. Engaged (2-3 sentences)

Skip options that don't fit.
```

### Step 5: Prepare Displays

For each chat, have ready:
- Display text (name, platform, context)
- Question: "Response for {Name}?"
- Options: 4 drafts + "Archive"

### Step 6: Announce

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BATCH READY - {N} chats
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 2: Rapid-Fire

**ZERO COMPUTATION. Just loop:**

1. Print prepared display
2. AskUserQuestion with prepared options
3. Record selection
4. Next chat immediately

Custom → ask for message, record it.
Archive → record as no-send.

---

## Phase 3: Execute

**PARALLEL:** Send all messages together:
```
mcp__beeper__send_message for each selection
```

**PARALLEL:** Archive all chats together:
```
mcp__beeper__archive_chat for each chat
```

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BATCH COMPLETE
Sent: {X} | Archived: {Y}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

More chats? Ask to continue.

---

## Notes

**Beeper quirks:** `search_chats` returns empty (don't use), `search_messages` max 20, 404 errors happen (retry).

**Interruptions:** Don't enter plan mode. Ask: "Send {X} selected, or discard?"

**Errors:** Beeper down → stop. Send fails → note it, don't archive that chat. No contact → use phone number.

---

## Voice Examples

Good: "Sounds great!" / "Let me check." / "Thanks!"
Avoid: "That sounds great to me!" / "I'll definitely look into that for you!" / "Thank you so much!"

---

Start by fetching inbox.
