# Fix Generated Response Styling & Send Bug

## Problems
1. Light blue background (`bg-blue-50`) - should be white
2. Text color hard to read
3. Textarea needs proper styling
4. **BUG**: ⌘↵ doesn't send when editing custom response (keyboard disabled during `editingResponse`)

## Fixes

### File: `components/actions/ActionPanel.tsx`

**Line 554** - Change container from blue to white with dark mode support:
```tsx
// Before:
<div className="mt-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">

// After:
<div className={`mt-4 p-4 border rounded-lg ${isDark ? 'bg-gray-700 border-gray-600' : 'bg-white border-gray-300'}`}>
```

**Line 556** - Fix label color:
```tsx
// Before:
<span className="text-sm font-medium text-blue-900">

// After:
<span className={`text-sm font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>
```

**Line 559** - Fix Edit/Preview button:
```tsx
// Before:
className="text-sm text-blue-600 hover:text-blue-800"

// After:
className={`text-sm ${isDark ? 'text-blue-400 hover:text-blue-300' : 'text-blue-600 hover:text-blue-800'}`}
```

**Line 565-569** - Fix textarea:
```tsx
// Before:
className="w-full px-3 py-2 border border-blue-300 rounded-lg..."

// After:
className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${isDark ? 'bg-gray-800 border-gray-600 text-white' : 'bg-white border-gray-300 text-gray-900'}`}
```

**Line 321** - Fix: Allow ⌘↵ to send even while editing:
```tsx
// Before:
useKeyboard([...], !processing && !editingResponse && !isActivelyEditing)

// After: Keep SEND shortcut enabled during editing
useKeyboard([...], !processing)

// But need to update individual shortcuts to check editing state
// Alternative: Add onKeyDown handler to textarea that calls handleSend on ⌘↵
```

Better approach - add `onKeyDown` to the custom response textarea (line 565):
```tsx
<textarea
  value={editedResponseText}
  onChange={(e) => setEditedResponseText(e.target.value)}
  onKeyDown={(e) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      e.preventDefault();
      handleSend();
    }
  }}
  rows={6}
  className={...}
/>
```
