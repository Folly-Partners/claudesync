# Email Triage App - Full Completion Plan

## Overview
Complete the email triage app for personal use with real Gmail integration, working AI/learning system, and polished UI features.

## Prerequisites
- [ ] Configure Google OAuth credentials in `.env.local`
- [ ] Verify redirect URI in Google Cloud Console matches `http://localhost:3002/api/auth/callback`

---

## Phase 0: Training Flow (CRITICAL - Do First)

The app needs to "learn" from your emails before it can make smart decisions. The current flow downloads emails but the learning functions are stubs.

### Training Sequence:
1. **Connect Gmail** → OAuth authentication
2. **Download emails** → ~3,000 emails (already implemented in `lib/patterns/learner.ts`)
3. **Analyze writing style** → Learn greetings, closings, formality (API exists, works)
4. **Learn action patterns** → What you archive, forward, CC (STUB - needs implementing)
5. **Learn CC patterns** → Who you loop in on what topics (STUB - needs implementing)
6. **Extract contacts** → Team members, assistant, frequent contacts (works but basic)

### What Training Produces:
- `LearnedPatterns` object stored in IndexedDB containing:
  - Your writing style (greetings, closings, phrases, formality by recipient type)
  - Action patterns (auto-archive rules, forward-to-assistant triggers)
  - Contact graph (assistant, team, common contacts with context)
  - Response time preferences (urgent vs normal vs low priority signals)

### Training Data Requirements:
- Minimum: 500 sent emails for writing style
- Ideal: 2,000+ emails for pattern detection
- The more emails, the better the AI learns your habits

---

## Phase 1: Gmail Integration & Setup Flow (Foundation)

### 1.1 Fix Environment Validation
**Files:** `lib/gmail/auth.ts`, `app/api/auth/token/route.ts`
- Add validation for `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `REDIRECT_URI`
- Return helpful error messages if credentials missing/placeholder

### 1.2 Fix Token Exchange Error Handling
**File:** `app/api/auth/token/route.ts`
- Return detailed error from Google on failure (currently logged but not returned)
- Handle common OAuth errors with user-friendly messages

### 1.3 Fix `getUnprocessedEmails()`
**File:** `lib/patterns/triage.ts` (line 156-160)
- Currently returns `[]` - change to use existing `dbHelpers.getUnprocessedEmails(limit)`

### 1.4 Enhance Triage Page Email Loading
**File:** `app/triage/page.tsx`
- When local DB empty, fetch fresh emails from Gmail inbox
- Add periodic sync with Gmail (check for new emails)
- Handle token refresh errors → redirect to re-auth

### 1.5 Improve Setup Flow
**File:** `app/setup/page.tsx`
- Better error messages for OAuth failures
- Show summary of what was learned before proceeding
- Handle pattern learning failures gracefully (still proceed)

---

## Phase 2: AI/Learning System (Make it Smart)

### 2.1 Implement `requiresResponse()` Properly
**Create:** `app/api/ai/requires-response/route.ts`
**Update:** `lib/ai/claude.ts` (lines 38-47)

Currently uses naive heuristic (just checks for "?" and "you"). Implement:
- Claude-based analysis of whether response is needed
- Consider: direct questions, action requests, To: vs CC:, email type
- Return confidence score and reasoning

### 2.2 Implement `analyzeActionPatterns()`
**Create:** `app/api/ai/analyze-patterns/route.ts`
**Update:** `lib/ai/claude.ts` (lines 107-117)

Currently returns empty. Implement:
- Analyze received vs sent emails for correlation patterns
- Identify auto-archive candidates (newsletters, notifications)
- Identify forward-to-assistant patterns (scheduling)
- Return structured patterns with confidence scores

### 2.3 Implement `analyzeCCPatterns()`
**Create:** `app/api/ai/analyze-cc/route.ts`
**Update:** `lib/ai/claude.ts` (lines 20-35)

Currently returns `{}`. Implement:
- Analyze emails where user CC'd someone
- Extract intro patterns per person
- Identify topic-based CC patterns

### 2.4 Learning from User Actions
**Create:** `lib/patterns/feedback.ts`
**Update:** `lib/storage/db.ts`, `app/triage/page.tsx`

New tables: `actionFeedback`, `patternStrengths`
- Track when AI prediction matches user action
- Adjust pattern confidence based on success/failure
- Periodic retraining from accumulated feedback

---

## Phase 3: UI/UX Features (Make it Polished)

### 3.1 Command Palette (⌘+K)
**Create:** `components/ui/CommandPalette.tsx`
**Update:** `app/demo/page.tsx`, `app/triage/page.tsx`

- Modal triggered by ⌘+K (shortcut already defined in useKeyboard.ts)
- Fuzzy search across actions, navigation, commands
- Categories: Actions (archive, reply, cc), Navigation (pages), Views (dark mode)
- Keyboard navigation (arrows, Enter)

### 3.2 Search/Filter Emails
**Create:** `components/ui/SearchBar.tsx`, `lib/hooks/useEmailSearch.ts`
**Update:** `lib/storage/db.ts`, `app/triage/page.tsx`

- Text search across subject, from, body
- Filter chips (sender, labels, attachments, date)
- Trigger with `/` key (shortcut exists)

### 3.3 Connect Need to Reply List
**Update:** `app/triage/page.tsx`, `components/email/NeedToReplyList.tsx`

Currently passes empty function. Implement:
- `handleSelectFromNeedToReply(emailId)` → load email, generate triage
- Visual indicator for Need to Reply items
- Mark done directly from list

### 3.4 Toast Notifications
**Create:** `components/ui/Toast.tsx`, `lib/hooks/useToast.ts`
**Update:** `app/triage/page.tsx`

- Action confirmations ("Email archived")
- Error messages
- Undo prompts with timer

### 3.5 Settings Page (Simple)
**Create:** `app/settings/page.tsx`, `components/settings/ContactsEditor.tsx`

- View/edit assistant email, team members
- Dark mode preference
- View stats, clear data, re-run learning
- Keyboard shortcut reference

---

## Implementation Order (Recommended)

### Sprint 1: Get Gmail Working + Training
1. **1.1-1.2** - Fix environment validation & error handling (30 min)
2. **2.2** - Implement `analyzeActionPatterns()` (45 min) ← TRAINING
3. **2.3** - Implement `analyzeCCPatterns()` (30 min) ← TRAINING
4. **1.5** - Setup flow improvements with progress display (30 min)
5. **TEST** - Run full training with YOUR real Gmail account
   - Connect Gmail OAuth
   - Download 3,000 emails
   - Verify patterns are learned (check IndexedDB)

### Sprint 2: Make Triage Work
6. **1.3** - Fix `getUnprocessedEmails()` (5 min)
7. **2.1** - Implement `requiresResponse()` properly (45 min)
8. **1.4** - Triage page email loading from Gmail (45 min)
9. **TEST** - Triage real emails, verify AI suggestions make sense

### Sprint 3: Learning Loop + Polish
10. **2.4** - Learning from user actions (1 hr)
11. **3.1** - Command palette (1 hr)
12. **3.3** - Need to Reply connection (30 min)
13. **3.4** - Toast notifications (30 min)

### Sprint 4: Extra Features
14. **3.2** - Search/filter (1 hr)
15. **3.5** - Settings page (45 min)
16. **Polish** - Animations, edge cases

---

## Critical Files Summary

| File | Changes |
|------|---------|
| `.env.local` | Add real Google OAuth credentials |
| `lib/gmail/auth.ts` | Add credential validation |
| `app/api/auth/token/route.ts` | Better error handling |
| `lib/ai/claude.ts` | Fix 3 stub functions (lines 20-35, 38-47, 107-117) |
| `lib/patterns/triage.ts` | Fix `getUnprocessedEmails()` (line 156-160) |
| `app/triage/page.tsx` | Gmail sync, Need to Reply handler, toasts |
| `app/setup/page.tsx` | Better error handling, summary display |
| `app/api/ai/` | Create 3 new routes (requires-response, analyze-patterns, analyze-cc) |
| `components/ui/` | Create CommandPalette.tsx, SearchBar.tsx, Toast.tsx |
| `lib/patterns/feedback.ts` | New - learning from actions |
| `lib/storage/db.ts` | Add new tables and helpers |
| `app/settings/page.tsx` | New - settings page |

---

## Notes
- Personal use = can hardcode some values, skip multi-account support
- Demo mode should remain functional as fallback
- Each Claude API call ~$0.01-0.03, budget accordingly for pattern analysis
