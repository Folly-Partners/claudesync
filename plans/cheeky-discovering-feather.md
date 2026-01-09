# Fix: Authentication Bug After Logout/Session Expiry

## Problem Summary

**Critical Bug**: After hitting "Restart from Scratch" mid-test (or when session expires), users are logged out but can still see the "Start My Profile" page and assessment content. This exposes protected UI and potentially cached data to unauthenticated users.

**Observed Behavior**:
- User clicks "Restart from Scratch" → session expires/clears
- Auth modal appears showing logged-out state
- But Wizard UI remains visible with "Start My Profile" button
- User sees assessment structure and any cached progress data

**Expected Behavior**:
- Logged-out users should ONLY see the landing page
- All protected content should be hidden immediately on logout

## Root Cause Analysis

The app manages authentication state (`user`) and view state (`view`) independently in App.tsx. This creates a race condition:

**File**: `App.tsx:358-366`

```typescript
if (event === 'SIGNED_OUT') {
  // Clears session storage ✓
  sessionStorage.removeItem('deep_personality_is_guest');
  sessionStorage.removeItem('force_password_reset');
  // ... more cleanup
  // ❌ MISSING: setView('landing')
}
```

**Compare to manual logout** (`App.tsx:484-495`):
```typescript
const handleSignOut = async () => {
  await supabase.auth.signOut();
  setView('landing'); // ✓ This DOES navigate
}
```

**The Gap**: Session expiry triggers `SIGNED_OUT` event but doesn't reset view state → user stuck on protected page.

## Multi-Layer Solution

### Layer 1: Immediate Fix (SIGNED_OUT Handler)
**Priority**: Critical | **Risk**: Very Low | **Time**: 5 min

Add `setView('landing')` to the SIGNED_OUT handler to match handleSignOut behavior.

**File**: `App.tsx:367` (after `prewarmProfilesRef.current.clear();`)

```typescript
if (event === 'SIGNED_OUT') {
  sessionStorage.removeItem('deep_personality_is_guest');
  sessionStorage.removeItem('force_password_reset');
  sessionStorage.removeItem('dp_pending_comparison_id');
  sessionStorage.removeItem('dp_pending_invite_code');
  setPendingComparisonId(null);
  setInitialProfile(null);
  prewarmProfilesRef.current.clear();
  setView('landing'); // ← ADD THIS LINE
}
```

**Why this is safe**: Idempotent operation, no side effects, makes both logout paths consistent.

### Layer 2: Component-Level Auth Guard (Wizard)
**Priority**: High | **Risk**: Low | **Time**: 10 min

Add defensive auth check at the top of Wizard component.

**File**: `components/Wizard.tsx:65-100` (after hooks, before render)

```typescript
export const Wizard = ({ onAnalyzeClick, onProfileSaved }: WizardProps) => {
  const [user, setUser] = useState<User | null>(null);
  // ... other hooks ...

  // Guard: Redirect to landing if not authenticated
  if (!user && authChecked) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <p className="text-gray-600 mb-4">Please sign in to continue</p>
          <button
            onClick={() => setShowAuthModal(true)}
            className="btn-primary"
          >
            Sign In
          </button>
        </div>
      </div>
    );
  }

  // ... rest of component
}
```

**Benefit**: Component protects itself even if parent state is wrong.

### Layer 3: Derive View from Auth State (Architectural Fix)
**Priority**: Medium | **Risk**: Medium | **Time**: 30 min

Replace independent `view` state with derived state that's computed from `user`.

**File**: `App.tsx:114` (replace `const [view, setView] = useState(...)`)

```typescript
// Remove: const [view, setView] = useState<'landing' | 'quiz' | 'dashboard'>('landing');

// Add: Derive view from auth state
const view = useMemo(() => {
  if (!user) return 'landing'; // No auth = always landing

  if (pendingComparisonId) return 'dashboard';

  // Check if has in-progress assessment (async check handled elsewhere)
  return 'quiz'; // Default for authenticated users
}, [user, pendingComparisonId]);
```

**Note**: This requires refactoring all `setView()` calls to instead manage the underlying state that derives view (e.g., setPendingComparisonId).

**Benefit**: Architecturally impossible for view to be out of sync with auth.

## Implementation Plan

### Phase 1: Ship Immediately (Fixes 90% of bug)
1. ✅ **Apply Layer 1**: Add `setView('landing')` to SIGNED_OUT handler
2. ✅ **Apply Layer 2**: Add Wizard auth guard
3. ✅ **Test**: Run auth test suite
4. ✅ **Manual test**: All 4 logout scenarios (see Verification section)

**Files to modify**:
- `App.tsx:367` - Add one line
- `components/Wizard.tsx:~100` - Add auth guard (~15 lines)

### Phase 2: Architectural Hardening (Optional, Next Sprint)
1. ⏸️ **Apply Layer 3**: Convert view to derived state
2. ⏸️ **Refactor**: Replace all `setView()` calls
3. ⏸️ **Add tests**: E2E regression tests for auth protection
4. ⏸️ **Add middleware**: Server-side page protection (defense in depth)

## Critical Files

| File | Lines | Changes |
|------|-------|---------|
| `App.tsx` | 367 | Add `setView('landing')` in SIGNED_OUT handler |
| `App.tsx` | 114 (optional) | Convert view to derived state (Phase 2) |
| `components/Wizard.tsx` | ~100 | Add auth guard before render |
| `e2e/auth-signin.spec.ts` | - | Add regression test (optional) |

## Verification & Testing

### Automated Tests

```bash
# Quick sanity check
npm run test:e2e -- --grep="User Journey" --project=chromium-authenticated

# Full auth flow tests
npm run test:e2e -- --grep="auth"
```

### Manual Test Scenarios

Test all 4 logout paths:

1. **Normal Sign Out**
   - Sign in → Dashboard → User menu → Sign out
   - ✓ Should immediately show landing page
   - ✓ Should not see any protected content

2. **Sign Out from Wizard**
   - Sign in → Start assessment → User menu → Sign out
   - ✓ Should immediately show landing page
   - ✓ Wizard should disappear

3. **Session Expiry During Assessment** (THE BUG)
   - Sign in → Start assessment
   - Wait for session to expire (or manually delete auth cookie)
   - Trigger any action (e.g., answer question)
   - ✓ Should show auth modal
   - ✓ After closing modal → should see landing page, NOT wizard

4. **Restart with Expired Session** (THE ORIGINAL BUG)
   - Sign in → Start assessment
   - Let session expire (or delete cookie)
   - Click "Restart from Scratch"
   - ✓ Should redirect to landing page
   - ✓ Should not see "Start My Profile" page

### Success Criteria

- [ ] All 4 manual test scenarios pass
- [ ] Automated auth tests pass
- [ ] No console errors during logout
- [ ] No visual flicker/flash of protected content
- [ ] Session storage properly cleared
- [ ] Sentry shows no new auth errors

## Rollback Plan

**If issues arise post-deployment:**

1. **Layer 1 rollback**: Remove the single line at App.tsx:367
2. **Layer 2 rollback**: Remove auth guard from Wizard.tsx
3. **Both are safe independent changes** - can roll back individually

## Risk Assessment

| Layer | Risk Level | Impact if Fails |
|-------|-----------|----------------|
| Layer 1 | Very Low | Worst case: double setView call (harmless) |
| Layer 2 | Low | Worst case: shows auth prompt unnecessarily |
| Layer 3 | Medium | Could break view routing if refactor incomplete |

## Security Impact

**What was exposed**: When bug occurred, logged-out users could see:
- Assessment UI structure and section titles
- Cached progress data from previous session (in-memory state)
- "Start My Profile" button (misleading, clicking would fail)
- Progress bar showing partial completion

**What was NOT exposed**:
- ✅ API routes are protected - no data could be fetched
- ✅ New profiles could not be created without auth
- ✅ Other users' data never accessible

**Severity**: Medium - UI exposure only, no data breach

## Additional Hardening (Future)

Optional improvements for future sprints:

1. **Middleware auth checks** - Add page-level auth enforcement
2. **Session validation on mount** - Re-verify session freshness
3. **Auth state machine** - Formal state management (loading/authenticated/unauthenticated)
4. **E2E regression tests** - Automated tests for all logout scenarios
5. **Sentry alerting** - Monitor for auth-related errors
