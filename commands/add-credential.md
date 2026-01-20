---
name: add-credential
description: Store a new API key or credential securely and sync to iCloud
argument-hint: "[KEY] [VALUE]"
---

# Add a new credential

Store a new API key or credential securely and sync to iCloud.

## Arguments
$ARGUMENTS - The KEY and VALUE to store (e.g., "OPENAI_API_KEY sk-xxx")

## Instructions

1. Parse the arguments to get KEY and VALUE:
   - If user provided both: use them
   - If only KEY: ask user for the value
   - If neither: ask what credential they want to add

2. Store the credential:
```bash
~/.local/bin/deep-env store KEY "VALUE"
```

3. Push to iCloud so other Macs get it:
```bash
~/.local/bin/deep-env push
```

4. Confirm storage:
```bash
~/.local/bin/deep-env list | grep KEY
```

5. If in a project directory with .env.example that needs this key, offer to sync:
```bash
~/.local/bin/deep-env sync .
```
