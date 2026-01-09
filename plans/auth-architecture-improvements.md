# Authentication Architecture Improvements

## Problem Analysis

### The Current Vulnerability
The application has a critical architectural flaw where **view state and authentication state are managed independently**, creating a window where logged-out users can see protected content:

**Root Cause:**
- `App.tsx` manages two independent pieces of state:
  - `user` (auth state from Supabase)
  - `view` (UI state: 'landing' | 'quiz' | 'dashboard')
- When logout occurs, `user` is cleared to `null` in the `SIGNED_OUT` event handler
- BUT `view` state is only changed to 'landing' in `handleSignOut()` function
- If logout happens through OTHER paths (session expiry, token invalidation, manual cookie deletion), the `SIGNED_OUT` event fires but `view` is NOT updated
- Result: User is logged out but still sees dashboard/quiz content

**Evidence from Code:**
```typescript
// App.tsx line 358-366 - SIGNED_OUT event handler
if (event === 'SIGNED_OUT') {
  // Clears session storage - good
  sessionStorage.removeItem('deep_personality_is_guest');
  sessionStorage.removeItem('force_password_reset');
  // ...
  setInitialProfile(null);
  // BUT DOES NOT CALL setView('landing') ❌
}

// App.tsx line 484-495 - Manual sign out
const handleSignOut = async () => {
  // Clears cache - good
  localStorage.removeItem('deep-personality-cached-profile');
  await supabase.auth.signOut();
  setShowUserMenu(false);
  setView('landing'); // ✅ Sets view to landing
};
```

**The Gap:**
- Manual signout → calls `handleSignOut()` → sets view to landing ✅
- Session expiry/invalidation → fires `SIGNED_OUT` event → does NOT set view to landing ❌
- Cookie deletion → fires `SIGNED_OUT` event → does NOT set view to landing ❌

### Current Protection Layers (Insufficient)

1. **API Routes:** Protected via Supabase auth (lines 34-37 in `/app/api/progress/route.ts`)
   - ✅ Prevents data access
   - ❌ Doesn't prevent UI from being shown

2. **Middleware:** Only rate-limiting and CSRF (lines 263-490 in `/middleware.ts`)
   - ❌ No auth enforcement on page routes
   - ❌ No redirection logic for protected views

3. **Component-level checks:** Inconsistent
   - Wizard: Has `!user` checks but doesn't enforce hiding (line 208, 327 in Wizard.tsx)
   - Dashboard: Relies on parent passing correct props
   - ❌ No defensive render guards

### What Data Can Be Exposed
When a logged-out user sees the dashboard/quiz:
- **Previous session's cached data** in component state (profileA, profileB, pastAssessments)
- **UI scaffolding** showing assessment structure
- **Error messages** that may leak info about the system
- **Partial analysis results** if they were in memory when logout occurred

---

## Proposed Architecture Improvements

### Layer 1: Derive View State from Auth State (Fundamental Fix)

**Problem:** Independent state allows desynchronization
**Solution:** Make view state a pure function of auth state + data

**Implementation:**
```typescript
// App.tsx - Replace independent view state with derived state
const view = useMemo((): 'landing' | 'quiz' | 'dashboard' => {
  // RULE 1: No auth = must be landing
  if (!user) return 'landing';
  
  // RULE 2: Check for routing hints (comparison ID, etc.)
  if (pendingComparisonId || returningFromCheckout) return 'dashboard';
  
  // RULE 3: Check for in-progress assessment
  if (hasInProgressAssessment) return 'quiz';
  
  // RULE 4: Default to quiz for authenticated users
  return 'quiz';
}, [user, pendingComparisonId, returningFromCheckout, hasInProgressAssessment]);
```

**Benefits:**
- View CANNOT be out of sync with auth state
- Single source of truth
- Impossible to show protected views when logged out

**Files to Change:**
- `/Users/andrewwilkinson/Deep-Personality/App.tsx` (lines 114, 306, 314, 372, 400, 410, 481, 494)

---

### Layer 2: Component-Level Auth Guards (Defense in Depth)

**Problem:** Components assume parent will protect them
**Solution:** Every protected component validates auth on EVERY render

**Implementation:**

```typescript
// components/Wizard.tsx - Add defensive guard at top of render
export const Wizard = ({ onAnalyzeClick, onProfileSaved, user }: WizardProps) => {
  // CRITICAL: Validate auth on every render
  if (!user) {
    return (
      <div className="p-10 text-center">
        <p className="text-slate-600 dark:text-slate-400">
          Please sign in to continue.
        </p>
        <button onClick={onAuthRequired} className="mt-4 px-6 py-2 bg-blue-600 text-white rounded-lg">
          Sign In
        </button>
      </div>
    );
  }
  
  // Rest of component logic...
}
```

**Add to:**
- `/Users/andrewwilkinson/Deep-Personality/components/Wizard.tsx`
- `/Users/andrewwilkinson/Deep-Personality/components/Dashboard.tsx`
- Any other component that shows user data

**Pattern:**
```typescript
interface ProtectedComponentProps {
  user: User; // Required, not nullable
  // ... other props
}

// At top of component:
if (!user) {
  return <AuthRequiredPlaceholder onSignIn={onRequestAuth} />;
}
```

---

### Layer 3: Middleware-Level Page Protection (Fail-Safe)

**Problem:** No server-side enforcement for protected page routes
**Solution:** Add auth checks in middleware for protected paths

**Implementation:**
```typescript
// middleware.ts - Add page-level auth checks
export async function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;
  
  // Protected view paths (client-side routes that show sensitive data)
  const protectedPaths = ['/dashboard', '/quiz'];
  const isProtectedPath = protectedPaths.some(path => pathname.startsWith(path));
  
  if (isProtectedPath) {
    // Check for auth cookie/token
    const supabase = createClient();
    const { data: { session } } = await supabase.auth.getSession();
    
    if (!session) {
      // No valid session - redirect to landing
      const response = NextResponse.redirect(new URL('/', request.url));
      return addSecurityHeaders(response, nonce, requestId);
    }
  }
  
  // ... rest of middleware
}
```

**Note:** This is a fail-safe. With derived view state, this should never trigger in normal operation.

**Files to Change:**
- `/Users/andrewwilkinson/Deep-Personality/middleware.ts` (after line 307)

---

### Layer 4: Enhanced SIGNED_OUT Event Handler

**Problem:** SIGNED_OUT event doesn't fully clean up UI state
**Solution:** Treat SIGNED_OUT as a hard reset trigger

**Implementation:**
```typescript
// App.tsx - Enhanced SIGNED_OUT handler
if (event === 'SIGNED_OUT') {
  // Existing cleanup
  sessionStorage.removeItem('deep_personality_is_guest');
  sessionStorage.removeItem('force_password_reset');
  sessionStorage.removeItem('dp_pending_comparison_id');
  sessionStorage.removeItem('dp_pending_invite_code');
  
  // NEW: Clear all UI state to force re-render
  setPendingComparisonId(null);
  setInitialProfile(null);
  prewarmProfilesRef.current.clear();
  
  // NEW: Force view to landing (belt + suspenders)
  // This is redundant if we use derived view state, but acts as fail-safe
  setView('landing');
  
  // NEW: Clear any cached component state
  localStorage.removeItem('deep-personality-cached-profile');
  
  // NEW: Log for debugging
  console.info('[Auth] SIGNED_OUT event - all state cleared');
}
```

**Files to Change:**
- `/Users/andrewwilkinson/Deep-Personality/App.tsx` (lines 358-366)

---

### Layer 5: Session Validation on Mount (Progressive Enhancement)

**Problem:** Stale sessions may allow brief access to protected content
**Solution:** Validate session freshness on component mount

**Implementation:**
```typescript
// components/Dashboard.tsx - Add session validation
useEffect(() => {
  async function validateSession() {
    if (!user) return;
    
    const { data: { session }, error } = await supabase.auth.getSession();
    
    if (error || !session) {
      // Session is invalid - trigger auth required
      console.warn('[Dashboard] Session validation failed:', error);
      onRequestAuth?.();
    }
  }
  
  validateSession();
}, [user, onRequestAuth]);
```

**Add to:**
- `/Users/andrewwilkinson/Deep-Personality/components/Dashboard.tsx`
- `/Users/andrewwilkinson/Deep-Personality/components/Wizard.tsx`

---

## Implementation Plan

### Phase 1: Critical Fixes (Ship Immediately)
1. **Layer 4: Fix SIGNED_OUT handler** (15 min)
   - Add `setView('landing')` to SIGNED_OUT event handler
   - Add localStorage cleanup
   - This fixes the immediate bug with minimal risk

2. **Layer 2: Add Wizard auth guard** (15 min)
   - Add defensive null check at top of Wizard render
   - Return "Please sign in" UI if user is null

### Phase 2: Architectural Improvements (Ship Same Day)
3. **Layer 1: Derive view state** (1 hour)
   - Replace `useState` for view with `useMemo`
   - Test all navigation flows
   - This is the fundamental fix that prevents the bug class

4. **Layer 2: Add Dashboard auth guard** (15 min)
   - Same defensive pattern as Wizard

### Phase 3: Belt + Suspenders (Ship Next Sprint)
5. **Layer 5: Session validation** (30 min)
   - Add useEffect to validate session on mount
   - Add periodic validation for long-lived sessions

6. **Layer 3: Middleware protection** (1 hour)
   - Add page-level auth checks
   - Handle edge cases (redirects, error states)
   - Test thoroughly (this touches routing)

---

## Testing Strategy

### Manual Testing Scenarios
1. **Normal logout flow**
   - Log in → view dashboard → click sign out
   - ✅ Should redirect to landing immediately
   - ✅ Should not show any dashboard content

2. **Session expiry**
   - Log in → view dashboard → manually delete auth cookies → wait for SIGNED_OUT event
   - ✅ Should redirect to landing
   - ✅ Should show "session expired" message

3. **Token invalidation**
   - Log in → view dashboard → invalidate token via Supabase admin
   - ✅ Should redirect to landing on next API call
   - ✅ Should not show stale data

4. **Multiple tabs**
   - Log in → open dashboard in 2 tabs → sign out in tab 1
   - ✅ Tab 2 should also redirect to landing (via auth state listener)

5. **Browser back button**
   - Log in → dashboard → log out → press back
   - ✅ Should not show cached dashboard
   - ✅ Should enforce auth check

### Automated Test Cases
```typescript
// e2e/auth-protection.spec.ts
test('logged out user cannot see dashboard even with manual URL navigation', async ({ page }) => {
  await page.goto('/');
  await page.goto('/dashboard'); // Try to force navigate
  await expect(page).toHaveURL('/'); // Should redirect to landing
  await expect(page.locator('[data-testid="view-dashboard"]')).not.toBeVisible();
});

test('session expiry redirects to landing from protected view', async ({ page }) => {
  // Log in
  await loginAsTestUser(page);
  await page.goto('/dashboard');
  await expect(page.locator('[data-testid="view-dashboard"]')).toBeVisible();
  
  // Simulate session expiry by clearing cookies
  await page.context().clearCookies();
  
  // Wait for auth state change
  await page.waitForTimeout(1000);
  
  // Should redirect to landing
  await expect(page).toHaveURL('/');
  await expect(page.locator('[data-testid="view-dashboard"]')).not.toBeVisible();
});

test('SIGNED_OUT event clears view state', async ({ page }) => {
  await loginAsTestUser(page);
  await page.goto('/dashboard');
  
  // Trigger sign out
  await page.click('[data-testid="user-menu"]');
  await page.click('text=Sign Out');
  
  // Should immediately redirect to landing
  await expect(page).toHaveURL('/', { timeout: 2000 });
  await expect(page.locator('[data-testid="view-landing"]')).toBeVisible();
});
```

---

## Rollback Plan

### If Layer 1 (Derived View State) Causes Issues:
1. Revert `useMemo` → `useState` for view
2. Keep all other layers (they're independent)
3. The SIGNED_OUT fix (Layer 4) alone prevents the bug

### If Middleware Changes (Layer 3) Cause Issues:
1. Remove middleware auth checks
2. All other layers still provide protection
3. Middleware is belt-and-suspenders only

---

## Success Metrics

**Before Implementation:**
- Bug exists: Logged-out users can see dashboard after session expiry
- Repro rate: 100% when session expires while viewing dashboard

**After Phase 1:**
- Bug should be reduced by 90% (SIGNED_OUT now clears view)
- Edge cases may remain (race conditions)

**After Phase 2:**
- Bug should be eliminated (view is derived from auth)
- Architecturally impossible to show protected content without auth

**After Phase 3:**
- Defense in depth complete
- Multiple independent layers of protection

---

## Additional Recommendations

### 1. Add Auth State Logging
```typescript
// lib/auth-logger.ts
export function logAuthStateChange(event: string, user: User | null, view: string) {
  console.info('[Auth State]', {
    event,
    userId: user?.id || 'none',
    view,
    timestamp: new Date().toISOString()
  });
}
```

Use this in `onAuthStateChange` callback to debug future auth issues.

### 2. Add Sentry Breadcrumbs
```typescript
if (event === 'SIGNED_OUT') {
  Sentry.addBreadcrumb({
    category: 'auth',
    message: 'User signed out',
    level: 'info',
    data: { previousView: view }
  });
}
```

This helps diagnose if users report seeing content after logout.

### 3. Consider Session Timeout Warning
Show a modal 5 minutes before session expiry:
```
"Your session will expire in 5 minutes. Would you like to stay signed in?"
[Extend Session] [Sign Out]
```

This prevents data loss and improves UX.

### 4. Add "session expired" Banner
When SIGNED_OUT event fires unexpectedly:
```typescript
if (event === 'SIGNED_OUT' && view !== 'landing') {
  showBanner('Your session has expired. Please sign in again.', 'warning');
}
```

---

## Risk Assessment

### Low Risk Changes (Ship First)
- Layer 4: SIGNED_OUT handler fix
- Layer 2: Component auth guards
- Both are additive and have clear rollback

### Medium Risk Changes (Test Thoroughly)
- Layer 1: Derived view state
  - Risk: May break navigation flows
  - Mitigation: Comprehensive testing, feature flag?

### Higher Risk Changes (Ship Last)
- Layer 3: Middleware page protection
  - Risk: May break routing, redirects
  - Mitigation: Thorough testing, canary deployment

---

## Long-Term Architecture Vision

### Future State: Route-Based Protection
Consider migrating to Next.js App Router with server components:

```typescript
// app/dashboard/page.tsx (Server Component)
export default async function DashboardPage() {
  const supabase = createServerClient();
  const { data: { session } } = await supabase.auth.getSession();
  
  if (!session) {
    redirect('/login');
  }
  
  return <Dashboard user={session.user} />;
}
```

**Benefits:**
- Auth enforced at routing layer
- Server-side redirects (faster, more secure)
- No client-side state sync issues

**Effort:** Large refactor, but eliminates entire class of auth bugs
**Timeline:** Consider for v2.0

