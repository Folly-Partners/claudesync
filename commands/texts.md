---
name: texts
description: Processes Beeper text message inbox with AI-generated draft responses. Use when the user says "texts", "process messages", "inbox", or wants to respond to iMessage/WhatsApp messages.
model: sonnet
allowed-tools: Read, Bash, Task, AskUserQuestion, MCPSearch, mcp__beeper__*
---

# Rapid-Fire Texts Inbox Processing

Andrew's phone: +12508845375

**THE ONE RULE: All computation in Phase 1. Phase 2 is pure ask-record-loop with embedded context.**

## Phases

1. **Prep** - Fetch, resolve, generate, prepare (ALL work)
2. **Rapid-fire** - AskUserQuestion with embedded context, record, next (NO computation)
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
- `drafts`: Array of 4 generated responses

### Step 6: Announce

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BATCH READY - {N} chats
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 2: Rapid-Fire

**ZERO COMPUTATION. All context is PRE-GENERATED and EMBEDDED in AskUserQuestion.**

For each chat, call AskUserQuestion with context INSIDE the question field:

```javascript
AskUserQuestion({
  questions: [{
    question: `**[${current}/${total}] ${contactName}** (${platform}${isGroup ? ` - ${participantCount} people` : ''})

${formatMessages(messages)}

Response?`,
    header: `${queuedCount}q`,
    multiSelect: false,
    options: [
      { label: "1", description: truncate(draft1, 80) },
      { label: "2", description: truncate(draft2, 80) },
      { label: "3", description: truncate(draft3, 80) },
      { label: "4", description: truncate(draft4, 80) },
      { label: "Archive", description: "No reply, mark done" },
      { label: "Skip", description: "Leave in inbox" }
    ]
  }]
})
```

**Message Formatting Rules:**

```javascript
function formatMessages(messages) {
  const toShow = messages.slice(-3); // Last 3 messages
  const earlier = messages.length - 3;

  let result = '';
  if (earlier > 0) {
    result += `... (${earlier} earlier)\n`;
  }

  for (const m of toShow) {
    const content = m.hasMedia ? m.hasMedia : truncate(m.text, 120);
    result += `${m.sender}: "${content}"\n`;
  }

  return result.trim();
}
```

**Example outputs:**

Single DM:
```
**[1/8] John Smith** (iMessage)

John: "Hey, want to grab dinner tonight?"
John: "I was thinking that new Thai place"

Response?
```

Group chat:
```
**[3/8] Team Lunch** (WhatsApp - 4 people)

Sarah: "Where should we go?"
Mike: "How about Thai?"
You: "Works for me"
Sarah: "1pm?"

Response?
```

With media:
```
**[5/8] Sarah** (iMessage)

Sarah: "[Image]"
Sarah: "What do you think of this design?"

Response?
```

Long thread:
```
**[7/8] Project Chat** (Slack - 6 people)

... (4 earlier)
Alex: "We need to decide on the database schema..."
You: "I'm leaning toward Postgres for the relatio..."
Alex: "What about the scaling concerns?"

Response?
```

Unknown contact:
```
**[8/8] +1 415 555-0123** (SMS)

+1 415 555-0123: "Hi, this is Mike from the conference..."

Response?
```

**Recording selections:**
- Draft selected → record (chatID, message)
- Archive → record (chatID, archive-only)
- Skip → don't record, move on
- Custom (Other) → ask for message text, record (chatID, custom-message)

---

## Phase 3: Execute

**PARALLEL:** Send all messages together:
```
mcp__beeper__send_message for each selection
```

**PARALLEL:** Archive all chats together:
```
mcp__beeper__archive_chat for each chat (except skipped)
```

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BATCH COMPLETE
Sent: {X} | Archived: {Y} | Skipped: {Z}
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
