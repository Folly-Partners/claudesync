# ClaudeSync

This plugin syncs Claude Code configuration across all your Macs via the **Folly** marketplace.

## Git Identity

When making commits, get the user's configured identity:
```bash
deep-env get GIT_COMMIT_NAME
deep-env get GIT_COMMIT_EMAIL
```

If not set, ask the user to run `/setup` to configure their git identity.

## Session Start: Git Sync Check (Daily)

**Once per day**, run the git sync check at session start:

```bash
~/.claude/plugins/marketplaces/Folly/skills/github-sync/git-sync-check.sh
```

The script self-limits to once every 24 hours. To force a check: `git-sync-check.sh --force`

This automatically finds all git repos in your home directory and checks them for:
- Uncommitted changes (from previous sessions)
- Unpushed commits (work that didn't get synced)
- Commits to pull from remote (changes from other machines)

**Actions based on results:**
- If behind remote: `git pull origin main` and tell user
- If uncommitted changes: Ask user if they want to commit or review
- If unpushed commits: Ask user if they want to push
- If clean or already checked today: Proceed silently

## Environment Variables & Credentials

This plugin includes `deep-env` for secure credential management. When working with any project that needs environment variables:

### Automatic Detection

When you see:
- A `.env.example`, `.env.template`, or `.env.sample` file
- A missing `.env.local` file
- Error messages about missing environment variables (e.g., `ANTHROPIC_API_KEY is not defined`)

**Use deep-env to sync credentials:**

```bash
# Sync to current project directory
deep-env sync .

# Or specify a path
deep-env sync /path/to/project
```

### Storing New Credentials

When the user provides a new API key or credential:

```bash
# Store it securely
deep-env store KEY_NAME "the-value"

# Then push to iCloud so other Macs get it
deep-env push
```

### Common Commands

```bash
deep-env list              # Show all stored credentials (masked)
deep-env sync .            # Generate .env.local in current directory
deep-env sync              # Defaults to current directory
deep-env store KEY VALUE   # Store a new credential
deep-env get KEY           # Get a single value
deep-env push              # Push to iCloud (for syncing to other Macs)
deep-env pull              # Pull from iCloud (on a new Mac)
```

### How It Works

1. Credentials are stored in macOS Keychain (secure, hardware-backed)
2. `deep-env sync` reads `.env.example` to know which keys a project needs
3. It generates `.env.local` from stored credentials
4. `deep-env push/pull` syncs encrypted credentials via iCloud Drive

### Project-Specific Credentials

Some credentials are specific to a project (like `CRON_SECRET`, `SESSION_SECRET`), while others are shared globally (like API keys). deep-env supports both:

**Global credentials** (default):
```bash
deep-env store ANTHROPIC_API_KEY "sk-ant-..." --global
```

**Project-specific credentials:**
```bash
cd ~/MyProject
deep-env store CRON_SECRET "abc123..." --project
```

#### Project Naming Strategy

By default, deep-env uses the directory name as the project identifier. To use a more meaningful project name:

1. **Create `.deep-env-project` file** in your project directory:
   ```bash
   echo "myproject" > ~/MyProject/.deep-env-project
   ```

2. **Store credentials** - deep-env will now use "myproject" as the project name:
   ```bash
   cd ~/MyProject
   deep-env store CRON_SECRET "value" --project  # Stores as "myproject:CRON_SECRET"
   ```

3. **Sync works automatically** - reads the `.deep-env-project` file first, falls back to directory name

### When Setting Up a New Project

1. Check if `.env.example` exists - it lists required variables
2. Run `deep-env sync .` to generate `.env.local`
3. If keys are missing, ask the user for them and store with `deep-env store`

### On a New Mac

If deep-env isn't installed:
```bash
# Copy from iCloud
mkdir -p ~/.local/bin
cp ~/Library/Mobile\ Documents/com~apple~CloudDocs/.deep-env/deep-env ~/.local/bin/
chmod +x ~/.local/bin/deep-env

# Pull credentials (will ask for sync password)
deep-env pull

# Then sync to any project
deep-env sync /path/to/project
```

## Skills Available

See the `skills/` directory for available skills:
- **deep-env** - Credential management for environment variables
- **github-sync** - Git synchronization at session start
- **history-pruner** - Prune old conversation history
- **component-sync** - Sync plugin components across Macs via iCloud
- **enhanced-planning** - Upgraded planning with parallel research and flow analysis

## Enhanced Planning Mode

**For non-trivial features**, use the enhanced planning workflow:

1. **Parallel Research** - Launch 3 simultaneous Task agents:
   - Codebase pattern analysis (similar implementations, conventions)
   - External best practices (WebSearch + WebFetch for current docs)
   - Framework/dependency documentation

2. **User Flow Analysis** - Before implementation, map:
   - Happy paths and all entry points
   - Edge cases and error states
   - User variations (roles, devices, network conditions)
   - State management and cleanup

3. **Gap Identification** - Identify missing specs, then use AskUserQuestion for critical ambiguities

4. **Structured Plan** - Output with research findings, user flows, implementation steps, open questions, testing strategy

**Apply when:** Any feature touching 3+ files, new integrations, architectural changes, or when the user says "plan" for something complex. Skip for simple bug fixes or single-file changes.

## Interaction Preferences

- **Plans with options**: When presenting plans that have multiple approaches or options, use the `AskUserQuestion` tool with multiple choice format instead of writing out options in prose. This lets the user quickly tap to select rather than typing responses.

## Notes

- Never commit `.env.local` files to git
- When user provides credentials, always store them with `deep-env store`
- If a project needs a new env var, add it and push to iCloud
