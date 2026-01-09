# Fix Journal Passkey Cross-Device Authentication

## Problem
Passkey authentication failing with origin mismatch error:
- Passkey registered with: `https://journal.software`
- Accessing via: `https://www.journal.software`
- Error: "Unexpected authentication response origin"

WebAuthn passkeys are strictly bound to their exact origin (protocol + domain). The www/non-www mismatch prevents authentication.

## Root Cause
1. No `WEBAUTHN_RP_ID` or `WEBAUTHN_ORIGIN` configured in environment variables
2. Code defaults to `localhost` for development
3. Code only accepts a single origin for verification
4. Production passkey was registered without consistent domain configuration

## Solution Overview
Configure WebAuthn to accept BOTH `journal.software` and `www.journal.software` origins so user never has to worry about which URL they use.

## Implementation Steps

### 1. Modify WebAuthn Library to Accept Multiple Origins
**File:** `/Users/andrewwilkinson/Journal/web/lib/auth.ts`

Change lines 22-26 from:
```typescript
const RP_NAME = 'Andrew\'s Journal';
const RP_ID = process.env.WEBAUTHN_RP_ID || 'localhost';
const ORIGIN = process.env.WEBAUTHN_ORIGIN ||
  (RP_ID === 'localhost' ? 'http://localhost:3000' : `https://${RP_ID}`);
```

To:
```typescript
const RP_NAME = 'Andrew\'s Journal';
const RP_ID = process.env.WEBAUTHN_RP_ID || 'localhost';
// Support both www and non-www origins in production
const ORIGINS = RP_ID === 'localhost'
  ? ['http://localhost:3000']
  : [`https://${RP_ID}`, `https://www.${RP_ID}`];
```

Then update line 136 in `completeRegistration()` from:
```typescript
expectedOrigin: ORIGIN,
```

To:
```typescript
expectedOrigin: ORIGINS,
```

And update line 224 in `completeAuthentication()` from:
```typescript
expectedOrigin: ORIGIN,
```

To:
```typescript
expectedOrigin: ORIGINS,
```

This allows SimpleWebAuthn to accept EITHER origin during verification.

### 2. Configure WebAuthn Environment Variable
**File:** `/Users/andrewwilkinson/Journal/web/.env.local`

Add this environment variable:
```
WEBAUTHN_RP_ID=journal.software
```

**Store in deep-env for sync across Macs:**
```bash
cd /Users/andrewwilkinson/Journal/web
deep-env store WEBAUTHN_RP_ID "journal.software"
deep-env push
deep-env sync .
```

### 3. Update .env.example Template
**File:** `/Users/andrewwilkinson/Journal/web/.env.example`

Add documentation:
```
# WebAuthn/Passkey Configuration
# Set to your domain (without protocol). Supports both www and non-www automatically.
WEBAUTHN_RP_ID=journal.software

# Existing variables...
ANTHROPIC_API_KEY=
FIREFLIES_API_KEY=
LIMITLESS_API_KEY=
```

### 4. Reset Passkey Credential
Delete existing credential from Vercel Blob:
```bash
# Option A: Via Vercel dashboard - delete blob at path: auth/credential.json
# Option B: Via CLI if blob CLI is available
```

Or manually via API/dashboard in Vercel Blob storage.

### 5. Configure Vercel Environment Variables
Set production environment variable:
- `WEBAUTHN_RP_ID` = `journal.software`

Via Vercel CLI:
```bash
cd /Users/andrewwilkinson/Journal/web
vercel env add WEBAUTHN_RP_ID production
# Enter: journal.software
```

### 6. Deploy to Vercel
```bash
cd /Users/andrewwilkinson/Journal/web
vercel --prod
```

### 7. Register New Passkey
1. Navigate to `https://journal.software/login` (or www variant - both work now)
2. Click "Sign in with Passkey"
3. Browser will prompt to create passkey
4. Passkey will sync via iCloud Keychain to all Macs

### 8. Sync Configuration to All Macs
On each Mac:
```bash
cd /Users/andrewwilkinson/Journal/web
deep-env pull  # Pull WEBAUTHN_RP_ID from iCloud
deep-env sync . # Generate .env.local
```

### 9. Add to Claude GitHub Sync Workflow
**File:** `~/.claude/skills/github-sync/git-sync-check.sh`

Add Journal environment sync after the git checks (around line 80, before the "All checks complete" message):

```bash
# Sync Journal environment if needed
if [[ -d "$HOME/Journal/web" ]]; then
  if [[ ! -f "$HOME/Journal/web/.env.local" ]] || ! grep -q "WEBAUTHN_RP_ID" "$HOME/Journal/web/.env.local" 2>/dev/null; then
    echo "Syncing Journal environment configuration..."
    deep-env sync "$HOME/Journal/web" || echo "Warning: Failed to sync Journal env"
  fi
fi
```

This ensures every Mac automatically has the correct WebAuthn configuration at session start.

## Critical Files
- `/Users/andrewwilkinson/Journal/web/lib/auth.ts` - WebAuthn implementation (modify to accept multiple origins)
- `/Users/andrewwilkinson/Journal/web/.env.local` - Environment configuration
- `/Users/andrewwilkinson/Journal/web/.env.example` - Documentation
- `~/.claude/skills/github-sync/git-sync-check.sh` - Add auto-sync for Journal

## Verification

### Test Code Changes
Check that auth.ts correctly defines ORIGINS array:
```bash
cd /Users/andrewwilkinson/Journal/web
grep -A 3 "const ORIGINS" lib/auth.ts
# Should show array with both origins
```

### Test Authentication on Both Domains
1. On Mac A after deployment:
   - Navigate to `https://journal.software/login`
   - Register new passkey (should succeed)
2. On same Mac A:
   - Navigate to `https://www.journal.software/login`
   - Sign in with passkey (should succeed - no origin error)
3. On Mac B (after deep-env sync):
   - Navigate to `https://journal.software/login`
   - Sign in with same passkey from iCloud Keychain (should succeed)
4. On Mac B:
   - Navigate to `https://www.journal.software/login`
   - Sign in with passkey (should succeed)

### Verify Environment Variables
```bash
cd /Users/andrewwilkinson/Journal/web
cat .env.local | grep WEBAUTHN
# Should show: WEBAUTHN_RP_ID=journal.software
```

### Verify Auto-Sync on New Mac
1. Open Claude Code on a Mac that doesn't have Journal configured
2. Daily sync check should detect missing Journal .env.local
3. Should automatically run: `deep-env sync ~/Journal/web`
4. Verify .env.local created with WEBAUTHN_RP_ID

## Security Notes
- RP_ID must be a valid domain suffix (no protocol, no paths)
- RP_ID set to `journal.software` allows both that domain and www subdomain
- Origins array includes explicit protocol (https://)
- RP_ID determines passkey scope - cannot be changed without re-registering
- Passkeys in iCloud Keychain sync automatically across devices signed into same Apple ID
- Multiple origins in verification array is standard WebAuthn security practice
