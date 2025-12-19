# Deep Personality - Public Launch Readiness Plan

## Overview
Comprehensive testing, bug fixing, code review, and security hardening before opening to public users.

**Priority Levels:**
- **P0 (BLOCKING)**: Must fix before any public access - security/data loss risks
- **P1 (CRITICAL)**: Fix within first week - major UX/reliability issues
- **P2 (IMPORTANT)**: Fix within first month - code quality/maintainability
- **P3 (NICE-TO-HAVE)**: Post-launch improvements

---

## Phase 1: Security Hardening (P0)

### 1.1 Password Security - CRITICAL
**File:** `/app/api/share/route.ts` (lines 18-24)
**Issue:** Uses SHA-256 for password hashing (vulnerable to GPU attacks)
**Fix:** Replace with bcrypt (12 rounds)
```typescript
import bcrypt from 'bcrypt';
const hash = await bcrypt.hash(password, 12);
const isValid = await bcrypt.compare(password, storedHash);
```

### 1.2 API Authentication - CRITICAL
**File:** `/app/api/analyze/route.ts` (lines 77-81), `/app/api/complete/route.ts`
**Issue:** `API_SECRET_KEY` check is optional (bypassed if env var not set)
**Fix:** Make authentication required; fail closed
```typescript
if (!API_SECRET_KEY) {
  return new Response("Server misconfiguration", { status: 500 });
}
if (!authHeader || authHeader !== API_SECRET_KEY) {
  return new Response("Unauthorized", { status: 401 });
}
```

### 1.3 Admin Access Control
**File:** `/app/api/admin/profiles/route.ts` (line 5)
**Issue:** Hardcoded admin email in source code
**Fix:** Move to environment variable `ADMIN_EMAILS` (comma-separated list)

### 1.4 Input Validation
**File:** `/app/api/share/route.ts` (lines 93-100)
**Fix:** Add validation for:
- Profile size limit (5MB max)
- Password minimum length (8+ chars)
- expiresInDays range (1-365)
- visibleSections whitelist

### 1.5 Security Headers
**File:** `middleware.ts` or `next.config.js`
**Add:**
- Content-Security-Policy
- Strict-Transport-Security
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY

### 1.6 Share Link Security
**File:** `/app/api/share/route.ts`
**Issues:**
- Password sent in URL query string (exposed in logs/history)
- Share code only 8 chars (48-bit entropy)
**Fix:**
- Change password verification to POST request
- Increase share code to 16 characters

---

## Phase 2: Critical Bug Fixes (P1)

### 2.1 Mental Health Crisis Protocol
**File:** `/app/api/analyze/route.ts`, `/components/Dashboard.tsx`
**Issue:** PHQ-9 suicidal ideation flag exists but no crisis intervention
**Fix:**
- Display crisis resources (988 Lifeline, Crisis Text) when flag triggered
- Add disclaimer that assessment is educational only
- Require acknowledgment checkbox

### 2.2 Error Boundaries
**File:** `/app/layout.tsx` or new `/components/ErrorBoundary.tsx`
**Issue:** Single component error crashes entire app
**Fix:** Wrap main content in React error boundary with graceful fallback

### 2.3 Race Condition Fixes
**File:** `/components/Dashboard.tsx` (lines 1795-1940)
**Issue:** Multiple "Analyze" clicks cause concurrent fetches, state collisions
**Fix:**
- Add AbortController to cancel previous request
- Disable button during analysis
- Track in-flight request state

### 2.4 localStorage Robustness
**File:** `/components/Wizard.tsx`
**Issues:**
- No size validation before saving
- No cleanup mechanism
- Corruption causes silent fallback
**Fix:**
- Add try-catch with user notification on corruption
- Implement storage quota check
- Add "Clear Progress" button visible when issues detected

### 2.5 Streaming Error Handling
**File:** `/components/Dashboard.tsx` (lines 1818-1940)
**Issue:** Stream close/network failure shows spinner indefinitely
**Fix:**
- Add timeout (60s) with "Taking longer than expected" message
- Detect connection loss and show retry button
- Handle partial results gracefully

---

## Phase 3: Code Quality (P2)

### 3.1 TypeScript Strict Mode
**File:** `/tsconfig.json`
**Issue:** `"strict": false` disables type checking
**Fix:** Enable strict mode and fix resulting type errors

### 3.2 Remove Console Logging
**Files:** All `/app/api/` routes
**Issue:** `console.log/error/warn` leak to Vercel logs
**Fix:** Replace with `logServerEvent()` from `/services/logger.ts`

### 3.3 Replace `any` Types
**Files:** Multiple API routes, Wizard.tsx, Dashboard.tsx
**Fix:** Create proper TypeScript interfaces:
- `Profile` interface
- `Assessment` interface
- `DarkTriad` interface
- `AnalysisResponse` interface

### 3.4 Component Decomposition
**Files:**
- `/components/Wizard.tsx` (1098 lines)
- `/components/Dashboard.tsx` (2900+ lines)
**Fix:** Extract into smaller components:
- WizardStep components
- AnalysisSection component
- ShareModal component
- ProfileCard component

### 3.5 Environment Validation
**File:** New `/lib/env.ts`
**Fix:** Validate required env vars at startup:
```typescript
const requiredVars = ['ANTHROPIC_API_KEY', 'SUPABASE_SERVICE_ROLE_KEY', ...];
requiredVars.forEach(v => {
  if (!process.env[v]) throw new Error(`Missing required env: ${v}`);
});
```

---

## Phase 4: Automated Testing (P1)

### 4.0 Test Infrastructure Setup
**New Files:**
- `jest.config.js` - Jest configuration for Next.js
- `jest.setup.ts` - Test setup with mocks
- `playwright.config.ts` - Playwright E2E config
- `__tests__/` - Test directory structure

**Dependencies to Add:**
```bash
npm install -D jest @testing-library/react @testing-library/jest-dom @types/jest jest-environment-jsdom
npm install -D playwright @playwright/test
npm install -D msw # Mock Service Worker for API mocking
```

**package.json scripts:**
```json
"test": "jest",
"test:watch": "jest --watch",
"test:coverage": "jest --coverage",
"test:e2e": "playwright test",
"test:e2e:ui": "playwright test --ui"
```

---

### 4.1 API Route Tests
**File:** `__tests__/api/share.test.ts`
```typescript
// Test cases:
- POST /api/share - creates share link successfully
- POST /api/share - validates password minimum length
- POST /api/share - validates expiresInDays range (1-365)
- POST /api/share - rejects oversized profiles (>5MB)
- POST /api/share - requires authentication
- GET /api/share/[code] - returns profile for valid code
- GET /api/share/[code] - returns 404 for invalid code
- GET /api/share/[code] - returns 410 for expired link
- POST /api/share/verify - validates password correctly
- POST /api/share/verify - rejects wrong password
```

**File:** `__tests__/api/analyze.test.ts`
```typescript
// Test cases:
- POST /api/analyze - requires API_SECRET_KEY header
- POST /api/analyze - returns 500 if API_SECRET_KEY not configured
- POST /api/analyze - returns 401 for missing/wrong auth
- POST /api/analyze - validates profile structure
- POST /api/analyze - handles streaming response
```

**File:** `__tests__/api/admin.test.ts`
```typescript
// Test cases:
- GET /api/admin/profiles - requires authentication
- GET /api/admin/profiles - returns 403 for non-admin users
- GET /api/admin/profiles - returns profiles for admin users
- Admin email list from ADMIN_EMAILS env var works
```

---

### 4.2 Component Unit Tests
**File:** `__tests__/components/AuthModal.test.tsx`
```typescript
// Test cases:
- Renders sign in form by default
- Switches to sign up mode
- Switches to magic link mode
- Shows validation errors for empty fields
- Shows loading state during submission
- Calls onSuccess after successful auth
- Closes on backdrop click
- Closes on X button click
```

**File:** `__tests__/components/Wizard.test.tsx`
```typescript
// Test cases:
- Renders welcome step initially
- Progresses through assessment steps
- Saves progress to localStorage
- Restores progress from localStorage
- Handles localStorage corruption gracefully
- Validates required name field
- Shows correct button based on completion state
- Handles rapid Next button clicks (debounce)
```

**File:** `__tests__/components/Dashboard.test.tsx`
```typescript
// Test cases:
- Displays profile information correctly
- Shows analysis loading state
- Handles analysis streaming
- Aborts analysis on component unmount
- Shows error state on analysis failure
- Displays crisis resources when PHQ-9 flag triggered
- Share modal opens and closes correctly
```

---

### 4.3 Integration Tests
**File:** `__tests__/integration/auth-flow.test.ts`
```typescript
// Test cases:
- Email/password sign up creates account
- Email/password sign in authenticates
- Wrong password shows error
- Sign out clears session
- Guest completes assessment, then signs up (data preserved)
```

**File:** `__tests__/integration/assessment-flow.test.ts`
```typescript
// Test cases:
- Complete assessment start to finish
- Progress persists across page reload
- Returning user with results sees dashboard
- Assessment data saved to profile correctly
```

---

### 4.4 E2E Tests (Playwright)
**File:** `e2e/auth.spec.ts`
```typescript
// Test cases:
- Sign up with email/password
- Sign in with email/password
- Sign out and sign back in
- Magic link flow (with email interceptor)
```

**File:** `e2e/assessment.spec.ts`
```typescript
// Test cases:
- Complete full assessment (automated clicking)
- Progress bar updates correctly
- Can navigate back to previous sections
- Completion triggers results display
```

**File:** `e2e/sharing.spec.ts`
```typescript
// Test cases:
- Create share link without password
- Create share link with password
- Access share link successfully
- Password protection works
- Expired link shows error
```

**File:** `e2e/mobile.spec.ts`
```typescript
// Viewport tests:
- iPhone SE (375x667) - all modals fit
- iPhone 14 Pro (393x852) - navigation works
- iPad (768x1024) - layout responsive
- Touch targets are 44px minimum
```

---

### 4.5 Security Tests
**File:** `__tests__/security/input-validation.test.ts`
```typescript
// Test cases:
- XSS payloads in name field are sanitized
- SQL injection attempts are rejected
- Oversized payloads are rejected
- Invalid JSON is handled gracefully
```

**File:** `__tests__/security/auth.test.ts`
```typescript
// Test cases:
- Bcrypt password hashing used (not SHA-256)
- Password timing attacks mitigated
- Session tokens are secure
- CSRF protection active
```

---

### 4.6 Test Utilities
**File:** `__tests__/utils/test-helpers.ts`
```typescript
// Helpers:
- createMockProfile() - generates test profile data
- createMockUser() - generates test user
- mockSupabaseClient() - mocks Supabase calls
- mockAnthropicAPI() - mocks Claude API responses
```

**File:** `__tests__/utils/msw-handlers.ts`
```typescript
// MSW handlers for:
- /api/analyze (mock streaming response)
- /api/share (mock share creation)
- Supabase auth endpoints
```

---

### 4.7 CI/CD Integration
**File:** `.github/workflows/test.yml`
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npm run test:coverage
      - run: npx playwright install --with-deps
      - run: npm run test:e2e
```

---

### Test Coverage Targets
| Area | Target |
|------|--------|
| API Routes | 90%+ |
| Security functions | 100% |
| Auth flows | 85%+ |
| UI Components | 70%+ |
| E2E critical paths | 100% |

---

## Phase 5: Documentation (P3)

### 5.1 Privacy Policy
**File:** `/app/privacy/page.tsx`
**Add:** Complete privacy policy covering:
- Data collection (psychological assessments)
- Data storage (Supabase)
- Third-party sharing (Anthropic API)
- Retention periods
- User rights (deletion, export)

### 5.2 Terms of Service
**File:** `/app/terms/page.tsx`
**Add:** Terms including:
- Assessment is educational, not clinical
- No medical/professional advice
- User responsibility for data sharing

### 5.3 Crisis Resources
**Add visible link/section:**
- 988 Suicide & Crisis Lifeline
- Crisis Text Line (741741)
- International resources

---

## Files to Modify (Summary)

| Priority | File | Changes |
|----------|------|---------|
| P0 | `/app/api/share/route.ts` | bcrypt, validation, POST for password |
| P0 | `/app/api/analyze/route.ts` | Required auth, logging |
| P0 | `/app/api/admin/profiles/route.ts` | Env var for admin email |
| P0 | `middleware.ts` | Security headers |
| P1 | `/components/Dashboard.tsx` | Error boundary, abort controller, crisis protocol |
| P1 | `/components/Wizard.tsx` | localStorage handling, error states |
| P1 | `jest.config.js` | New - Jest configuration |
| P1 | `playwright.config.ts` | New - E2E test configuration |
| P1 | `__tests__/api/*.test.ts` | New - API route tests |
| P1 | `__tests__/components/*.test.tsx` | New - Component unit tests |
| P1 | `__tests__/security/*.test.ts` | New - Security tests |
| P1 | `e2e/*.spec.ts` | New - Playwright E2E tests |
| P1 | `.github/workflows/test.yml` | New - CI/CD test pipeline |
| P2 | `tsconfig.json` | Enable strict mode |
| P2 | All API routes | Replace console.* with logServerEvent |
| P2 | New interfaces file | TypeScript interfaces |
| P3 | `/app/privacy/page.tsx` | Full privacy policy |
| P3 | `/app/terms/page.tsx` | Full terms of service |

---

## Estimated Effort

| Phase | Effort | Risk if Skipped |
|-------|--------|-----------------|
| Phase 1 (Security) | 4-6 hours | Data breach, account compromise |
| Phase 2 (Bug Fixes) | 3-4 hours | User data loss, crashes |
| Phase 3 (Code Quality) | 6-8 hours | Technical debt, harder maintenance |
| Phase 4 (Automated Testing) | 8-10 hours | Unknown bugs, regressions |
| Phase 5 (Documentation) | 2-3 hours | Legal/compliance risk |

**Total: ~25-30 hours for complete launch readiness**

**Testing ROI:** Automated tests add ~6 hours upfront but save 10x that in manual testing for every release. Tests catch regressions automatically and serve as documentation.

---

## Recommended Approach

1. **Day 1**: Phase 4 Test Infrastructure (setup Jest, Playwright, mocks)
2. **Day 2**: Phase 1 Security + write security tests as we go
3. **Day 3**: Phase 2 Bug Fixes + write component/integration tests
4. **Day 4**: Complete E2E tests + Phase 3 Code Quality
5. **Pre-launch**: Phase 5 Documentation + final test run

**Why tests first?** Writing tests alongside fixes catches issues immediately and ensures nothing breaks as we make changes. Security tests verify our hardening actually works.
