# CC Team Member Improvements + Bug Fixes

---

## Overview

Four areas to address:
1. **CC Team Member UI**: Compact layout, show learned contacts, allow adding new contacts
2. **Bug Fix**: Reply editing doesn't work properly
3. **Bug Fix**: Email disappears/jumps to next while composing
4. **Auto-archive**: Archive emails after any action (reply, forward, CC, etc.)

---

## Issue 1: CC Team Member Improvements

### Current State
- CC contacts come from `decision.suggestedContacts` (AI-generated per email)
- Shows name, email, AND reason (takes too much vertical space)
- No way to add new contacts that persist

### User Requirements
1. Show contacts learned from AI analysis (people user typically CCs)
2. Allow CCing to someone not in the list (add autocomplete input)
3. When user adds a new person, save them so they show up as an option going forward
4. Compact layout: just name + email underneath (no role/reason text)
5. Should not take up too much vertical space

### Implementation

**File: `components/actions/ActionPanel.tsx`**

1. **Redesign CC contact display** (lines 541-583):
```tsx
// BEFORE: Radio buttons with name, email, AND reason
<label className="...">
  <input type="radio" ... />
  <div>{contact.name}</div>
  <div>{contact.email}</div>
  <div>{contact.reason}</div>  // ← REMOVE THIS
</label>

// AFTER: Compact stacked layout
<label className="flex items-center p-2 ...">
  <input type="radio" ... />
  <div className="ml-2">
    <div className="text-sm font-medium">{contact.name}</div>
    <div className="text-xs text-gray-500">{contact.email}</div>
  </div>
  <kbd className="ml-auto ...">{index + 1}</kbd>
</label>
```

2. **Add autocomplete input for custom CC recipient**:
```tsx
// After the contact list, add:
<AutoCompleteInput
  label="Or CC someone else:"
  value={customCcTo}
  onChange={setCustomCcTo}
  contacts={[...googleContacts, ...patterns.contacts.team, ...patterns.contacts.common]}
  placeholder="Type name or email..."
  isDark={isDark}
/>
```

3. **Merge contact sources for display**:
```tsx
// Combine AI suggestions with learned contacts
const ccContacts = useMemo(() => {
  const aiSuggested = decision?.suggestedContacts || [];
  const learned = patterns?.contacts?.team || [];

  // Dedupe by email, prioritize AI suggestions
  const seen = new Set<string>();
  const merged = [];

  for (const c of [...aiSuggested, ...learned]) {
    if (!seen.has(c.email.toLowerCase())) {
      seen.add(c.email.toLowerCase());
      merged.push(c);
    }
  }
  return merged;
}, [decision?.suggestedContacts, patterns?.contacts?.team]);
```

**File: `lib/storage/db.ts`**

4. **Add method to persist new CC contacts**:
```typescript
async addTeamContact(contact: { name: string; email: string }): Promise<void> {
  const patterns = await this.getPatterns();
  if (!patterns) return;

  // Check if already exists
  const exists = patterns.contacts.team.some(
    c => c.email.toLowerCase() === contact.email.toLowerCase()
  );
  if (exists) return;

  patterns.contacts.team.push(contact);
  await this.savePatterns(patterns);
}
```

**File: `app/triage/page.tsx`**

5. **Handle new CC contact persistence**:
```typescript
case 'cc':
  // If user used custom CC input (not from suggestions), save the contact
  if (metadata?.ccTo && metadata?.isNewContact) {
    await dbHelpers.addTeamContact({
      name: metadata.ccName || metadata.ccTo.split('@')[0],
      email: metadata.ccTo,
    });
  }
  // ... existing send logic
```

---

## Issue 2: Reply Editing Bug

### Root Cause
The editing flow has no clear way to exit edit mode after making changes:
- Click "Edit" → textarea appears, `editedOptions[index]` set
- Can type in textarea
- "Reset to original" removes edit entirely
- **Missing**: Way to confirm edits and close textarea

### User Requirement
- "Done" button should ONLY close the textarea (exit edit mode)
- "Done" does NOT send the email
- User must still explicitly click "Send & Next" to send
- This allows reviewing the edited text before sending

### Fix

**File: `components/actions/ActionPanel.tsx`**

1. **Add state to track which option is actively being edited**:
```tsx
const [activelyEditingIndex, setActivelyEditingIndex] = useState<number | null>(null);
```

2. **Update Edit button handler**:
```tsx
onClick={() => {
  setActivelyEditingIndex(index);  // Track which is being edited
  setSelectedResponse(index);
  setCustomResponse('');
  setEditedOptions({ ...editedOptions, [index]: option.text });
}}
```

3. **Add "Done" button next to "Reset to original"** (closes edit mode, does NOT send):
```tsx
{activelyEditingIndex === index ? (
  <div onClick={(e) => e.stopPropagation()}>
    <textarea ... />
    <div className="flex justify-between mt-1">
      <button onClick={handleReset}>Reset to original</button>
      <button onClick={() => setActivelyEditingIndex(null)}>Done</button>
    </div>
  </div>
) : (
  <div>{displayText}</div>  // Shows edited text, user can review before sending
)}
```

4. **Update condition for showing textarea**:
```tsx
// BEFORE:
{isEditing && isSelected ? ...

// AFTER:
{activelyEditingIndex === index ? ...  // Only show if actively editing THIS option
```

5. **Fix keyboard shortcut disabling**:
```tsx
// BEFORE:
const isEditingAnyResponse = Object.keys(editedOptions).length > 0 && editedOptions[selectedResponse] !== undefined;

// AFTER:
const isActivelyEditing = activelyEditingIndex !== null;

useKeyboard([...], !processing && !editingResponse && !isActivelyEditing);
```

**Flow after fix:**
1. User clicks "Edit" → textarea opens
2. User edits text
3. User clicks "Done" → textarea closes, edited text shows in preview
4. User can review the edited text
5. User clicks "Send & Next" → email sends with edited text

---

## Issue 3: Email Disappearing Bug

### Root Cause
When user clicks "Send & Next":
1. DB marks email as processed immediately (line 655)
2. `loadNextEmail()` runs right away (line 692)
3. ActionPanel resets due to `useEffect` on `email.id`
4. But the actual send is delayed 15 seconds (UNDO_DELAY_MS)

The email "jumps" to the next one before the user expects it.

### Fix

**File: `app/triage/page.tsx`**

The current flow saves to DB immediately to enable undo. The issue is that `loadNextEmail()` is called at the same time, causing the UI to jump.

**Option A: Delay loadNextEmail (Simpler)**
```typescript
// Don't advance to next email until after undo window closes
// Only call loadNextEmail() inside executeAction(), not in handleAction()

const executeAction = async (pendingId: string) => {
  // ... existing send logic ...

  // NOW advance to next email (after successful send)
  await loadNextEmail();
};
```

The drawback: user has to wait 15 seconds before seeing next email.

**Option B: Visual transition (Better UX)**
```typescript
// In handleAction, after saving to DB:
// 1. Mark current email as "pending" visually
// 2. Load next email but keep pending action visible
// 3. Show mini card of pending email with undo button

const [pendingEmailAction, setPendingEmailAction] = useState<{
  email: Email;
  action: ActionType;
  pendingId: string;
} | null>(null);

// After handleAction saves to DB:
setPendingEmailAction({
  email: emailToProcess,
  action,
  pendingId,
});
await loadNextEmail();  // ← Still advances immediately
```

Then show a small overlay/toast with the pending email info and undo button.

### Recommended: Option B - Advance immediately with toast

Keep the immediate advancement but ensure the undo toast works properly:

```typescript
// In handleAction - keep loadNextEmail() call as-is

// The UndoableToast component already exists and is being used (line ~710)
// The issue is the ActionPanel resets due to useEffect on email.id

// Fix: The toast system already handles this - the bug is likely that
// the toast isn't being shown or the undo isn't properly connected.
// Need to verify the pendingAction state and UndoableToast are working.
```

**Verify/Fix:**
1. Check that `pendingAction` state is being set correctly
2. Ensure `UndoableToast` is rendering when there's a pending action
3. Confirm the undo button calls `handleUndo()` which cancels the timeout
4. The email advancing is expected - the bug may be something else triggering it prematurely

---

## Issue 4: Auto-Archive After Actions

### Requirement
After any action that involves sending/processing (respond, forward, CC, delegate), automatically archive the email.

### Implementation

**File: `app/triage/page.tsx`**

In `executeAction()`, after sending the email, call Gmail archive:

```typescript
const executeAction = async (pendingId: string) => {
  const pending = pendingActions.current.get(pendingId);
  if (!pending) return;

  const { email, action, metadata } = pending;

  try {
    switch (action) {
      case 'respond':
        // ... send reply ...
        await gmailClient.archiveEmail(email.id);  // ← ADD
        break;

      case 'forward':
        // ... send forward ...
        await gmailClient.archiveEmail(email.id);  // ← ADD
        break;

      case 'cc':
        // ... send CC reply ...
        await gmailClient.archiveEmail(email.id);  // ← ADD
        break;

      case 'archive':
        await gmailClient.archiveEmail(email.id);  // Already does this
        break;

      // 'hold' and 'ignore' do NOT archive
    }
  }
};
```

**Alternative: Cleaner approach**

Add archive call after the switch statement for actions that should archive:

```typescript
const executeAction = async (pendingId: string) => {
  // ... existing switch for sending emails ...

  // Archive after any "actioned" email (not hold/ignore)
  const archiveActions: ActionType[] = ['respond', 'forward', 'cc', 'archive'];
  if (archiveActions.includes(action)) {
    await gmailClient.archiveEmail(email.id);
  }
};
```

---

## Files to Modify

| File | Changes |
|------|---------|
| `components/actions/ActionPanel.tsx` | Compact CC layout, add autocomplete, fix editing flow |
| `lib/storage/db.ts` | Add `addTeamContact()` method |
| `app/triage/page.tsx` | Persist new CC contacts, fix email jumping |
| `lib/constants.ts` | Reduce UNDO_DELAY_MS (optional) |

---

## Implementation Order

1. **Fix reply editing bug** (add Done button, track active editing)
2. **Fix email jumping bug** (move loadNextEmail to executeAction)
3. **Compact CC layout** (remove reason, tighten spacing)
4. **Add CC autocomplete** (for adding contacts not in list)
5. **Persist new CC contacts** (save to patterns.contacts.team)
