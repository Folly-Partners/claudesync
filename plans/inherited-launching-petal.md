# Deep Personality - Comprehensive Bug Testing Plan

**Goal:** Battle test Deep Personality for public launch
**Live URL:** https://deeppersonality.app
**Status:** Pre-launch security & functionality audit

---

## Executive Summary

Deep Personality is a sophisticated psychological assessment platform with 18 clinically validated instruments, AI-powered analysis via Claude, Stripe payments, and Supabase backend. This plan covers comprehensive testing across all critical areas.

---

## Phase 1: Run Existing Test Suites

### 1.1 Unit Tests (Jest)
```bash
cd ~/Deep-Personality && npm test
```
- [ ] Run full test suite
- [ ] Check coverage report (`npm run test:coverage`)
- [ ] Flag any failing tests

### 1.2 E2E Tests (Playwright)
```bash
cd ~/Deep-Personality && npm run test:e2e
```
- [ ] Run all E2E specs (auth, assessment, sharing, home)
- [ ] Test across browsers (Chrome, Firefox, Safari)
- [ ] Test mobile viewports (iPhone, Pixel, iPad)

---

## Phase 2: Live Browser Testing (Browserbase)

### 2.1 Landing Page & Navigation
- [ ] Page loads correctly
- [ ] CTA buttons visible and functional
- [ ] Dark mode toggle works
- [ ] Mobile responsive layout
- [ ] EU geo-blocking redirects to /unavailable

### 2.2 Authentication Flows
- [ ] Sign up modal opens/closes
- [ ] Email validation works
- [ ] Google OAuth flow
- [ ] Magic link authentication
- [ ] Guest mode (no auth required)
- [ ] Session persistence across page reloads

### 2.3 Assessment Wizard
- [ ] Name field required validation
- [ ] All 18 sections load correctly
- [ ] Likert scales function (1-5 selection)
- [ ] Progress saves to localStorage
- [ ] Progress survives page reload
- [ ] Section completion celebrations
- [ ] Milestone achievements (25%, 50%, 75%, 100%)
- [ ] Restart confirmation modal
- [ ] Time estimates accurate

### 2.4 AI Analysis & Dashboard
- [ ] Streaming response displays in real-time
- [ ] Cache hit returns saved analysis
- [ ] All visualizations render (15+ charts)
- [ ] Table of contents navigation
- [ ] Markdown renders correctly with icons
- [ ] Crisis resources appear when mental health flags triggered
- [ ] PDF export works

### 2.5 Profile Sharing
- [ ] Create share link with password
- [ ] Share link expires correctly
- [ ] Password verification works
- [ ] Public view accessible without auth
- [ ] Rate limiting on password attempts (10/min)

### 2.6 Payments (Stripe)
- [ ] Checkout button initiates Stripe
- [ ] Test card processing
- [ ] Webhook handling
- [ ] Premium content unlocks after payment
- [ ] Promo code redemption

---

## Phase 3: Security Audit

### 3.1 Rate Limiting Verification
| Endpoint | Limit | Test |
|----------|-------|------|
| `/api/analyze` | 5/min | Hammer with 10 requests |
| `/api/share/verify` | 10/min | Brute force password |
| `/api/checkout` | 5/min | Spam checkout requests |
| `/api/user/delete` | 3/min | Test deletion limit |

### 3.2 CSRF Protection
- [ ] State-changing requests require Origin/Referer
- [ ] API key requests bypass CSRF (as designed)
- [ ] Webhook endpoints accept external calls

### 3.3 Input Validation
- [ ] SQL injection attempts blocked
- [ ] XSS in profile name/email sanitized
- [ ] Oversized payloads rejected
- [ ] Invalid JSON returns 400

### 3.4 Authentication Bypass
- [ ] Protected endpoints require auth
- [ ] Admin endpoints require ADMIN_EMAILS match
- [ ] API_SECRET_KEY validated in production
- [ ] Service role client only used server-side

### 3.5 Data Privacy
- [ ] Dark Triad hidden from casual users
- [ ] User deletion removes all data
- [ ] Audit logs anonymize deleted users
- [ ] Share links don't expose full profile

---

## Phase 4: Edge Cases & Error Handling

### 4.1 Network Failures
- [ ] Offline mode graceful degradation
- [ ] API timeout handling
- [ ] Partial response recovery (streaming)
- [ ] Retry logic for failed requests

### 4.2 Data Integrity
- [ ] Incomplete assessment handling
- [ ] Missing required fields
- [ ] Corrupted localStorage recovery
- [ ] Database constraint violations

### 4.3 Browser Compatibility
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile Safari
- [ ] Mobile Chrome

---

## Phase 5: Performance Testing

### 5.1 Load Times
- [ ] Initial page load < 3s
- [ ] Assessment navigation < 500ms
- [ ] AI streaming starts < 5s
- [ ] Dashboard renders < 2s

### 5.2 Resource Usage
- [ ] Memory usage reasonable
- [ ] No memory leaks on long sessions
- [ ] localStorage not exceeding limits

---

## Issues Tracking

### 🔴 Critical (Must Fix Before Launch)
| Issue | Location | Status |
|-------|----------|--------|
| TBD | TBD | Pending |

### 🟠 High Priority (Should Fix)
| Issue | Location | Status |
|-------|----------|--------|
| TBD | TBD | Pending |

### 🟡 Medium Priority (Nice to Fix)
| Issue | Location | Status |
|-------|----------|--------|
| TBD | TBD | Pending |

### 🟢 Low Priority / Cosmetic
| Issue | Location | Status |
|-------|----------|--------|
| TBD | TBD | Pending |

---

## Known Concerns from Code Review

### Potential Issues Identified During Exploration:

1. **Race condition in rate limiting** - In-memory cache + DB could allow burst attacks
2. **Cache invalidation missing** - Deleted user data may persist in analysis_cache
3. **Markdown→HTML converter** - Custom regex-based, potential XSS vectors
4. **No startup env validation** - Missing vars only surface at runtime
5. **Email failures silent** - User doesn't know if confirmation email failed

---

## Execution Order

1. **Start dev server** or use live site
2. **Run Jest unit tests** - catch obvious regressions
3. **Run Playwright E2E** - test critical flows
4. **Browserbase manual testing** - edge cases & UX
5. **Security probing** - rate limits, auth bypass, injection
6. **Document all issues** with severity ratings

---

## Files to Modify (If Fixes Needed)

- `middleware.ts` - Rate limiting, security headers
- `app/api/analyze/route.ts` - AI streaming, caching
- `app/api/complete/route.ts` - Email generation, profile save
- `app/api/share/verify/route.ts` - Password verification
- `app/api/user/delete/route.ts` - Data deletion
- `services/analyze/cache.ts` - Cache invalidation
- `components/Wizard.tsx` - Assessment flow
- `components/Dashboard.tsx` - Results display
