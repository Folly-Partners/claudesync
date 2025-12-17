---
name: deep-env
description: Secure credential manager for environment variables. Use this skill when you see .env.example without .env.local, when user provides API keys or credentials, when setting up a new project, or when there are missing environment variable errors.
---

# deep-env - Credential Management

Use this skill to manage environment variables securely across all of Andrew's Macs.

## When to Use This Skill

Automatically invoke this skill when:
- You see a `.env.example`, `.env.template`, or `.env.sample` file without a corresponding `.env.local`
- User provides an API key, secret, token, or credential (ALWAYS store it immediately)
- User sets up a new account for any service (API provider, SaaS tool, database, etc.)
- User signs up for or configures any service that provides credentials
- User mentions they got/received/created an API key, token, or secret
- Error messages mention missing environment variables (e.g., "ANTHROPIC_API_KEY is not defined")
- Setting up or cloning a new project
- User asks about credentials, secrets, or environment variables
- User mentions connecting to a new service, integration, or third-party API

**IMPORTANT**: Any time a credential, API key, token, or secret is shared or created, IMMEDIATELY store it with `deep-env store` and push to iCloud. Don't wait to be asked.

## Commands

### Sync credentials to current project
```bash
deep-env sync .
```
This reads `.env.example` and generates `.env.local` from stored credentials.

### Store a new credential
```bash
deep-env store KEY_NAME "value"
deep-env push  # Sync to iCloud for other Macs
```

### List stored credentials
```bash
deep-env list
```

### Get a single value
```bash
deep-env get KEY_NAME
```

## Workflow

### When you see .env.example but no .env.local:
1. Run `deep-env sync .`
2. If keys are missing, ask user for values
3. Store with `deep-env store KEY "value"`
4. Push to iCloud with `deep-env push`
5. Re-run `deep-env sync .`

### When user provides a credential:
1. Store it: `deep-env store KEY "value"`
2. Push to iCloud: `deep-env push`
3. If in a project, sync: `deep-env sync .`

### When user sets up a new account or service:
1. Proactively ask: "Do you have any API keys or credentials for this that I should store?"
2. If they provide credentials, immediately store them:
   ```bash
   deep-env store SERVICE_API_KEY "value"
   deep-env push
   ```
3. Use naming conventions: `SERVICE_API_KEY`, `SERVICE_SECRET`, `SERVICE_TOKEN`

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
