# ClaudeSync Commands

Slash commands for common tasks. Type `/command-name` in Claude Code to invoke.

## Quick Reference

| Command | Description |
|---------|-------------|
| `/commit` | Commit changes with smart message generation |
| `/push` | Push commits to GitHub |
| `/scommit` | Silent commit (no confirmation) |
| `/spush` | Silent push (no confirmation) |
| `/add-credential` | Store a new credential in deep-env |
| `/sync-env` | Generate .env.local from stored credentials |
| `/setup-deep-env` | Set up deep-env on a new Mac |
| `/setup` | Initial claudesync setup |
| `/sync` | Sync components across Macs |
| `/github-sync` | Check git status across repositories |
| `/test` | Run tests for current project |
| `/deepcodereview` | Deep code review with AI analysis |
| `/lfg` | Full autonomous engineering workflow |
| `/email` | Rapid-fire email processing with AI drafts |

## Categories

### Git Commands

| Command | File | Description |
|---------|------|-------------|
| `/commit` | [commit.md](commit.md) | Stage and commit changes with auto-generated message |
| `/push` | [push.md](push.md) | Push commits to remote with confirmation |
| `/scommit` | [scommit.md](scommit.md) | Silent commit without confirmation prompts |
| `/spush` | [spush.md](spush.md) | Silent push without confirmation prompts |

### Credential Commands

| Command | File | Description |
|---------|------|-------------|
| `/add-credential` | [add-credential.md](add-credential.md) | Store API key or credential in deep-env |
| `/sync-env` | [sync-env.md](sync-env.md) | Generate .env.local from .env.example |
| `/setup-deep-env` | [setup-deep-env.md](setup-deep-env.md) | Install and configure deep-env |

### Setup Commands

| Command | File | Description |
|---------|------|-------------|
| `/setup` | [setup.md](setup.md) | Initial claudesync setup on a new Mac |
| `/sync` | [sync.md](sync.md) | Force component sync across Macs |
| `/github-sync` | [github-sync.md](github-sync.md) | Check git status for all repositories |

### Development Commands

| Command | File | Description |
|---------|------|-------------|
| `/test` | [test.md](test.md) | Run test suite for current project |
| `/deepcodereview` | [deepcodereview.md](deepcodereview.md) | Comprehensive code review |
| `/lfg` | [lfg.md](lfg.md) | Full autonomous workflow: plan → deepen → work → review → test |

### Communication Commands

| Command | File | Description |
|---------|------|-------------|
| `/email` | [email.md](email.md) | Parallel prep email triage with learning system |

## Usage

Commands are invoked by typing the slash prefix:

```
/commit
```

Some commands accept arguments:

```
/test --watch
```

## Creating New Commands

1. Create a `.md` file in `commands/`
2. Write the command instructions in markdown
3. The filename (without `.md`) becomes the command name
4. Push to sync across Macs

### Example Command File

```markdown
# Command Title

Brief description of what this command does.

## When to Use

Describe when to invoke this command.

## Steps

1. Step one
2. Step two
3. ...

## Options

- `--flag`: Description of flag
```
