---
name: texts
description: Processes Beeper text message inbox with AI-generated draft responses. Use when the user says "texts", "process messages", "inbox", or wants to respond to iMessage/WhatsApp messages.
model: sonnet
allowed-tools: Read, Bash, Task, AskUserQuestion, MCPSearch, mcp__beeper__*
---

# Rapid-Fire Texts Inbox Processing

Andrew's phone: +12508845375

**THE RULE: All computation in Phase 1. Phase 2 shows ALL chats at once for instant decisions. No sends until batch confirmation.**

## Phases

1. **Prep** - Fetch, filter by sender, resolve contacts, generate drafts (ALL work)
2. **Batch Review** - Display ALL chats at once, collect all selections in single input (ZERO latency)
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
3. **Filter out reactions** - Skip if last message is ONLY a reaction/emoji with no text (👍, ❤️, 😂 alone)
4. **Sort** - By timestamp, most recent first
5. **Cap at 20** - Fetch more initially (will filter by sender in Step 3)

**Target: 10 conversations awaiting response after sender filtering.**

If fewer than 1 chat after filtering:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
INBOX CLEAR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
No conversations need attention.
```
Then stop—do not proceed to Phase 2.

### Step 3: Get Details and Filter by Last Sender

**PARALLEL:** Call ALL together:
- `~/.claude/scripts/contacts/search_by_phones_batch.sh "+1xxx" "+1yyy"...`
- `mcp__beeper__list_messages` for each chat (all in same message)

**After receiving results, filter by last sender:**
1. For each chat, check `messages[0].isSender` (most recent message)
2. If `isSender === true` (Andrew sent last), **exclude from batch**
3. Keep only chats where `isSender === false` (awaiting response from you)
4. **Cap at 10** after filtering

**Announce filtered count:**
```
Filtered out: {X} conversations (you sent last)
```

If fewer than 1 chat after filtering:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
INBOX CLEAR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
No conversations awaiting your response.
```
Then stop—do not proceed to Phase 2.

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
- `messages`: Last **5** messages (or all if ≤5), each with:
  - `sender`: Contact name, phone, or "You" for Andrew's messages
  - `text`: Message body (truncate to **200** chars if longer)
  - `hasMedia`: If attachment, format as `[Image]`, `[Video]`, `[File]`, `[Link]`
- `drafts`: Array of 2 generated responses (Quick and Full)

### Step 6: Announce

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BATCH READY - {N} chats
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 2: Batch Review

**ALL chats displayed at once. User makes ALL decisions in a single input. Zero latency between decisions.**

---

### Step 7: Display All Chats

Print all chats to stdout in batch format:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BATCH READY - {N} chats awaiting response
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1] John Smith (iMessage)
John: "Hey, want to grab dinner tonight?"
John: "I was thinking that new Thai place"
John: "How about 7pm?"
→ Q: "Sounds great!"
→ F: "Yes, let's do it! 7pm works perfectly."

[2] Sarah Chen (WhatsApp - Team, 4 people)
... (3 earlier)
Sarah: "Can you review the design mockups?"
Mike: "I'm +1 on the new layout"
Sarah: "Andrew, thoughts?"
→ Q: "Looks good!"
→ F: "Love the new layout, let's ship it."

[3] Mom (iMessage)
Mom: "Are you coming for dinner Sunday?"
Mom: "Dad is making his famous ribs"
→ Q: "Yes!"
→ F: "Definitely coming! Can't miss Dad's ribs."

... (continue for all chats)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Message Formatting Instructions

Build the message display for each chat:

1. Take the last **5** messages from the `messages` array (or all if ≤5)
2. If there were more than 5 messages total, prepend `... ({N} earlier)\n`
3. For each message to display:
   - If the message has media (`hasMedia`), use that value (e.g., `[Image]`)
   - Otherwise, use the text content (truncate to **200** chars if longer)
   - Format as: `{sender}: "{content}"\n`
4. After messages, show drafts:
   - `→ Q: "{quickDraft}"`
   - `→ F: "{fullDraft}"`
5. Blank line between chats

---

### Step 8: Collect Selections

Use AskUserQuestion with freeform input:

```javascript
AskUserQuestion({
  questions: [{
    question: `Enter selections (e.g., "1q 2f 3a 4s"):
• q = Quick reply
• f = Full reply
• a = Archive (no reply)
• s = Skip (leave in inbox)
• c = Custom (will prompt after)`,
    header: "Batch",
    multiSelect: false,
    options: [
      { label: "All Quick", description: "Send quick reply to all" },
      { label: "All Archive", description: "Archive all without reply" },
      { label: "Cancel", description: "Discard and exit" }
    ]
  }]
})
```

**For "Other" (custom text input):** Parse the selections string.

---

### Step 9: Parse and Validate Selections

Parse input like "1q 2f 3a 4s 5q 6c 7f 8a 9q 10f":

**Parsing rules:**
- Split by spaces (or parse as continuous string: "1q2f3a")
- Extract number (1-N where N is total chats)
- Extract action letter (q/f/a/s/c) - case insensitive
- Numbers not mentioned = skip

**Build queued_actions:**
```javascript
queued_actions = [
  { chatID: chats[0].id, action: "send", message: quickDraft },  // 1q
  { chatID: chats[1].id, action: "send", message: fullDraft },   // 2f
  { chatID: chats[2].id, action: "archive_only" },               // 3a
  // 4s = skip, not recorded
  ...
]
```

**Shortcut handling:**
- "All Quick" → set all to quick reply
- "All Archive" → set all to archive only
- "Cancel" → discard and exit

**Error handling:**
- Invalid letter (e.g., "1x") → show error, re-prompt
- Out of range number → ignore
- Duplicate numbers → use last one

---

### Step 10: Handle Custom Messages

If any selections used "c" (custom):

For each custom selection:
```javascript
AskUserQuestion({
  questions: [{
    question: `Custom reply to ${contactName}?

${formatMessages(lastMessages)}`,
    header: "Custom",
    multiSelect: false,
    options: [
      { label: "Skip", description: "Leave in inbox instead" }
    ]
  }]
})
```

**For "Other":** Use the text as the custom message.

---

### Step 11: Confirm Batch

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
READY TO EXECUTE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Replies: {X}
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
