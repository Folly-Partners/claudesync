---
name: texts
description: Processes Beeper text message inbox with AI-generated draft responses. Use when the user says "texts", "process messages", "inbox", or wants to respond to iMessage/WhatsApp messages.
model: sonnet
allowed-tools: Read, Bash, Task, AskUserQuestion, MCPSearch, mcp__beeper__*
---

# Batch Texts Inbox Processing

Andrew's phone: +12508845375

**THE RULE: Collect ALL selections, then execute in batch. No sends until batch confirmation.**

## Phase 1: Prep

### Step 1: Fetch Inbox

**PARALLEL:** Call both together:
- `mcp__beeper__search_messages` (sender: "others", limit: 20, chatType: "single")
- `mcp__beeper__search_messages` (sender: "others", limit: 20, chatType: "group")

### Step 2: Filter (Relaxed)

**Only skip if:**
- Last message is ONLY a reaction/emoji with no text (👍, ❤️, 😂 alone)

**KEEP even if:**
- Andrew sent last (may want to follow up or archive)

**Dedupe:** By chatID if same chat appears in both results.

### Step 3: Get Details

**PARALLEL:** Call ALL together:
- `~/.claude/scripts/contacts/search_by_phones_batch.sh "+1xxx" "+1yyy"...`
- `mcp__beeper__list_messages` for each chat (all in same message)

### Step 4: Generate Drafts

**PARALLEL:** Launch ALL Haiku tasks in ONE message:

```
Task (model: "haiku", subagent_type: "general-purpose", prompt: "...")
Task (model: "haiku", subagent_type: "general-purpose", prompt: "...")
```

**Haiku prompt:**
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

Skip options that don't fit the context.
```

### Step 5: Prepare Displays

For each chat, have ready:
- Display text (name, platform, context)
- Question: "Response for {Name}?"
- Options: 4 drafts + "Archive" + "Skip"

### Step 6: Announce

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BATCH READY - {N} chats
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 2: Rapid-Fire

**ZERO COMPUTATION. Store selections only. NO SENDS YET.**

For each chat, print with running total:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[{current}/{total}] {Name} ({Platform})     📤 {queued} queued
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{Last 2-3 messages as context}
```

AskUserQuestion: "Response for {Name}?"
Options:
1. "{draft1}"
2. "{draft2}"
3. "{draft3}"
4. "{draft4}"
5. "Archive (no reply)"
6. "Skip (leave in inbox)"

- Draft selected → store (chatID, message)
- Archive selected → store (chatID, archive-only)
- Skip selected → store nothing, move on
- Custom → prompt for text, store (chatID, custom-message)

**DO NOT EXECUTE ANYTHING. Just record and move to next.**

### End of Rapid-Fire: Batch Confirmation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TRIAGE COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Replies queued: {X}
• Archive only: {Y}
• Skipped: {Z}
```

AskUserQuestion: "Execute all {X+Y} actions?"
- "Yes, send and archive"
- "Review list first"
- "Cancel (discard all)"

If "Review list first":
```
QUEUED ACTIONS:
1. Mom → Send: "Sounds great, see you Sunday!"
2. John S. → Archive (no reply)
3. Work Group → Send: "Thanks for the heads up"
...
```
Then re-ask execute confirmation.

---

## Phase 3: Execute

**Only after user confirms "Yes, send and archive"**

**PARALLEL:** Send all messages together:
```
mcp__beeper__send_message for each reply selection
```

**PARALLEL:** Archive all chats together (including send + archive-only, NOT skipped):
```
mcp__beeper__archive_chat for each non-skipped chat
```

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BATCH COMPLETE
Sent: {X} | Archived: {Y} | Skipped: {Z}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

More in inbox? Ask to fetch another batch.

---

## Notes

**Beeper quirks:** `search_chats` returns empty (don't use), `search_messages` limit capped at 20, 404 errors happen (retry).

**Interruptions:** Don't enter plan mode. Ask: "Execute {X} queued, or discard?"

**Errors:** Beeper down → stop. Send fails → note it, don't archive that chat, show in summary.

---

## Voice Examples

Good: "Sounds great!" / "Let me check." / "Thanks!"
Avoid: "That sounds great to me!" / "I'll definitely look into that for you!"

---

Start by fetching inbox.
