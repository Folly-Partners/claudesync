---
name: sync-env
description: Sync credentials from Keychain to generate .env.local for the current project
---

# Sync environment variables to current project

Sync credentials from Keychain to generate .env.local for the current project.

## Instructions

1. Check if deep-env is installed:
```bash
which deep-env || ls ~/.local/bin/deep-env 2>/dev/null
```

If not installed, run `/setup-deep-env` first.

2. Sync to current directory:
```bash
~/.local/bin/deep-env sync .
```

3. If any keys are missing, ask the user for the values and store them:
```bash
~/.local/bin/deep-env store MISSING_KEY "value"
~/.local/bin/deep-env push  # So other Macs get it
```

4. Verify the .env.local was created:
```bash
ls -la .env.local
```

## Notes
- deep-env reads `.env.example` to know which keys are needed
- If no `.env.example`, it syncs ALL stored credentials
- Missing keys are shown with warnings - ask user for values
