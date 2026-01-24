---
name: multi-ai-review
description: Get code reviews from Codex and Gemini CLI tools in parallel. Use when you want external AI perspectives on code changes, plans, or implementations.
---

# Multi-AI Review Skill

Get parallel code reviews from OpenAI Codex and Google Gemini CLI tools. Both tools review the actual codebase, not just plans.

## When to Use

- After implementing a feature, before committing
- When reviewing a plan before implementation
- For security/architecture second opinions
- When stuck and want fresh perspectives

## Usage

```
/multi-ai-review                    # Review uncommitted changes
/multi-ai-review --base main        # Review changes vs main branch
/multi-ai-review --commit abc123    # Review a specific commit
/multi-ai-review --files src/       # Review specific files/directory
/multi-ai-review --plan plans/x.md  # Review a plan file with codebase context
```

## Workflow

### Step 1: Determine Review Scope

Parse arguments to determine what to review:

| Argument | What Gets Reviewed |
|----------|-------------------|
| (none) | Uncommitted changes (staged + unstaged) |
| `--base <branch>` | Changes compared to branch |
| `--commit <sha>` | Single commit changes |
| `--files <path>` | Specific files or directory |
| `--plan <file>` | Plan file + relevant codebase files |

### Step 2: Gather Context

Before calling external tools, gather codebase context:

```bash
# Get project root and structure
pwd
ls -la
cat README.md 2>/dev/null | head -50
cat CLAUDE.md 2>/dev/null | head -50

# For uncommitted changes
git status
git diff --stat

# For branch comparison
git log --oneline main..HEAD
git diff --stat main
```

### Step 3: Run Reviews in Parallel

Launch both reviews simultaneously using Bash tool calls in parallel:

**Codex Review:**
```bash
cd <project_dir> && codex review --uncommitted "Focus on: security, performance, edge cases, and adherence to project conventions"
```

Or with branch:
```bash
cd <project_dir> && codex review --base main "Focus on: security, performance, edge cases"
```

**Gemini Review:**
```bash
cd <project_dir> && cat <<'CONTEXT' | gemini "You are reviewing code changes. Here is the project context and diff. Provide a thorough review focusing on: 1) Security issues 2) Performance concerns 3) Edge cases 4) Code quality 5) Suggestions for improvement.

$(git diff --stat)
$(git diff)
CONTEXT"
```

For file-specific reviews:
```bash
cd <project_dir> && gemini "Review these files for issues, improvements, and adherence to best practices: $(cat <files>)"
```

For plan reviews with codebase context:
```bash
cd <project_dir> && gemini "Review this implementation plan against the actual codebase. Check if the plan accounts for existing patterns, potential conflicts, and edge cases.

PLAN:
$(cat <plan_file>)

RELEVANT CODE:
$(find . -name '*.ts' -o -name '*.tsx' | head -20 | xargs head -50 2>/dev/null)"
```

### Step 4: Aggregate Results

Present both reviews with clear sections:

```markdown
## Codex Review

[Codex output here]

## Gemini Review

[Gemini output here]

## Summary

**Common Concerns:** [Issues both flagged]
**Unique from Codex:** [Only Codex mentioned]
**Unique from Gemini:** [Only Gemini mentioned]

### Recommended Actions
1. [Prioritized action items]
```

## Example Invocations

### Review Uncommitted Changes
```
User: /multi-ai-review
Claude: [Runs both tools on uncommitted changes, presents aggregated feedback]
```

### Review Against Main Branch
```
User: /multi-ai-review --base main
Claude: [Uses codex review --base main, pipes branch diff to gemini]
```

### Review Plan With Codebase Context
```
User: /multi-ai-review --plan plans/auth-feature.md
Claude: [Sends plan + relevant code files to both tools for validation]
```

## Custom Review Focus

You can add a focus area after the flags:

```
/multi-ai-review --base main security    # Focus on security
/multi-ai-review architecture            # Focus on architecture
/multi-ai-review performance             # Focus on performance
```

Pass the focus to both tools in their prompts.

## Notes

- Both tools run from the project directory, so they have full filesystem context
- Codex has built-in git awareness via `--uncommitted` and `--base` flags
- Gemini receives context via stdin/prompt
- Reviews run in parallel for speed
- If either tool fails, still present the other's results
