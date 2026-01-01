# Plan: Email Lookup Integration for SuperThings

## Summary

Add email lookup capability to SuperThings by creating a `CLAUDE.md` instruction file in the SuperThings project that teaches Claude to automatically resolve email addresses using a cascade: Google Contacts → Gmail history → Hunter API. Cache found emails in `~/.claude/data/email-cache.json` for sync across machines.

## Files to Create

| File | Purpose |
|------|---------|
| `/Users/andrewwilkinson/Projects/SuperThings/CLAUDE.md` | Instructions for email lookup workflow |
| `/Users/andrewwilkinson/.claude/data/email-cache.json` | Cache of resolved emails (syncs via GitHub) |

## Implementation

### Step 1: Create email cache file

**File**: `~/.claude/data/email-cache.json`

```json
{
  "contacts": {
    "john smith|acme": {
      "email": "john.smith@acme.com",
      "source": "hunter",
      "found": "2025-01-01",
      "verified": true
    }
  }
}
```

Key format: `lowercase name|domain` for easy lookup.

### Step 2: Create CLAUDE.md in SuperThings project

**File**: `/Users/andrewwilkinson/Projects/SuperThings/CLAUDE.md`

Content:

```markdown
# SuperThings Email Lookup

## Auto-Trigger

When ANY person is mentioned by name and an email address is needed (or might be useful), automatically resolve their email before proceeding.

**Triggers:**
- Todo involves contacting someone
- User mentions a person's name without their email
- Keywords: "email", "contact", "reach out", "follow up with", "send to"

## Lookup Cascade

1. **Check cache first**: Read `~/.claude/data/email-cache.json`
2. **Gmail/Contacts**: `mcp__zapier__gmail_find_email` with name query
3. **Hunter API**: Use Hunter MCP tools with inferred domain
4. **Ask user**: If all else fails

## Domain Inference

Infer company domain from context:
- "John at Acme Corp" → acme.com, acmecorp.com
- "Sarah from Google" → google.com
- Recent conversation mentions company
- LinkedIn profile if visible

Try common domain patterns: company.com, companyinc.com, thecompany.com

## Caching

After successful lookup, update `~/.claude/data/email-cache.json`:
- Key: `name|domain` (lowercase)
- Store: email, source, date found, verified status

## Tool Usage

### Gmail Search
mcp__zapier__gmail_find_email with query: "from:{name}" or "to:{name}"

### Hunter API
Use Hunter MCP server tools to:
1. Find email by name + domain
2. Verify email validity

## Example Flow

User: "Create a todo to email John Smith at Acme about the proposal"

1. Check cache for "john smith|acme" → not found
2. Gmail search for "john smith acme" → not found
3. Hunter: find email for "John Smith" at "acme.com" → john.smith@acme.com
4. Cache result
5. Create todo with email in notes
```

### Step 3: Ensure data directory exists

Create `~/.claude/data/` directory if it doesn't exist (will be tracked by git).

## Notes

- Email cache syncs via existing `~/.claude` GitHub sync
- Domain inference uses context clues (company mentions, LinkedIn, etc.)
- Hunter API key already configured in `~/.claude/mcp.json`
- Zapier Gmail tools already available for contact lookup
