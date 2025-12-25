# Penetration Test: Deep Personality Security Vulnerabilities

## Executive Summary

Adversarial security analysis of Deep Personality, thinking like an attacker trying to extract test results or embarrass the developer. **14 vulnerabilities identified** across authentication, authorization, rate limiting, and data exposure.

**Attacker's Prize:** Sensitive psychological data including personality assessments, Dark Triad scores, mental health screenings (GAD-7, PHQ-9, PCL-5), and ADHD results.

---

## Critical Vulnerabilities (Fix Immediately)

### 1. IDOR Bug - Shared Profiles Not Deleted on Account Deletion
**File:** `app/api/user/delete/route.ts:50-54`
**Impact:** User data persists after account deletion (GDPR violation)

```typescript
// BUG: Wrong column name!
.eq('created_by', userId)  // ❌ Should be 'created_by_user_id'
```

**Fix:** Change to `.eq('created_by_user_id', userId)`

---

### 2. Error Messages Leak Internal Details
**Files:** Multiple API routes expose `error.message` to clients
- `app/api/share/route.ts:295`
- `app/api/partners/route.ts:39`
- `app/api/complete/route.ts:401`
- `app/api/generate-card/route.ts:253`
- `app/api/analyze/route.ts:1856`

**Attack:** Trigger errors to learn database structure, file paths, API patterns

**Fix:** Return generic `{ error: 'Internal server error' }` in all catch blocks

---

### 3. Hardcoded Promo Codes
**File:** `app/api/promo/route.ts:7`

```typescript
const VALID_PROMO_CODES = ['ANDREWFRIEND', 'ULTRATHINK'];  // ❌ EXPOSED!
```

**Attack:** Anyone with repo access gets unlimited free unlocks. No rate limiting.

**Fix:** Move to database with expiry dates, usage limits, and rate limiting

---

### 4. Rate Limiting Bypass via IP Spoofing
**File:** `middleware.ts:68-88`

```typescript
const forwardedFor = request.headers.get('x-forwarded-for');  // ❌ SPOOFABLE
```

**Attack:** Set custom `x-forwarded-for` header to bypass all rate limits:
```bash
curl -H "x-forwarded-for: 1.2.3.4" https://deeppersonality.app/api/share/verify
# Change IP each request = unlimited attempts
```

**Fix:** Only trust `x-vercel-forwarded-for` (Vercel validates this header)

---

### 5. Middleware Fails Open
**File:** `middleware.ts:204-211`

If Supabase is unavailable, rate limiting is **completely disabled**:
```typescript
if (!supabase) {
  return addSecurityHeaders(NextResponse.next());  // ❌ ALLOWS REQUEST
}
```

**Attack:** Wait for Supabase outage, then brute-force passwords or spam expensive AI endpoints

**Fix:** Fail closed - return 503 Service Unavailable when rate limiting can't be verified

---

## High Vulnerabilities

### 6. Missing Authentication on generate-card
**File:** `app/api/generate-card/route.ts:145`

Endpoint accepts ANY profile data without authentication:
```typescript
export async function POST(req: Request) {
  const { profile, cardType } = await req.json();
  // NO AUTH CHECK - processes profile immediately
```

**Attack:** Generate cards for any profile, enumerate data structures

**Fix:** Add `supabase.auth.getUser()` check

---

### 7. Email-Only Admin Authentication
**File:** `app/api/admin/profiles/route.ts:6-12`

```typescript
const ADMIN_EMAILS = process.env.ADMIN_EMAILS?.split(',')...
function isAdmin(email) { return ADMIN_EMAILS.includes(email); }
```

**Attack:** If email verification is disabled in Supabase, register as admin@yourdomain.com

**Fix:** Implement proper RBAC with Supabase roles, require verified emails + MFA for admins

---

### 8. Dark Triad Exposure in Shared Profiles
**File:** `app/api/share/route.ts:55-75`

Users can share Dark Triad scores (Machiavellianism, Narcissism, Psychopathy) with the world.

**Attack:** Social engineering - "Hey, share your profile with me" then screenshot embarrassing scores

**Fix:** Disable Dark Triad sharing entirely, or require explicit consent with warning

---

### 9. Session Not Invalidated After Account Deletion
**File:** `app/api/user/delete/route.ts:92`

```typescript
await supabase.auth.signOut()  // No verification this succeeded
```

**Attack:** Steal session token, delete account, continue accessing "deleted" data

**Fix:** Verify signOut succeeded, revoke all sessions server-side

---

## Medium Vulnerabilities

### 10. CSRF Protection Allows Missing Headers
**File:** `middleware.ts:158-176`

Allows requests with no Origin AND no Referer header:
```typescript
} else {
  return { valid: true };  // ❌ ALLOWS MISSING HEADERS
}
```

**Fix:** Require at least one header for state-changing requests

### 11. Debug Logging Exposes User IDs
**File:** `app/api/profiles/route.ts:166-173`

```typescript
logServerEvent(`🔍 Profile check: ${JSON.stringify({
    authUserId: user.id,  // ❌ User IDs in logs
    profileUserId: existingProfile?.user_id,
})}`);
```

**Fix:** Redact or hash sensitive identifiers in logs

### 12. No Input Validation
**File:** `app/api/generate-card/route.ts:145-178`

Accepts arbitrary JSON without schema validation. Could crash with malformed data or DoS with huge payloads.

**Fix:** Add Zod validation on all endpoints

### 13. Weak Share Password Requirements
**File:** `app/api/share/route.ts:12`

Only requires 8 characters, no complexity. Allows `12345678`.

**Fix:** Require uppercase + number + special character

### 14. Authorization Check Pattern Leaks Existence
**File:** `app/api/profiles/route.ts:160-164`

```typescript
// Fetches profile THEN checks ownership
const { data: existingProfile } = await supabase
  .from('profiles')
  .select('id, user_id, name')
  .eq('id', profileId)  // ❌ No user_id filter
  .single();
```

**Fix:** Always include `.eq('user_id', user.id)` in the query itself

---

## Attack Scenarios

### Scenario 1: Extract Stranger's Psychology Profile
1. Find shared profile link (social engineering or guessing 16-char codes)
2. If no password, instant access to personality data
3. If password exists, brute force via IP spoofing (bypass rate limits)
4. Screenshot Dark Triad scores, ADHD results, mental health data

### Scenario 2: Embarrass the Developer
1. Clone repo, find promo codes `ANDREWFRIEND`, `ULTRATHINK`
2. Create script to redeem for 1000 fake emails
3. Post on social media "Free Deep Personality for everyone!"
4. Developer loses revenue, reputation damage

### Scenario 3: Data Persistence Attack (GDPR)
1. Create account, complete all assessments
2. Share profile publicly
3. Delete account
4. Shared profile remains accessible (bug #1)
5. Report GDPR violation to authorities

---

## Implementation Priority

### Phase 1: Critical Fixes (Do First)
| # | Vulnerability | File | LOE |
|---|---------------|------|-----|
| 1 | IDOR column name bug | `api/user/delete/route.ts` | 5 min |
| 2 | Error message leakage | Multiple files | 30 min |
| 3 | Hardcoded promo codes | `api/promo/route.ts` | 1 hr |
| 4 | Rate limit IP spoofing | `middleware.ts` | 30 min |
| 5 | Middleware fail-open | `middleware.ts` | 15 min |

### Phase 2: High Priority
| # | Vulnerability | File | LOE |
|---|---------------|------|-----|
| 6 | generate-card auth | `api/generate-card/route.ts` | 15 min |
| 7 | Admin email-only auth | `api/admin/profiles/route.ts` | 1 hr |
| 8 | Dark Triad sharing | `api/share/route.ts` | 30 min |
| 9 | Session invalidation | `api/user/delete/route.ts` | 30 min |

### Phase 3: Medium Priority
| # | Vulnerability | File | LOE |
|---|---------------|------|-----|
| 10-14 | CSRF, logging, validation, passwords, auth pattern | Various | 2 hr |

---

## Files to Modify

```
app/api/user/delete/route.ts      # Fix IDOR bug, session invalidation
app/api/share/route.ts            # Error handling, Dark Triad, password strength
app/api/partners/route.ts         # Error handling
app/api/complete/route.ts         # Error handling
app/api/generate-card/route.ts    # Add auth, error handling
app/api/analyze/route.ts          # Error handling
app/api/promo/route.ts            # Move codes to DB, add rate limiting
app/api/profiles/route.ts         # Fix auth pattern, reduce logging
app/api/admin/profiles/route.ts   # Improve admin auth
middleware.ts                      # Fix IP handling, fail-closed, CSRF
```

---

## Positive Findings (Already Secure)

- Stripe webhook signature verification
- bcrypt password hashing (12 rounds)
- SQL injection prevention (Supabase SDK)
- XSS protection in markdown converter
- Proper ownership checks on most endpoints
- Share codes are 16-char random (hard to guess)
