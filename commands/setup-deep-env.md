# Setup deep-env on this Mac

Set up the deep-env credential management system on this Mac. This syncs environment variables securely across all of Andrew's Macs via iCloud.

## Instructions

1. First, check if deep-env is already installed:
```bash
which deep-env || ls ~/.local/bin/deep-env
```

2. If NOT installed, install from iCloud:
```bash
mkdir -p ~/.local/bin
cp ~/Library/Mobile\ Documents/com~apple~CloudDocs/.deep-env/deep-env ~/.local/bin/
chmod +x ~/.local/bin/deep-env
```

3. Check if credentials are already pulled:
```bash
~/.local/bin/deep-env list
```

4. If no credentials shown, pull from iCloud:
```bash
~/.local/bin/deep-env pull
```
**ASK THE USER FOR THE SYNC PASSWORD** - they set it on their main Mac.

5. Enable auto-sync:
```bash
~/.local/bin/deep-env auto-sync enable
```

6. Verify setup:
```bash
~/.local/bin/deep-env list
~/.local/bin/deep-env auto-sync status
```

7. If working in a project directory, sync credentials:
```bash
~/.local/bin/deep-env sync .
```

## Summary
After setup, tell the user:
- `deep-env sync .` - Generate .env.local in any project
- `deep-env store KEY VALUE` - Store new credentials
- `deep-env push` - Push changes to iCloud
- `deep-env list` - See all stored credentials
