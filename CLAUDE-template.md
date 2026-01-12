# Claude Code Instructions for Andrew's Macs

## Session Start: Git Sync Check (Daily)

**Once per day**, run the git sync check at session start:

```bash
~/.claude/skills/github-sync/git-sync-check.sh
```

The script self-limits to once every 24 hours. To force a check: `git-sync-check.sh --force`

This checks `~/.claude` and `~/Deep-Personality` for:
- Uncommitted changes (from previous sessions)
- Unpushed commits (work that didn't get synced)
- Commits to pull from remote (changes from other machines)

**Actions based on results:**
- If behind remote: `git pull origin main` and tell user
- If uncommitted changes: Ask user if they want to commit or review
- If unpushed commits: Ask user if they want to push
- If clean or already checked today: Proceed silently

## Environment Variables & Credentials

This Mac uses `deep-env` for secure credential management. When working with any project that needs environment variables:

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
cd ~/Journal/web
deep-env store CRON_SECRET "abc123..." --project
```

#### Project Naming Strategy

By default, deep-env uses the directory name as the project identifier (e.g., `web` for `~/Journal/web`). To use a more meaningful project name:

1. **Create `.deep-env-project` file** in your project directory:
   ```bash
   echo "journal" > ~/Journal/web/.deep-env-project
   git add .deep-env-project
   git commit -m "Add deep-env project identifier"
   ```

2. **Store credentials** - deep-env will now use "journal" as the project name:
   ```bash
   cd ~/Journal/web
   deep-env store CRON_SECRET "value" --project  # Stores as "journal:CRON_SECRET"
   ```

3. **Sync works automatically** - reads the `.deep-env-project` file first, falls back to directory name

**Why this matters:** If you have multiple web projects, each can have its own `CRON_SECRET` by using distinct project names in `.deep-env-project` files (e.g., "journal", "dealhunter", "blaze").

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

## Enhanced Planning

For non-trivial features, use enhanced planning from `~/.claude/skills/enhanced-planning/SKILL.md`:

1. **Parallel Research** - Run 3 Task agents simultaneously:
   - Codebase patterns (similar code, conventions, reusable utilities)
   - External best practices (WebSearch/WebFetch for current docs)
   - Framework documentation (official sources, version constraints)

2. **User Flow Analysis** - Map happy paths, edge cases, error states, user variations

3. **Gap Identification** - Find missing specs, ask clarifying questions via AskUserQuestion

4. **Structured Plan** - Output with research findings, flows, steps, open questions, testing strategy

**Apply when:** 3+ files affected, new integrations, architectural changes. Skip for simple fixes.

## Projects

### Deep Personality
- Location: `~/Deep-Personality`
- Shortcut: `deep-env sync dp` or `deep-env sync deep-personality`

## Notes

- Never commit `.env.local` files to git
- When user provides credentials, always store them with `deep-env store`
- If a project needs a new env var, add it and push to iCloud
