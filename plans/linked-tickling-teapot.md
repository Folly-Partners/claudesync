# Enhanced Comparison System Plan

## Summary
Enhance the comparison/invite system to support:
1. Shareable URLs that work for new users (signup → assessment → auto-compare)
2. Multiple invite codes (up to 10 active) - show person's name once accepted
3. Better visibility into linked comparisons and invite status
4. Revoke capabilities for both invites and comparisons

---

## Phase 2: Invite URL Flow for New Users

### 2.1 Update `/compare/[code]` Page

**File:** `/app/compare/[code]/page.tsx`

**Changes:**
- On page load, immediately store code in sessionStorage: `dp_pending_invite_code`
- For unauthenticated users:
  - Show friendly invite landing page ("Someone wants to compare with you!")
  - "Create Account" and "Sign In" CTAs
  - Note about completing assessment
- For authenticated users without a profile:
  - Show "Complete your assessment to see this comparison"
  - Redirect to quiz (code stays in sessionStorage)
- For authenticated users with profile:
  - Proceed with normal redemption flow

### 2.2 Auto-Redeem After Assessment

**File:** `/components/wizard/ResultsStep.tsx`

**Changes:**
- After profile save succeeds (`saveStatus === 'saved'`), check for `dp_pending_invite_code`
- If found, call `/api/comparison-grants/redeem` with the code
- On success: set `dp_pending_comparison_id`, clear the invite code
- On failure (expired/invalid): clear the code silently, don't block user

### 2.3 App.tsx Integration

**File:** `/App.tsx`

**Changes:**
- In auth success handler, check for pending invite code
- If user has profile → go to dashboard (code will be redeemed)
- If user needs assessment → go to quiz (ResultsStep will handle redemption)

---

## Phase 3: Multiple Invite Codes (Max 10)

### 3.1 API Updates

**File:** `/app/api/comparison-grants/route.ts`

**POST changes:**
- Check count of active (unused, non-revoked, non-expired) grants for user
- Return error if already at 10 active codes
- Continue normal code generation if under limit

**GET changes:**
- Include recipient name for used invites (join with comparison data)
- Return clear status for each grant

### 3.2 Dashboard Compare Modal Enhancements

**File:** `/components/Dashboard.tsx`

**Changes to Compare modal:**

1. **Multiple invites support:**
   - Change `activeInvite` → `activeInvites` (array)
   - Fetch all active invites when modal opens
   - Allow creating additional invites (up to 10 active)
   - Show "Generate New Code" button if under limit

2. **Show all invites with smart display:**
   - **Pending**: Show code with copy URL button, expiration countdown, revoke button
   - **Accepted**: Show person's name (not the code), link to view comparison, badge "Can compare with you"
   - **Expired/Revoked**: Don't show or show greyed out

3. **Enhanced comparisons list:**
   - Show recent comparisons with person's name prominently
   - "You invited" vs "Invited you" indicator
   - Quick "View Comparison" button
   - "View All in Settings" link for full management

4. **Compare button styling:**
   - Change from teal to **pink/red gradient** (e.g., `from-pink-500 to-rose-500`)
   - Heart icon to denote love/relationship theme

### 3.3 Clear Access Indicators

**For the invitee (person who received the link):**
- After signing up + completing assessment via invite link:
  - Show toast/notification: "You're now linked with [Inviter's name]!"
  - In Compare modal: Show "Linked with [name]" at the top with heart icon
  - Easy "View Comparison" button

**For the inviter (person who sent the link):**
- Once someone accepts their invite:
  - Show "[Name] can now compare with you" badge
  - Clear visual that the connection is mutual
  - "View Comparison" CTA

**Visual indicators:**
- Use pink/rose colors consistently for comparison features
- Heart icon (💕) for linked connections
- Subtle "linked" badge on accepted invites/comparisons

---

## Phase 4: Settings Modal Enhancements

**File:** `/components/SettingsModal.tsx`

**Enhancements to Comparisons section:**

1. **Pending Invites:**
   - Show code (formatted) with copy URL button
   - Show expiration countdown
   - Revoke button

2. **Accepted Invites (now comparisons):**
   - Show person's name prominently
   - Show date accepted
   - Link to view comparison
   - Revoke access button

3. **Active Comparisons (from others):**
   - Show who invited you
   - Show creation date
   - Show analysis status
   - Clear visual for revoked comparisons

---

## Complete User Flow

```
User A generates invite URL
        ↓
User B clicks link (not logged in)
        ↓
Code stored in sessionStorage
        ↓
User B signs up
        ↓
User B completes assessment
        ↓
ResultsStep auto-redeems code
        ↓
Comparison created, both users can view
        ↓
User A sees "Accepted by [B's name]" in their invites
```

---

## Files to Modify

| File | Changes |
|------|---------|
| `/app/compare/[code]/page.tsx` | Unauthenticated user handling, sessionStorage |
| `/components/wizard/ResultsStep.tsx` | Auto-redeem pending invites |
| `/App.tsx` | Auth success handler for pending invites |
| `/app/api/comparison-grants/route.ts` | 10-code limit, recipient name in response |
| `/app/api/comparisons/[id]/route.ts` | Allow either party to generate/update AI analysis |
| `/components/Dashboard.tsx` | Multiple invites UI, enhanced comparisons list |
| `/components/SettingsModal.tsx` | Enhanced comparison management |

---

## Implementation Order

1. **`/compare/[code]` page** - Handle unauthenticated users, store code in sessionStorage
2. **ResultsStep** - Auto-redeem pending invite after assessment completion
3. **App.tsx** - Integrate pending invite check in auth success flow
4. **API updates** - 10-code limit, recipient name in GET response
5. **Comparison API** - Allow either party to generate/update AI analysis
6. **Dashboard Compare modal** - Multiple invites, show names for accepted, enhanced list
7. **Settings modal** - Polish comparison management UI

---

## Phase 5: Allow Either Party to Generate AI Analysis

### Current Behavior (Already Working)
- When a code is redeemed, **both parties get access** via `comparison_access` table
- Both can view the comparison and the AI analysis
- Analysis is stored in the `comparisons.analysis` column - **not regenerated each time**

### Change Needed

**File:** `/app/api/comparisons/[id]/route.ts`

**Current (line ~121):**
```typescript
if (access.role !== 'sender') {
  return NextResponse.json({ error: 'Only sender can modify' }, { status: 403 });
}
```

**New logic:**
- Allow PATCH if analysis is empty/null (either party can generate initial analysis)
- Once analysis exists, only allow updates from the person who generated it (or both?)
- Or simpler: allow either party to regenerate, but warn "This will replace the existing analysis"

**Recommended approach:** Allow either party to generate/update the analysis. First person to generate it "wins", but either can regenerate later if needed.

---

## Decisions Made

- **No labels**: Codes show as codes until accepted, then show person's name
- **10 code limit**: Max 10 active (unused) invite codes per user
- **Auto-redeem**: Pending invites automatically redeem after assessment completion
- **Bidirectional viewing**: Already supported - both parties can view comparison
- **Shared AI analysis**: Already supported - analysis stored once, both can view
- **Either party can generate**: Allow recipient OR sender to generate/update AI analysis
- **Pink/red theming**: Compare button uses pink/rose gradient with heart icon
- **Clear access indicators**: Show who can compare with you, mutual connections highlighted
