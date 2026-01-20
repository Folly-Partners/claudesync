# ClaudeSync Agents

Specialized Task agents for complex, multi-step workflows that require focused context and specific processing logic.

## Available Agents

| Agent | Purpose | Model | Trigger |
|-------|---------|-------|---------|
| [email-response-processor](email-response-processor.md) | Process Gmail emails with "simple-decision" label | Sonnet | "Let's go" for emails |
| [inbox-task-manager](inbox-task-manager.md) | Review, clarify, rewrite inbox tasks | Haiku | "let's go" for tasks |
| [wardrobe-cataloger](wardrobe-cataloger.md) | Analyze clothing photos, add to Google Sheet | Opus | Upload clothing photos |

## Agent Descriptions

### Email Response Processor
Handles bulk email review by creating multiple response options for each email. User says "Let's go" to start, then selects responses using a compact format like "1: 2, 3: 1 Karen, 5: Archive".

**Key features:**
- Processes 30 emails initially, 10 per batch after
- Creates 2-6 response options per email
- Supports CC additions and custom modifications
- Archives emails after sending

### Inbox Task Manager
Manages Things inbox with clarification, rewriting, and project assignment. Designed for voice-dictated tasks that need cleanup.

**Key features:**
- Caches tasks locally for context efficiency
- Escalates to Sonnet for complex decisions
- User shortcuts: d=delete, k=keep, s=skip
- Suggests project assignments based on task content

### Wardrobe Cataloger
Analyzes clothing photos and adds items to a Google Sheet wardrobe database with 22 metadata fields.

**Key features:**
- Determines next Item_ID automatically
- Extracts brand, color, material, style, etc.
- Uses Zapier Google Sheets integration
- Processes multiple items in sequence

## When to Use Agents

Agents are invoked automatically via the Task tool when:
1. The conversation matches the agent's description triggers
2. User explicitly mentions the agent's trigger phrase
3. A task requires the agent's specialized workflow

## Agent Structure

Agents are defined in `.md` files with YAML frontmatter:

```yaml
---
name: agent-name
description: Long description with examples for matching...
model: sonnet|haiku|opus
color: blue|green|...
---

You are a [persona description]...

## Workflow
1. Step one
2. Step two
...
```

The `description` field includes examples that help Claude Code match conversations to the appropriate agent.

## Creating New Agents

1. Create a `.md` file in `agents/`
2. Add YAML frontmatter with name, description, model, color
3. Write detailed instructions for the agent persona
4. Include examples in the description for trigger matching
5. Push to sync across Macs
