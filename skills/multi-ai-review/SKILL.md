---
name: multi-ai-review
description: Get plan reviews from Codex and Gemini before implementation. Both AIs review the plan against the actual codebase and suggest improvements. Claude then incorporates their feedback.
---

# Multi-AI Plan Review

After writing a plan, get feedback from Codex and Gemini. Both review the plan against the actual codebase and suggest improvements. Claude then updates the plan based on their feedback.

## Workflow

### Step 1: Claude Writes Initial Plan

Use enhanced-planning or standard plan mode to create an implementation plan. Save it to a file (e.g., `plans/feature-name.md`).

### Step 2: Gather Codebase Context for External Tools

Prepare context that helps Codex and Gemini understand the codebase:

```bash
# Create a context summary
cat > /tmp/codebase-context.txt << 'EOF'
PROJECT: $(basename $(pwd))
STRUCTURE:
$(find . -type f -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.rb" -o -name "*.go" | grep -v node_modules | grep -v .git | head -50)

KEY FILES:
$(cat README.md 2>/dev/null | head -30)
$(cat CLAUDE.md 2>/dev/null | head -30)
$(cat ARCHITECTURE.md 2>/dev/null | head -30)
EOF
```

### Step 3: Run Plan Reviews in Parallel

Launch both reviews simultaneously. Each tool receives:
1. The plan file
2. Codebase context
3. Instructions to suggest improvements

**Codex Review:**
```bash
cd <project_dir> && codex exec "Review this implementation plan against the codebase.

YOUR TASK:
1. Check if the plan accounts for existing code patterns and conventions
2. Identify missing steps or edge cases
3. Suggest any strategy improvements
4. Flag potential conflicts with existing code
5. Add any tasks the plan missed

Be specific - reference actual files and code when possible.

THE PLAN:
$(cat <plan_file>)

CODEBASE STRUCTURE:
$(find . -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.py' -o -name '*.rb' \) | grep -v node_modules | head -30)

KEY CONTEXT:
$(cat README.md CLAUDE.md 2>/dev/null | head -50)"
```

**Gemini Review:**
```bash
cd <project_dir> && gemini "You are a senior engineer reviewing an implementation plan. Your job is to improve it.

REVIEW CHECKLIST:
1. Does the plan account for existing patterns in this codebase?
2. Are there missing steps or edge cases?
3. Could the strategy be simplified or improved?
4. Are there potential conflicts with existing code?
5. What tasks or considerations did the plan miss?

Be specific and actionable. Reference actual files when relevant.

THE PLAN:
$(cat <plan_file>)

CODEBASE FILES:
$(find . -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.py' -o -name '*.rb' \) | grep -v node_modules | head -30)

KEY CONTEXT:
$(cat README.md CLAUDE.md 2>/dev/null | head -50)"
```

### Step 4: Synthesize Feedback

After both tools respond, Claude synthesizes their feedback:

```markdown
## External AI Feedback

### Codex Suggestions
- [List key points from Codex]

### Gemini Suggestions
- [List key points from Gemini]

### Consensus (Both Agree)
- [Items both tools flagged]

### Unique Insights
- From Codex: [...]
- From Gemini: [...]
```

### Step 5: Update the Plan

Claude incorporates the feedback and updates the plan file:

1. Add missing tasks/steps both tools identified
2. Adjust strategy based on their recommendations
3. Add edge cases they flagged
4. Note any disagreements and Claude's resolution

Mark incorporated changes with `[Added per Codex/Gemini review]` so the user can see what changed.

### Step 6: Present Updated Plan

Show the user:
1. Summary of what changed
2. The updated plan
3. Any feedback Claude disagreed with (and why)

## Usage

After writing a plan in plan mode:

```
/multi-ai-review plans/my-feature.md
```

Or Claude can invoke this automatically after writing a plan by asking:
"Want me to get Codex and Gemini to review this plan before we proceed?"

## Example Flow

```
User: Plan adding user avatars with S3 upload
Claude: [Uses enhanced-planning, writes plan to plans/avatars.md]
Claude: Want me to get external AI review of this plan?
User: Yes
Claude: [Runs /multi-ai-review plans/avatars.md]
Claude: [Shows Codex + Gemini feedback]
Claude: [Updates plan with their suggestions]
Claude: Here's the updated plan with their feedback incorporated. Ready to implement?
```

## Notes

- Both tools run from the project directory for full codebase access
- Codex uses `codex exec` for one-shot prompts (not `codex review` which is for code diffs)
- Gemini receives context via the prompt
- Claude maintains final judgment - not all suggestions must be incorporated
- The goal is better plans through diverse AI perspectives
