# Deep-env Security Hardening Plan

## Scope: Phase 1 + Phase 2

**Implementing:**
1. Store sync password in Keychain (not plaintext file)
2. Use stdin for OpenSSL password (not process args)
3. Add access logging for all credential operations
4. Secure temp file handling (shred or memory-only)

---

## Current Security Model

**What's Good:**
- macOS Keychain (hardware-backed encryption on Apple Silicon)
- AES-256-CBC with PBKDF2 for iCloud sync
- File permissions (600) on sensitive files
- Credential masking in output

**Vulnerabilities Identified:**

| Issue | Severity | Description |
|-------|----------|-------------|
| Plaintext sync password | **HIGH** | `~/.config/deep-env/.sync_pass` stores password in plaintext for auto-sync |
| Password in process list | **HIGH** | OpenSSL `-pass pass:"$password"` visible in `ps aux` |
| No access logging | MEDIUM | No way to detect if something is reading credentials |
| Any user process access | MEDIUM | Keychain items accessible to any process as user |
| Temp file exposure | MEDIUM | Decrypted credentials briefly exist in temp files |
| No key rotation tracking | LOW | No visibility into when keys were last changed |

---

## Recommended Improvements

### 1. Store Sync Password in Keychain (HIGH PRIORITY)

**Problem:** `.sync_pass` is plaintext, readable by any process.

**Solution:** Store sync password in Keychain itself.

```bash
# Store sync password securely
security add-generic-password -s "deep-env-sync" -a "master" -w "$password" -U

# Retrieve for auto-sync
password=$(security find-generic-password -s "deep-env-sync" -a "master" -w)
```

**Changes:**
- Remove `.sync_pass` file entirely
- Auto-sync reads from Keychain instead
- Keychain item protected by system login

---

### 2. Use stdin for OpenSSL Password (HIGH PRIORITY)

**Problem:** `openssl enc -pass pass:"$password"` exposes password in process list.

**Current (vulnerable):**
```bash
openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$password" ...
```

**Fixed:**
```bash
echo "$password" | openssl enc -aes-256-cbc -salt -pbkdf2 -pass stdin ...
```

Or using file descriptor:
```bash
openssl enc -aes-256-cbc -salt -pbkdf2 -pass fd:3 3<<<"$password" ...
```

---

### 3. Add Access Logging (MEDIUM PRIORITY)

**Problem:** No visibility into what's accessing credentials.

**Solution:** Log all credential access with timestamps.

```bash
# ~/.config/deep-env/access.log
2024-01-15T10:23:45 GET ANTHROPIC_API_KEY (deep-env sync)
2024-01-15T10:23:45 GET SUPABASE_URL (deep-env sync)
2024-01-15T14:30:00 STORE NEW_KEY (deep-env store)
```

**Features:**
- Timestamp every get/store/delete
- Include calling context (which command)
- Option to send alerts on unusual patterns

---

### 4. Secure Temp File Handling (MEDIUM PRIORITY)

**Problem:** During decrypt, plaintext exists in temp files briefly.

**Solution:** Use memory-only decryption or secure delete.

```bash
# Use named pipe (never touches disk)
mkfifo "$tmpdir/credentials_pipe"
openssl enc -d ... > "$tmpdir/credentials_pipe" &
while read line; do
  # Process in memory
done < "$tmpdir/credentials_pipe"
rm "$tmpdir/credentials_pipe"
```

Or use `shred` for cleanup:
```bash
shred -u "$temp_file"  # Overwrite then delete
```

---

## Implementation Steps

### Step 1: Migrate Sync Password to Keychain
- Add function `sync_password_store()` - saves to Keychain service "deep-env-sync"
- Add function `sync_password_get()` - retrieves from Keychain
- Update `push` command to use new functions
- Update `pull` command to use new functions
- Delete `.sync_pass` file after migration

### Step 2: Fix OpenSSL Password Exposure
- Find all `openssl enc` calls in script
- Replace `-pass pass:"$password"` with `-pass stdin` pattern
- Test encryption/decryption still works

### Step 3: Add Access Logging
- Add function `log_access(action, key, context)`
- Call from `keychain_get()`, `keychain_set()`, `keychain_delete()`
- Create `~/.config/deep-env/access.log` with rotation
- Format: `TIMESTAMP ACTION KEY_NAME (CONTEXT)`

### Step 4: Secure Temp File Handling
- Find all temp file usage in script
- Replace `rm` with `shred -u` where plaintext is involved
- Or refactor to use named pipes for streaming decryption

---

## Files to Modify

| File | Changes |
|------|---------|
| `~/.local/bin/deep-env` | All encryption/security changes (~1,890 lines bash script) |
| `~/.config/deep-env/.sync_pass` | **Delete** - migrate to Keychain |
| `~/.config/deep-env/access.log` | **New** - access audit log |

---

## Migration Path

1. **Backup current setup**: `deep-env push` to ensure iCloud has latest
2. **Update script** with security fixes
3. **Migrate sync password**: Move from file to Keychain
4. **Delete plaintext file**: `shred -u ~/.config/deep-env/.sync_pass`
5. **Test auto-sync**: Verify launchd job still works
6. **Enable logging**: Start collecting access patterns

---

## Security Properties After Hardening

| Property | Before | After |
|----------|--------|-------|
| Sync password storage | Plaintext file | Keychain (encrypted) |
| Password visibility | Process list | Hidden (stdin) |
| Access audit trail | None | Full logging |
| Temp file exposure | Brief plaintext | Memory-only or shredded |

---

## What This Still Doesn't Protect Against

- Compromised user account (attacker logged in as you)
- Malware with root access
- Physical access to unlocked Mac
- iCloud account compromise (encrypted, but attacker could delete)
- Memory inspection by privileged process

**Bottom line:** These improvements raise the bar significantly for casual access while keeping the workflow simple. The main threat model is still "protect against accidental exposure and opportunistic access."
