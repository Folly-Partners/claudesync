# Plan: Fix Full Email Rendering

## Problem
The "Full Email" view has two rendering issues:
1. **Long URLs overflow** - Proofpoint wrapped URLs and long links break out of the container
2. **Excessive line spacing** - Each line renders as a separate paragraph due to `\n` → `<br />` conversion

## Root Cause
**File:** `components/email/EmailView.tsx` (lines 584-593)

```jsx
<div
  className={`whitespace-pre-wrap ${isDark ? 'text-gray-300' : 'text-gray-700'}`}
  dangerouslySetInnerHTML={{
    __html: cleanedBody
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/\n/g, '<br />'),  // Every newline becomes <br>, causing excessive spacing
  }}
/>
```

Issues:
- No `break-words` or `overflow-wrap` for long URLs
- Converting every `\n` to `<br />` creates too much vertical space
- No intelligent paragraph grouping

## Solution

### 1. Add CSS for URL wrapping
Add `break-words` class to handle long URLs:
```jsx
className={`whitespace-pre-wrap break-words ${isDark ? 'text-gray-300' : 'text-gray-700'}`}
```

### 2. Smarter text processing
Instead of converting every `\n` to `<br />`, implement intelligent paragraph handling:

```javascript
// Process text into proper paragraphs
const formatEmailBody = (text: string): string => {
  // Escape HTML
  let escaped = text.replace(/</g, '&lt;').replace(/>/g, '&gt;');

  // Normalize multiple newlines to paragraph breaks
  // Single newlines within a paragraph stay as spaces or soft breaks
  // Double+ newlines become paragraph separators
  const paragraphs = escaped.split(/\n\s*\n/);

  return paragraphs
    .map(p => {
      // Within paragraphs, convert single newlines to <br> only if short lines
      // (indicates intentional line breaks like in signatures or lists)
      const lines = p.split('\n');
      if (lines.every(l => l.length < 80)) {
        // Short lines - preserve breaks (likely formatted content)
        return `<p>${lines.join('<br />')}</p>`;
      } else {
        // Long lines - join with spaces (likely wrapped prose)
        return `<p>${lines.join(' ')}</p>`;
      }
    })
    .join('');
};
```

### 3. Add paragraph styling
Add CSS for proper paragraph spacing:
```jsx
<div
  className={`break-words [&>p]:mb-4 [&>p:last-child]:mb-0 ${isDark ? 'text-gray-300' : 'text-gray-700'}`}
  dangerouslySetInnerHTML={{ __html: formatEmailBody(cleanedBody) }}
/>
```

## Files to Modify

1. **`components/email/EmailView.tsx`**
   - Add `formatEmailBody` helper function
   - Update the Full Email div (lines 584-593) with new classes and processing
   - Add `break-words` for URL handling
   - Use paragraph-based rendering instead of `<br />` everywhere

## Implementation Steps

1. Add `formatEmailBody` function near the top of EmailView component
2. Update the Full Email rendering div with:
   - `break-words` class for URL overflow
   - Remove `whitespace-pre-wrap` (paragraphs handle spacing now)
   - Use `formatEmailBody(cleanedBody)` instead of simple replace chain
   - Add paragraph margin styles
