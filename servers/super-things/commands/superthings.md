---
name: superthings
description: Main command hub for SuperThings - intelligent task management with learning. Shows interactive menu for inbox triage, GTD workflows, pattern management, and stats.
---

# SuperThings Command Hub

Display the SuperThings welcome screen and interactive menu.

## Welcome Screen

Print this ASCII art banner:

```
 ____                      _____ _     _
/ ___| _   _ _ __   ___ _ |_   _| |__ (_)_ __   __ _ ___
\___ \| | | | '_ \ / _ \ '__|| | | '_ \| | '_ \ / _` / __|
 ___) | |_| | |_) |  __/ |   | | | | | | | | | | (_| \__ \
|____/ \__,_| .__/ \___|_|   |_| |_| |_|_|_| |_|\__, |___/
            |_|                                 |___/
```

Then show the status dashboard:

```
┌─────────────────────────────────────────────────────────────┐
│  SUPERTHINGS v2.0                      Learning: ENABLED   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Inbox: [N] items     Today: [N] tasks     Patterns: [N]   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**To get these counts:**
1. Call `things_get_inbox` → count items
2. Call `things_get_today` → count items
3. Call `things_list_patterns` → count patterns

## Main Menu

Use AskUserQuestion to show the main menu:

```
question: "What would you like to do?"
header: "Menu"
multiSelect: false
options:
  - label: "Triage Inbox"
    description: "Sort [N] inbox items into projects with AI suggestions"
  - label: "GTD: Get Things Done"
    description: "Execute tasks from Computer and Deep Work queues"
  - label: "Learning System"
    description: "View patterns, stats, and train the AI"
  - label: "Quick Actions"
    description: "Add task, search, complete, or delegate"
```

## Menu Actions

### Option 1: Triage Inbox
Run the `/thingsinbox` workflow:
- Fetch inbox items
- Apply learned patterns
- Use AskUserQuestion for low-confidence items
- Batch update decisions

### Option 2: GTD: Get Things Done
Run the `/gtd` workflow:
- Fetch Computer and Deep Work projects
- Research tasks with Tavily/Firecrawl
- Execute with C/D/DD commands

### Option 3: Learning System
Show the learning submenu:

```
question: "Learning System"
header: "Learn"
options:
  - label: "View Patterns"
    description: "See all learned title transforms and project hints"
  - label: "View Stats"
    description: "Sessions, accuracy trend, patterns learned"
  - label: "Manage Patterns"
    description: "Remove or adjust pattern confidence"
  - label: "View History"
    description: "Recent corrections and decisions"
```

#### View Patterns
Call `things_list_patterns` and display as:

```
┌─ LEARNED PATTERNS ──────────────────────────────────────────┐
│                                                             │
│  TITLE TRANSFORMS (3)                                       │
│  ├─ ^Fix → "Delegate to Brianna: Fix..."     [12x] ████████ │
│  ├─ ^Call → "Call: ..."                      [8x]  █████    │
│  └─ ^Research → keep original                [5x]  ███      │
│                                                             │
│  PROJECT HINTS                                              │
│  ├─ "build" → Deep Work (15) / Computer (2)                 │
│  ├─ "research" → Computer (23) / Deep Work (1)              │
│  └─ "call" → Call (18)                                      │
│                                                             │
│  EXACT OVERRIDES (1)                                        │
│  └─ "Call mom" → "Call: Mom" → Call project                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### View Stats
Call `things_list_patterns` and show stats section:

```
┌─ LEARNING STATS ────────────────────────────────────────────┐
│                                                             │
│  Sessions Completed:  47                                    │
│  Items Processed:     892                                   │
│  Patterns Learned:    23                                    │
│                                                             │
│  Accuracy Trend:                                            │
│  60% ─── 72% ─── 85%  ↑ improving                          │
│  ████    ██████  █████████                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Manage Patterns
Use AskUserQuestion to select a pattern, then offer:
- Boost confidence (+5)
- Reset confidence (→ 1)
- Remove pattern

Call `things_update_pattern` or `things_remove_pattern` accordingly.

#### View History
Read the last 10 entries from history.jsonl:

```bash
tail -10 ~/claudesync/servers/super-things/data/history.jsonl
```

Display as:

```
┌─ RECENT DECISIONS ──────────────────────────────────────────┐
│                                                             │
│  10m ago  "Fix garage" → "Delegate: Fix garage"    ✓ accept │
│  10m ago  "Research AI" → Computer                 ✓ accept │
│  1h ago   "Build app" → Deep Work                  ✗ changed│
│  1h ago   "Call dentist" → Call                    ✓ accept │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Option 4: Quick Actions
Show quick actions submenu:

```
question: "Quick Action"
header: "Quick"
options:
  - label: "Add Task"
    description: "Create a new task in Things"
  - label: "Search Tasks"
    description: "Find tasks by keyword"
  - label: "Complete Task"
    description: "Mark a task as done"
  - label: "Delegate Task"
    description: "Assign to someone via email"
```

#### Add Task
Ask for task details:

```
question: "Task title?"
header: "Add"
options:
  - label: "Type your task..."
    description: "I'll suggest a project based on learned patterns"
```

Then:
1. Call `things_suggest_for_task` with the title
2. Show suggestion with confidence
3. Call `things_add_todo` to create

#### Search Tasks
```
question: "Search for?"
header: "Search"
options:
  - label: "Type keywords..."
    description: "Search across all tasks and projects"
```

Call `things_search` with the query.

#### Complete Task
Call `things_get_today`, show tasks, let user select one to complete.

#### Delegate Task
Show today's tasks, let user select one, then draft delegation email via Zapier.

## Navigation

After any action completes, offer to return to main menu:

```
question: "What's next?"
header: "Nav"
options:
  - label: "Back to Menu"
    description: "Return to main SuperThings menu"
  - label: "Done"
    description: "Exit SuperThings"
```

## Execution

1. Print the ASCII banner
2. Fetch counts for dashboard (inbox, today, patterns) - do in parallel
3. Print the status dashboard
4. Show main menu via AskUserQuestion
5. Execute selected action
6. Offer navigation back to menu or exit

## CLI Style Guidelines

- Use box-drawing characters: `┌ ┐ └ ┘ │ ─ ├ ┤`
- Use progress bars: `████████░░`
- Use status indicators: `✓ ✗ ● ○ ▶ ■`
- Keep lines under 65 chars for readability
- Use consistent spacing and alignment
- Show counts in brackets: `[12]`
- Show confidence with `[Nx]` notation

## MCP Tools Reference

| Tool | Purpose |
|------|---------|
| `things_get_inbox` | Get inbox items |
| `things_get_today` | Get today's tasks |
| `things_list_patterns` | Get all learned patterns |
| `things_suggest_for_task` | Get AI suggestion for a title |
| `things_log_correction` | Log a single correction |
| `things_learn_batch` | Log multiple decisions |
| `things_update_pattern` | Adjust pattern confidence |
| `things_remove_pattern` | Remove a pattern |
| `things_add_todo` | Create a new task |
| `things_search` | Search for tasks |
| `things_update_todo` | Update a task |
| `things_complete_todo` | Complete a task |

## Example Session

```
$ /superthings

 ____                      _____ _     _
/ ___| _   _ _ __   ___ _ |_   _| |__ (_)_ __   __ _ ___
\___ \| | | | '_ \ / _ \ '__|| | | '_ \| | '_ \ / _` / __|
 ___) | |_| | |_) |  __/ |   | | | | | | | | | | (_| \__ \
|____/ \__,_| .__/ \___|_|   |_| |_| |_|_|_| |_|\__, |___/
            |_|                                 |___/

┌─────────────────────────────────────────────────────────────┐
│  SUPERTHINGS v2.0                      Learning: ENABLED   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Inbox: [12] items    Today: [8] tasks     Patterns: [23]  │
│                                                             │
└─────────────────────────────────────────────────────────────┘

? What would you like to do?
  ▶ Triage Inbox - Sort 12 inbox items into projects with AI suggestions
    GTD: Get Things Done - Execute tasks from Computer and Deep Work queues
    Learning System - View patterns, stats, and train the AI
    Quick Actions - Add task, search, complete, or delegate
```
