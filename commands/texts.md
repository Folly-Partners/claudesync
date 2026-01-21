---
name: texts
description: Processes Beeper text message inbox with AI-generated draft responses. Use when the user says "texts", "process messages", "inbox", or wants to respond to iMessage/WhatsApp messages.
model: sonnet
allowed-tools: Read, Bash, Task, AskUserQuestion, MCPSearch, mcp__beeper__*
---

# Rapid-Fire Texts Inbox Processing

Andrew's phone: +12508845375

**THE RULE: All computation in Phase 1. Phase 2 is pure ask-record-loop with embedded context. No sends until batch confirmation.**

## Phases

1. **Prep** - Fetch, resolve, generate, prepare (ALL work)
2. **Rapid-fire** - AskUserQuestion with embedded context, record, next (NO computation)
3. **Execute** - Batch send and archive (only after confirmation)

---

## Phase 1: Prep

### Step 0: Load Beeper Tools

Load the required MCP tools (they are deferred):
```
MCPSearch (query: "select:mcp__beeper__search_messages")
MCPSearch (query: "select:mcp__beeper__list_messages")
MCPSearch (query: "select:mcp__beeper__send_message")
MCPSearch (query: "select:mcp__beeper__archive_chat")
```

### Step 1: Fetch Inbox

**PARALLEL:** Call both together:
- `mcp__beeper__search_messages` (limit: 50, chatType: "single", excludeLowPriority: true)
- `mcp__beeper__search_messages` (limit: 50, chatType: "group", excludeLowPriority: true)

**CRITICAL: Do NOT use `sender: "others"`.** Include all recent messages regardless of who sent last. The API returns individual messages, not conversations—we need to over-fetch to get enough unique chats.

### Step 2: Dedupe, Filter, and Cap

1. **Combine** results from both calls
2. **Dedupe by chatID** - Keep only the most recent message per unique chatID
3. **Filter** - Only skip if last message is ONLY a reaction/emoji with no text (👍, ❤️, 😂 alone)
4. **Sort** - By timestamp, most recent first
5. **Cap at 10** - Take first 10 unique chats (cognitive load optimal: 4-8 items)

**KEEP even if:**
- Andrew sent last (may want to follow up or archive)

**Target: 8-10 unique conversations per batch.**

If fewer than 1 chat after filtering:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
INBOX CLEAR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
No conversations need attention.
```
Then stop—do not proceed to Phase 2.

### Step 3: Get Details

**PARALLEL:** Call ALL together:
- `~/.claude/scripts/contacts/search_by_phones_batch.sh "+1xxx" "+1yyy"...`
- `mcp__beeper__list_messages` for each chat (all in same message)

If `list_messages` returns empty for a chat, mark that chat with `messages: []` and display as "(no recent messages)" in Phase 2.

### Step 4: Generate Drafts

**PARALLEL:** Launch ALL Haiku tasks in ONE message (30 second timeout each):

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

2 options:
1. Quick (1-5 words) - e.g., "Sounds great!", "Thanks!", "On it"
2. Full (1-2 sentences) - a more complete response

Return ONLY the two drafts, one per line. No labels, no explanations.
```

**If Haiku times out (>30s):** Use fallback drafts:
- Quick: "Thanks!"
- Full: "Let me get back to you on this."

### Step 5: Prepare Display Data

For each chat, prepare these fields:
- `contactName`: From contacts lookup, or formatted phone (+1 250 884-5375)
- `platform`: iMessage, WhatsApp, Signal, SMS
- `isGroup`: boolean
- `participantCount`: number (for groups)
- `messages`: Last 3-5 messages, each with:
  - `sender`: Contact name, phone, or "You" for Andrew's messages
  - `text`: Message body (truncate to 120 chars if longer)
  - `hasMedia`: If attachment, format as `[Image]`, `[Video]`, `[File]`, `[Link]`
- `drafts`: Array of 2 generated responses (Quick and Full)

### Step 6: Announce

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BATCH READY - {N} chats
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 2: Rapid-Fire

**ZERO COMPUTATION. All context is PRE-GENERATED and EMBEDDED in AskUserQuestion.**

---

### CRITICAL: Message Display Requirements

**The question field MUST include the conversation messages.**

DO NOT simplify to "Response for {name}?" - this is **WRONG** and defeats the purpose. The user cannot make a decision without seeing what the other person said.

**WRONG (never do this):**
```
Response for John Smith?
```

**CORRECT (always do this):**
```
**[1/10] John Smith** (iMessage)

John: "Hey, want to grab dinner tonight?"
John: "I was thinking that new Thai place"

Response?
```

---

### Required Question Format

For each chat, call AskUserQuestion with this **EXACT** format:

```javascript
AskUserQuestion({
  questions: [{
    question: `**[${current}/${total}] ${contactName}** (${platform}${isGroup ? ` - ${participantCount} people` : ''})

${formatMessages(messages)}

Response?`,
    header: `${queuedCount}q`,
    multiSelect: false,
    options: [
      { label: "Quick", description: truncate(quickDraft, 80) },
      { label: "Full", description: truncate(fullDraft, 80) },
      { label: "Archive", description: "No reply, mark done" },
      { label: "Skip", description: "Leave in inbox" }
    ]
  }]
})
```

### Message Formatting Instructions

Build the message display by following these steps exactly:

1. Take the last 3 messages from the `messages` array
2. If there were more than 3 messages total, prepend `... ({N} earlier)\n` where N is the count of earlier messages
3. For each message to display:
   - If the message has media (`hasMedia`), use that value (e.g., `[Image]`)
   - Otherwise, use the text content (truncate to 120 chars if longer)
   - Format as: `{sender}: "{content}"\n`
4. Combine all lines, trim trailing whitespace

**Example transformation:**

Input messages array (5 messages):
```
[msg1, msg2, msg3, msg4, msg5]  // msg5 is most recent
```

Output string:
```
... (2 earlier)
Sarah: "Where should we go?"
Mike: "How about Thai?"
Sarah: "1pm?"
```

### Format Examples

**Single DM:**
```
**[1/10] John Smith** (iMessage)

John: "Hey, want to grab dinner tonight?"
John: "I was thinking that new Thai place"

Response?
```

**Group chat:**
```
**[3/10] Team Lunch** (WhatsApp - 4 people)

Sarah: "Where should we go?"
Mike: "How about Thai?"
Sarah: "1pm?"

Response?
```

**With media:**
```
**[5/10] Sarah** (iMessage)

Sarah: "[Image]"
Sarah: "What do you think of this design?"

Response?
```

**Long thread:**
```
**[7/10] Project Chat** (Slack - 6 people)

... (4 earlier)
Alex: "We need to decide on the database schema..."
You: "I'm leaning toward Postgres for the relatio..."
Alex: "What about the scaling concerns?"

Response?
```

**Unknown contact:**
```
**[8/10] +1 415 555-0123** (SMS)

+1 415 555-0123: "Hi, this is Mike from the conference..."

Response?
```

**Empty messages (rare edge case):**
```
**[9/10] Jane Doe** (iMessage)

(no recent messages)

Response?
```

---

### Recording Selections

- **Quick or Full** → store `{ chatID, action: "send", message: selectedDraft }`
- **Archive** → store `{ chatID, action: "archive_only" }`
- **Skip** → don't record, move to next
- **Other (custom)** → ask for message text, store `{ chatID, action: "send", message: customText }`

**State structure (in-memory):**
```javascript
queued_actions = [
  { chatID: "abc123", action: "send", message: "Sounds great!" },
  { chatID: "def456", action: "archive_only" },
  // skip actions are NOT stored
]
```

**DO NOT EXECUTE ANYTHING. Just record and move to next.**

---

### Checkpoint Every 5 Chats

After processing chat 5 (and 10, 15, etc.), show a checkpoint:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CHECKPOINT - {processed}/{total}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Replies queued: {X}
Archives queued: {Y}
```

Then AskUserQuestion:
- "Continue" - proceed with next 5
- "Execute now" - go to batch confirmation
- "Stop" - discard all and exit

---

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
- "Cancel (discard all)"

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

## Error Handling

| Error | Action |
|-------|--------|
| Beeper 404 | Retry once after 1 second, then skip chat |
| Beeper 429 (rate limit) | Wait 60 seconds, retry |
| Beeper down/5xx | Stop workflow, report to user |
| Send fails | Note failure, don't archive that chat, show in summary |
| Haiku timeout (>30s) | Use fallback drafts: "Thanks!" and "Let me get back to you on this." |
| No contact found | Use phone number as display name |
| Empty messages | Show "(no recent messages)" in question |

**Beeper quirks:** `search_chats` returns empty (don't use), `search_messages` returns individual messages (over-fetch and dedupe).

**Interruptions:** Don't enter plan mode. Ask: "Execute {X} queued, or discard?"

---

## Voice Examples

Good: "Sounds great!" / "Let me check." / "Thanks!" / "On my way"
Avoid: "That sounds great to me!" / "I'll definitely look into that for you!"

---

Start by fetching inbox.
