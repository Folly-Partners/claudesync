# Fix: Calendar Navigation Buttons Not Working

## Problem
The < and > navigation buttons in the Journal calendar (at localhost:3000) don't respond to clicks.

## Root Cause
**Hydration mismatch** in `Calendar.tsx` at line 31:
```tsx
const [currentMonth, setCurrentMonth] = useState(new Date());
```

`new Date()` returns different values on server vs client, causing React hydration to fail. When hydration fails, event handlers don't get properly attached to buttons.

## Solution
Defer setting the initial date to client-side only using `useEffect`:

```tsx
const [currentMonth, setCurrentMonth] = useState<Date | null>(null);

useEffect(() => {
  setCurrentMonth(new Date());
}, []);

// Add early return while loading
if (!currentMonth) {
  return <div className="max-w-4xl mx-auto">Loading...</div>;
}
```

## File to Modify
- `/Users/andrewwilkinson/Journal/web/components/Calendar.tsx`

## Changes
1. Change `useState(new Date())` to `useState<Date | null>(null)`
2. Add `useEffect` to set the date on client mount
3. Add loading state handling before the date is set
