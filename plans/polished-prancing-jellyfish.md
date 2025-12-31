# E2E Test Refinement Plan

## Problem Summary

The E2E tests are failing because they were written for a URL-based routing architecture that doesn't exist. The Deep-Personality app is a **Single Page Application** where all views (`landing`, `quiz`, `dashboard`) render at `/` using React state - there are no `/wizard` or `/dashboard` routes.

### Root Causes
1. **URL Routing Mismatch**: Tests expect `/wizard` and `/dashboard` URLs, but app uses client-side state at `/`
2. **Duplicate Sign In Buttons**: Header, AuthModal, and StartAssessmentModal all render "Sign In" causing strict mode violations
3. **Fragile Selectors**: Hardcoded placeholder text and CSS class selectors break easily

---

## Implementation Plan

### Phase 1: Add Test Infrastructure (Components)

Add `data-testid` attributes to key interactive elements:

**Files to modify:**

| File | Test IDs to Add |
|------|-----------------|
| `App.tsx` | `header-sign-in-btn`, `view-landing`, `view-quiz`, `view-dashboard` |
| `components/AuthModal.tsx` | `auth-modal`, `auth-modal-backdrop`, `auth-email-input`, `auth-password-input`, `auth-submit-btn`, `auth-google-btn`, `auth-close-btn` |
| `components/StartAssessmentModal.tsx` | `start-modal`, `start-name-input`, `start-email-input`, `start-password-input`, `start-submit-btn`, `start-guest-btn` |
| `components/LandingHero.tsx` | `begin-assessment-btn` |
| `components/Wizard.tsx` | `wizard-container`, `wizard-progress-bar`, `wizard-next-btn`, `wizard-back-btn` |
| `components/Dashboard.tsx` | `dashboard-container` |

---

### Phase 2: Create Test Utilities

**New file: `e2e/utils/test-helpers.ts`**
- `seedQuizState(page, state)` - Set localStorage to jump to quiz/dashboard view
- `waitForView(page, viewName)` - Wait for specific view to render
- `openAuthModal(page)` - Click header sign-in button
- `completeGuestSignup(page, name, email)` - Fill guest signup form

**New file: `e2e/fixtures/mock-data.ts`**
- `MOCK_COMPLETED_STATE` - Full quiz completion for dashboard tests
- `MOCK_IN_PROGRESS_STATE` - Partial quiz for wizard tests
- `MOCK_BASIC_INFO` - Reusable user data

---

### Phase 3: Rewrite Tests (by priority)

#### 3.1 `home.spec.ts` (4 tests - Minor updates)
- Replace button selectors with `getByTestId('begin-assessment-btn')`
- Keep URL expectations (they test `/` which is correct)

#### 3.2 `auth.spec.ts` (13 tests - Selector fixes)
- Replace `page.getByRole('button', { name: /sign in/i })` with `page.getByTestId('header-sign-in-btn')` for header button
- Replace `page.getByRole('button', { name: /^sign in$/i })` with `page.getByTestId('auth-submit-btn')` for modal submit
- Replace `.fixed.inset-0` with `page.getByTestId('auth-modal-backdrop')`
- Replace hardcoded placeholders with test IDs

#### 3.3 `assessment.spec.ts` (15 tests - Complete rewrite)

**Remove:** All `page.goto('/wizard')` calls and URL expectations

**New approach:**
```typescript
// Instead of: await page.goto('/wizard')
// Do this:
await page.goto('/');
await page.getByTestId('begin-assessment-btn').click();
await page.getByTestId('start-guest-btn').click();
// ... fill form
await expect(page.getByTestId('wizard-container')).toBeVisible();
await expect(page).toHaveURL('/'); // URL stays at /
```

**Tests to rewrite:**
- `should navigate to assessment from homepage` - Remove URL expectation, check for wizard-container
- `should show welcome/intro step first` - Seed localStorage, check wizard renders
- `should display progress indicator` - Use `wizard-progress-bar` test ID
- `should allow answering questions with Likert scale` - Navigate to quiz via UI
- `should enable Next button after answering` - Check button state changes
- `should show Back button after first question` - Navigate forward first
- `should persist answers when navigating` - Seed state, verify persistence

#### 3.4 `dashboard.spec.ts` (22 tests - State seeding approach)

**Remove:** All `page.goto('/dashboard')` calls

**New approach:**
```typescript
test.beforeEach(async ({ page }) => {
  await page.goto('/');
  await page.evaluate(() => {
    localStorage.setItem('deep_personality_quiz_v2', JSON.stringify({
      step: 30,
      basicInfo: { name: 'Test', email: 'test@example.com' },
      answers: { /* mock */ },
      hasConsented: true
    }));
  });
  await page.reload();
  // Click analyze results to get to dashboard view
});
```

**Tests to keep (with modifications):**
- Page load tests - Check `dashboard-container` visibility
- Visualization tests - Check for chart elements
- Export/share button tests - Use test IDs
- Accessibility tests - Keep heading hierarchy checks

**Tests to remove:**
- URL-based navigation tests
- Tests with no real assertions (just `body.toBeVisible()`)

#### 3.5 `sharing.spec.ts` (9 tests - Partial updates)

**Keep:** Tests for `/share/[code]` route (this actually exists)
**Remove:** Tests that navigate to `/dashboard`
**Update:** Use test IDs for share button selectors

---

### Phase 4: Tests to Delete

Remove tests that provide no value:
- Tests with only `await expect(page.locator('body')).toBeVisible()` assertion
- Duplicate tests checking same functionality
- Tests for non-existent features

---

## File Change Summary

| File | Action | Complexity |
|------|--------|------------|
| `App.tsx` | Add 4 test IDs | Low |
| `components/AuthModal.tsx` | Add 7 test IDs | Low |
| `components/StartAssessmentModal.tsx` | Add 6 test IDs | Low |
| `components/LandingHero.tsx` | Add 1 test ID | Low |
| `components/Wizard.tsx` | Add 4 test IDs | Low |
| `components/Dashboard.tsx` | Add 1 test ID | Low |
| `e2e/utils/test-helpers.ts` | Create new | Medium |
| `e2e/fixtures/mock-data.ts` | Create new | Low |
| `e2e/home.spec.ts` | Minor updates | Low |
| `e2e/auth.spec.ts` | Selector updates | Medium |
| `e2e/assessment.spec.ts` | Complete rewrite | High |
| `e2e/dashboard.spec.ts` | Major rewrite | High |
| `e2e/sharing.spec.ts` | Partial updates | Medium |

---

## Success Criteria

After implementation:
- [ ] All E2E tests pass in CI with secrets configured
- [ ] No strict mode violations (duplicate element selectors)
- [ ] No URL routing expectations for client-side views
- [ ] Tests use data-testid for reliable element selection
- [ ] Test utilities reduce code duplication
