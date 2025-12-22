---
name: deep-env
description: Secure credential manager for environment variables. Use this skill when you see .env.example without .env.local, when user provides API keys or credentials, when setting up a new project, or when there are missing environment variable errors.
---

# deep-env - Credential Management

Use this skill to manage environment variables securely across all of Andrew's Macs.

## When to Use This Skill

Automatically invoke this skill when:
- You see a `.env.example`, `.env.template`, or `.env.sample` file without a corresponding `.env.local`
- User provides an API key, secret, or credential
- Error messages mention missing environment variables (e.g., "ANTHROPIC_API_KEY is not defined")
- Setting up or cloning a new project
- User asks about credentials, secrets, or environment variables
- **At session start**: Run `deep-env diff .` to catch keys configured elsewhere (e.g., Vercel) but not stored in deep-env

## Known Projects

| Shortcut | Project | Path |
|----------|---------|------|
| `dp` | Deep Personality | `~/Deep-Personality` |

## Global vs Project-Specific Credentials

Credentials can be:
- **Global**: Available to all projects (e.g., ANTHROPIC_API_KEY, SUPABASE_*)
- **Project-specific**: Only for one project (e.g., ADMIN_EMAILS for Deep Personality)

### Current Project Assignments

**Global (all projects):**
- ANTHROPIC_API_KEY
- GMAIL_USER, GMAIL_APP_PASSWORD
- NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY
- SUPABASE_SERVICE_ROLE_KEY
- FIRECRAWL_API_KEY, APIFY_API_KEY

**Deep-Personality only:**
- ADMIN_EMAILS
- API_SECRET_KEY
- NEXT_PUBLIC_APP_URL

## Commands

### Sync credentials to a project
```bash
deep-env sync .                    # Current directory
deep-env sync ~/Deep-Personality   # Specific path
deep-env sync dp                   # Using shortcut
```

### Store credentials

```bash
# Global credential (available to all projects)
deep-env store ANTHROPIC_API_KEY "sk-ant-xxx"

# Project-specific credential
deep-env store -p dp ADMIN_EMAILS "admin@example.com"
deep-env store --project deep-personality API_SECRET_KEY "xxx"

# Push to iCloud after storing
deep-env push
```

### Assign existing keys to projects

```bash
# Assign to Deep Personality
deep-env assign ADMIN_EMAILS -p dp

# Make a key global
deep-env assign SOME_KEY --global
deep-env assign SOME_KEY -g

# Interactive assignment
deep-env assign KEY_NAME
```

### List credentials (grouped by project)
```bash
deep-env list
```

Output shows:
```
Global (all projects)
  ANTHROPIC_API_KEY       sk-a..._gAA
  GMAIL_USER              andr....com

Deep-Personality
  ADMIN_EMAILS            andr....com
  API_SECRET_KEY          kgg/...nSE=
```

### Diff - Find unstored keys
```bash
deep-env diff .                    # Check current directory
deep-env diff ~/Deep-Personality   # Check specific project
deep-env diff dp                   # Using shortcut
```

This compares `.env.local` against Keychain and shows:
- ✓ Keys that are synced (in both)
- ~ Keys with different values (file vs keychain)
- ✗ Keys NOT in Keychain (configured elsewhere, e.g., Vercel)

**Use this to catch keys that were configured in Vercel/production but never stored in deep-env!**

### Project Registry & Auto-Check
```bash
# Register projects to monitor
deep-env projects add ~/Deep-Personality   # Register a project
deep-env projects add .                    # Register current directory
deep-env projects                          # List registered projects
deep-env projects remove ~/old-project     # Remove a project

# Check all registered projects at once
deep-env check                             # Check ALL projects for unstored keys
deep-env full-sync                         # Check + push to iCloud

# Enable automatic checks (runs at 9 AM and 5 PM)
deep-env auto-sync enable                  # Enable scheduled sync
deep-env auto-sync status                  # Check if enabled
deep-env auto-sync disable                 # Disable
```

When auto-sync runs, it:
1. Checks all registered projects for unstored keys
2. Sends a macOS notification if any are found
3. Pushes credentials to iCloud

### Other commands
```bash
deep-env get KEY_NAME      # Get single value (for scripting)
deep-env delete KEY_NAME   # Remove a credential
deep-env import .env       # Import from existing file
deep-env export            # Output as shell exports
```

## Workflow

### When you see .env.example but no .env.local:
1. Run `deep-env sync .`
2. If keys are missing, ask user for values
3. Determine if key is project-specific or global:
   - URLs specific to the project (NEXT_PUBLIC_APP_URL) → project-specific
   - Admin emails, project secrets → project-specific
   - API keys for services (Anthropic, Supabase, etc.) → global
4. Store appropriately:
   - Global: `deep-env store KEY "value"`
   - Project: `deep-env store -p dp KEY "value"`
5. Push to iCloud: `deep-env push`
6. Re-run `deep-env sync .`

### When user provides a credential:
1. Determine if global or project-specific
2. Store it:
   - Global: `deep-env store KEY "value"`
   - Project: `deep-env store -p PROJECT KEY "value"`
3. Push to iCloud: `deep-env push`
4. If in a project, sync: `deep-env sync .`

### Detecting unstored keys (IMPORTANT!)
When working on a project that may have keys configured elsewhere (Vercel, production, etc.):
1. Run `deep-env diff .` to check for unstored keys
2. If keys are found in .env.local but NOT in Keychain:
   - Ask user if they want to import them
   - Run `deep-env import .env.local` to store all
   - Or store individually: `deep-env store KEY "value"`
3. Push to iCloud: `deep-env push`

**Why this matters:** Keys configured directly in Vercel or copied from production won't sync to other Macs unless stored in deep-env!

### Cross-Mac sync
```bash
# On main Mac (after storing new credentials)
deep-env push

# On other Macs
deep-env pull          # Pulls credentials + project assignments
deep-env sync .        # Generate .env.local
```

### On a new Mac (if deep-env not installed):
```bash
mkdir -p ~/.local/bin
cp ~/Library/Mobile\ Documents/com~apple~CloudDocs/.deep-env/deep-env ~/.local/bin/
chmod +x ~/.local/bin/deep-env
deep-env pull  # Ask user for sync password
deep-env auto-sync enable
```

## Important Notes

- Never commit `.env.local` to git
- Always `deep-env push` after storing new credentials
- The sync password is known only to the user - ask if needed
- Credentials are stored in macOS Keychain (secure)
- iCloud sync uses AES-256 encryption
- Project assignments are stored in `~/.config/deep-env/project-keys.json`
