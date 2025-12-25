# Deep Personality: Settings Page Implementation Plan

## Overview

Add a Settings modal accessible from the user dropdown menu with:
1. Data export (quick assessment JSON + full PIPEDA-compliant package)
2. Sign out
3. Delete account
4. Reset assessment progress
5. Manage saved partners

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `components/SettingsModal.tsx` | **Create** - Main settings modal component |
| `app/api/user/export/route.ts` | **Create** - Data export API endpoint |
| `App.tsx` | **Modify** - Add Settings link to dropdown, modal state |

---

## 1. SettingsModal Component

### Structure

```
+------------------------------------------+
|  Settings                            [X] |
+------------------------------------------+
|                                          |
|  [Avatar] User Name                      |
|           user@email.com                 |
|                                          |
|  ----------------------------------------|
|  DATA EXPORT                             |
|  [Download] Quick Export (scores only)   |
|  [Download] Full Data Package (PIPEDA)   |
|                                          |
|  ----------------------------------------|
|  ASSESSMENT PROGRESS                     |
|  [RefreshCw] Reset Progress              |
|                                          |
|  ----------------------------------------|
|  SAVED PARTNERS (N)                      |
|  [Users] Manage Partners            [>]  |
|                                          |
|  ----------------------------------------|
|  [LogOut] Sign Out                       |
|                                          |
|  ----------------------------------------|
|  DANGER ZONE                             |
|  [Trash2] Delete Account                 |
+------------------------------------------+
```

### Sub-views

1. **Partners List** - View/delete saved partners
2. **Delete Confirmation** - Type "delete my account" to confirm

### Props

```typescript
interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSignOut: () => void;
  user: User;
}
```

### Key State

```typescript
const [section, setSection] = useState<'main' | 'partners' | 'delete'>('main');
const [partners, setPartners] = useState([]);
const [exporting, setExporting] = useState<'quick' | 'full' | null>(null);
const [deleteConfirmText, setDeleteConfirmText] = useState('');
```

---

## 2. Export API Endpoint

### `GET /api/user/export?type=quick|full`

**Quick Export** - Just assessment scores:
```json
{
  "exportDate": "2024-12-24T...",
  "user": { "email": "...", "name": "..." },
  "assessments": [{ "name": "...", "scores": {...} }]
}
```

**Full Export** - PIPEDA compliant:
```json
{
  "exportDate": "...",
  "exportType": "full_data_package",
  "pipedaCompliance": {
    "purpose": "Personal data access request",
    "dataController": "Deep Personality"
  },
  "user": { "id": "...", "email": "...", "name": "...", "created_at": "..." },
  "profiles": [...],
  "savedPartners": [...],
  "sharedProfiles": [...]
}
```

---

## 3. App.tsx Modifications

### Add to user dropdown (line ~226, after user info div):

```tsx
<button
  onClick={() => {
    setShowUserMenu(false);
    setShowSettingsModal(true);
  }}
  className="w-full flex items-center gap-2 px-4 py-2.5 text-sm text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-colors"
>
  <Settings className="w-4 h-4" />
  Settings
</button>
```

### Add state:
```tsx
const [showSettingsModal, setShowSettingsModal] = useState(false);
```

### Add modal render (after other modals):
```tsx
<SettingsModal
  isOpen={showSettingsModal}
  onClose={() => setShowSettingsModal(false)}
  onSignOut={handleSignOut}
  user={user}
/>
```

---

## 4. Implementation Details

### Reset Progress
```typescript
const handleResetProgress = () => {
  localStorage.removeItem('deep_personality_quiz_v2');
  sessionStorage.removeItem('deep_personality_is_guest');
  // Show toast/feedback
};
```

### File Download Helper
```typescript
const downloadJSON = (data: object, filename: string) => {
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
};
```

### Delete Confirmation
- User must type "delete my account" exactly
- Calls existing `/api/user/delete` endpoint
- Clears local state and reloads page

---

## 5. Existing APIs to Use

| Endpoint | Purpose |
|----------|---------|
| `GET /api/partners` | Fetch saved partners list |
| `DELETE /api/partners?id={id}` | Delete individual partner |
| `DELETE /api/user/delete` | Delete account (already exists) |

---

## 6. UI Patterns (from existing modals)

**Modal overlay:**
```tsx
className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/60 backdrop-blur-sm"
```

**Modal card:**
```tsx
className="bg-white dark:bg-slate-800 rounded-2xl p-6 max-w-md w-full mx-4 shadow-2xl max-h-[90vh] overflow-y-auto"
```

**Section header:**
```tsx
className="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-3"
```

**Action row:**
```tsx
className="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-700/30 rounded-xl hover:bg-slate-100 dark:hover:bg-slate-700/50 transition-colors cursor-pointer"
```

**Danger button:**
```tsx
className="w-full px-4 py-3 bg-red-600 text-white rounded-xl font-semibold hover:bg-red-700"
```

---

## 7. Icons Needed (Lucide)

```tsx
import { Settings, Download, Trash2, LogOut, RefreshCw, Users, ChevronRight, ArrowLeft, AlertTriangle, X, Loader2 } from 'lucide-react';
```

---

## Implementation Order

1. Create `SettingsModal.tsx` with main view layout
2. Add modal state and dropdown link to `App.tsx`
3. Implement Sign Out button (uses existing handler)
4. Implement Reset Progress
5. Create `/api/user/export` endpoint
6. Implement export buttons with download
7. Implement partners management sub-view
8. Implement delete account confirmation sub-view

---

## Estimated Lines of Code

| File | Lines |
|------|-------|
| `SettingsModal.tsx` | ~350 |
| `app/api/user/export/route.ts` | ~80 |
| `App.tsx` modifications | ~15 |
| **Total** | ~445 |
