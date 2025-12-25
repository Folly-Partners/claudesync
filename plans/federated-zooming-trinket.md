# Plan: Improve Analyze Page UX

## Summary
Fix the analyze page so logged-in users with assessment data get a seamless experience:
1. **Primary flow:** User has assessment → auto-load → auto-analyze (hide upload UI)
2. **Fallback flow:** User has no assessment OR wants to switch profiles → show upload UI with clear button

## File to Modify
`/Users/andrewwilkinson/Deep-Personality/components/Dashboard.tsx`

---

## Change 1: Start with Upload Section Collapsed for Users with Data

**Location:** Line 187 (`uploadSectionExpanded` state) and auto-load logic (~lines 454-478, 513-539)

**Current:** `uploadSectionExpanded` starts as `true` for everyone

**New:**
- Keep it `true` initially (for loading state)
- After checking auth: if user has saved profiles, set `uploadSectionExpanded(false)`
- After auto-loading profile, collapse the section

```tsx
// After successfully loading profile in the auto-load blocks:
setProfileA(profileData.profile);
setUploadSectionExpanded(false);  // ADD THIS LINE
```

---

## Change 2: Auto-Trigger Analysis When Profile Loads Without Saved Analysis

**Location:** Add new state + useEffect

**Implementation:**
```tsx
// Add state (near line 187)
const [shouldAutoAnalyze, setShouldAutoAnalyze] = useState(false);

// In auto-load blocks (after loading profile):
if (profileData.profile.aiAnalysis && profileData.profile.aiAnalysis.length > 100) {
  setAiResponse(profileData.profile.aiAnalysis);
  setIsSavedAnalysis(true);
} else {
  // No saved analysis - trigger auto-analyze
  setShouldAutoAnalyze(true);
}

// Add useEffect to trigger analysis (after other useEffects, ~line 562)
useEffect(() => {
  if (shouldAutoAnalyze && profileA && !aiResponse && !aiLoading) {
    setShouldAutoAnalyze(false);
    handleAiAnalysis();
  }
}, [shouldAutoAnalyze, profileA, aiResponse, aiLoading]);
```

---

## Change 3: Add Upload Button to Fallback UI (for users without data or switching)

**Location:** Lines ~2470-2527 (empty profile state in upload section)

The upload section only shows when:
- User is not logged in
- Logged-in user has no saved assessments
- User manually expands it via "Change profiles" button

**Add:**
1. `fileInputARef` ref (near line 182)
2. Hidden file input + visible button
3. `handleFileInputA` handler

```tsx
// Add ref (near line 182)
const fileInputARef = useRef<HTMLInputElement>(null);

// Add handler (near handleFileInputB ~line 1257)
const handleFileInputA = (e: React.ChangeEvent<HTMLInputElement>) => {
  const file = e.target.files?.[0];
  if (!file) return;
  if (!file.name.endsWith('.json')) {
    alert('Please upload a JSON file');
    return;
  }
  const reader = new FileReader();
  reader.onload = (event) => {
    try {
      const data = JSON.parse(event.target?.result as string);
      const validation = validateProfileStructure(data);
      if (validation.isValid) {
        setProfileA(data);
        setAiResponse(null);
        setAiError(null);
      } else {
        alert(`Invalid profile file: ${validation.errors.join(', ')}`);
      }
    } catch {
      alert('Failed to parse JSON file');
    }
  };
  reader.readAsText(file);
  e.target.value = '';
};

// In the empty profile UI (~line 2478, after "Upload your results file" text)
<input
  type="file"
  ref={fileInputARef}
  onChange={handleFileInputA}
  accept=".json,application/json"
  className="hidden"
/>
<div className="mt-4 text-center">
  <button
    onClick={(e) => { e.stopPropagation(); fileInputARef.current?.click(); }}
    className="px-6 py-3 bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 text-white font-semibold rounded-xl shadow-lg shadow-blue-200/50 transition-all flex items-center gap-2 mx-auto"
  >
    <UploadCloud className="w-5 h-5" />
    Upload Your Assessment Results File
  </button>
  <p className="text-xs text-slate-400 mt-2">
    Select the JSON file from your completed assessment
  </p>
</div>
```

---

## User Flow Summary

| Scenario | What Happens |
|----------|--------------|
| Logged-in + has assessment + has saved analysis | Auto-load profile → show saved analysis → upload hidden |
| Logged-in + has assessment + NO saved analysis | Auto-load profile → auto-run analysis → upload hidden |
| Logged-in + NO assessment | Show upload UI with button |
| Not logged in | Show upload UI with button |
| User clicks "Change profiles" | Expand upload section, can upload different file |

---

## Testing Checklist
- [ ] Logged-in user with saved analysis: sees analysis immediately, no upload UI
- [ ] Logged-in user without saved analysis: auto-analyzes, no upload UI
- [ ] Logged-in user with no assessments: sees upload UI with button
- [ ] Not logged in: sees upload UI with button
- [ ] Mobile: upload button works (tappable, opens file picker)
- [ ] Desktop: drag-drop still works
- [ ] "Change profiles" button: expands upload section
- [ ] Switching profiles: clears analysis, does NOT auto-analyze (user choice)
