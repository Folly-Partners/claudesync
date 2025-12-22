# Compound Engineering Plugin

Streamlines software development through three core commands for planning, executing, and reviewing code.

## Commands

### /plan
Transforms feature ideas into detailed GitHub issues with:
- Research and context gathering
- Acceptance criteria
- Implementation examples

### /work
Executes plans systematically using:
- Isolated git worktrees
- Task tracking
- Continuous testing

### /review
Conducts comprehensive multi-agent code reviews analyzing:
- Security vulnerabilities
- Performance issues
- Architecture patterns
- 12+ specialized reviewers (Rails, TypeScript, Python, etc.)

## MCP Tools Available

The plugin includes Playwright browser automation:
- `browser_navigate` - Navigate to URLs
- `browser_take_screenshot` - Capture screenshots

## When to Use

- **Starting a new feature**: Use `/plan` to create a detailed GitHub issue
- **Implementing a plan**: Use `/work` to execute with worktrees and testing
- **Before merging**: Use `/review` for comprehensive code review

## Setup

Plugin is installed via Every Marketplace:
```
/plugin marketplace add https://github.com/EveryInc/every-marketplace
/plugin install compound-engineering
```

MCP server configured in `~/.claude.json` under the project settings.
