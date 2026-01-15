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

3. Add to PATH if not already (check with `echo $PATH`):
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

4. Check if credentials are already pulled:
```bash
deep-env list
```

5. If no credentials shown, pull from iCloud:
```bash
deep-env pull
```
**ASK THE USER FOR THE SYNC PASSWORD** - they set it on their main Mac.
(Hint: check `~/.config/deep-env/.sync_pass` on another working Mac)

6. Validate the installation:
```bash
deep-env validate
deep-env list | head -10
```

If validate shows errors, try:
```bash
deep-env pull  # Re-pull from iCloud
```

7. Check version:
```bash
deep-env --version
```

8. If working in a project directory, sync credentials:
```bash
deep-env sync .
```

## Troubleshooting

If "No credentials stored" but user had credentials:
```bash
deep-env validate        # Check for corruption
deep-env restore         # List available backups
deep-env pull            # Re-pull from iCloud
```

## Summary
After setup, tell the user:
- `deep-env sync .` - Generate .env.local in any project
- `deep-env store KEY VALUE` - Store new credentials
- `deep-env push` - Push changes to iCloud
- `deep-env list` - See all stored credentials
- `deep-env backup` - Create a backup
- `deep-env validate` - Check data integrity
