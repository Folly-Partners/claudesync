# iMessage Sync Fix Plan - macOS 26.1

## WARNING: Session Disruption
These fixes will interrupt active sessions:
- Killing services may disrupt network-dependent tools
- Reboots will end your Claude Code session
- **Execute when ready to end current session**

## Problem
iMessage settings stuck on infinite spinner (sign-out button area), won't sync or connect properly on macOS Tahoe 26.1.

## Diagnosis Summary
- **macOS 26.2 available** - Some users report fixes in 26.2, but not everyone
- **Proxy auto-discovery already OFF** - Common Tahoe fix doesn't apply here
- **TunnelBear VPN installed** - Can leave residual network configs even when disconnected
- **Apple server connectivity OK** - DNS and direct connections working

## Troubleshooting Plan (Terminal-Based)

### Step 1: Kill and Restart iMessage Services
```bash
# Kill all iMessage-related processes
killall Messages imagent IMDPersistenceAgent identityservicesd 2>/dev/null

# Clear iMessage registration cache
rm -rf ~/Library/Caches/com.apple.iCloudHelper/
rm -rf ~/Library/Caches/com.apple.imfoundation.IMRemoteURLConnectionAgent/

# Restart identity services (will auto-relaunch)
killall identityservicesd 2>/dev/null
```

### Step 2: Reset TunnelBear VPN Network Residue
```bash
# Remove TunnelBear from network services (even if disconnected, it can interfere)
sudo networksetup -removenetworkservice "TunnelBear" 2>/dev/null

# Flush DNS cache
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Reset network preferences to remove any VPN proxy residue
sudo rm /Library/Preferences/SystemConfiguration/preferences.plist 2>/dev/null
sudo rm /Library/Preferences/SystemConfiguration/NetworkInterfaces.plist 2>/dev/null
# NOTE: This requires a reboot and will reset network settings
```

### Step 3: Clear iCloud Identity Token Cache
```bash
# Remove cached identity tokens
rm -rf ~/Library/Application\ Support/iCloud/Accounts/* 2>/dev/null
rm -rf ~/Library/Caches/com.apple.ids/ 2>/dev/null

# Clear keychain cached tokens (less destructive than full reset)
security delete-generic-password -s "ids: identity-rsa-key-pair-service" 2>/dev/null
```

### Step 4: Force iCloud Re-authentication
```bash
# Kill iCloud daemon to force re-auth
killall bird cloudd 2>/dev/null

# Reboot
sudo reboot
```

### Step 5: If Steps 1-4 Fail - Upgrade to macOS 26.2
```bash
# Download and install macOS 26.2
softwareupdate --download --all
sudo softwareupdate --install --all --restart
```

### Step 6: Nuclear Option - Full iCloud Sign Out/In
If upgrade doesn't fix it:
1. System Settings > Apple Account > Sign Out
2. Reboot
3. Sign back in
4. Re-enable iCloud services one by one

## Recommended Execution Order

1. **Step 1: Kill services & clear caches** (quick, low risk)
2. **Reboot and test** - see if spinner resolves
3. **Step 3: Clear identity token cache** if still broken
4. **Step 4: Force iCloud re-auth** + reboot
5. **Step 5: Upgrade to macOS 26.2** if terminal fixes don't work
6. **Step 2: Network reset** only if 26.2 doesn't fix it (requires Wi-Fi reconfiguration)
7. **Step 6: Full iCloud sign out/in** as absolute last resort

## Files That Will Be Modified/Deleted
- `~/Library/Caches/com.apple.iCloudHelper/`
- `~/Library/Caches/com.apple.imfoundation.IMRemoteURLConnectionAgent/`
- `~/Library/Caches/com.apple.ids/`
- `~/Library/Application Support/iCloud/Accounts/`
- `/Library/Preferences/SystemConfiguration/preferences.plist` (Step 2 only)
- `/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist` (Step 2 only)

## Notes
- Messages data (`~/Library/Messages/chat.db`) will NOT be touched - your message history is safe
- The 26.2 upgrade is ~3.6GB
- One user reported 26.2 still didn't fix their issue, so terminal fixes should be tried first
