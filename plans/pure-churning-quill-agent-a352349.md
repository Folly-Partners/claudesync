# Saved Company Analyses - UI/UX Design Plan

## Executive Summary

This plan designs a comprehensive saved analyses management system for Dealhunter, allowing users to save, search, and load previous company analyses. The design follows the existing design system (Claude/Anthropic-inspired styling) and integrates seamlessly with the current 4-step flow.

---

## 1. Overall Architecture & Navigation

### Current Flow
```
Login → Input → Upload → Analyzing → Results
```

### New Flow with Saved Analyses
```
Login → Dashboard (Saved Analyses) → Input → Upload → Analyzing → Results
                ↓                                                      ↓
                ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ←
```

### Navigation Strategy: **Dashboard-First Approach**

**Rationale:**
- Users likely return to review/compare previous analyses
- Common workflow: "Check what I analyzed before" → "Start new analysis"
- Mirrors typical SaaS patterns (dashboard → action)

**Implementation:**
1. **Dashboard as landing page** after login (new `/dashboard` route or modify `/` to show dashboard)
2. **"New Analysis" button** prominently placed in dashboard header
3. **Results page** has "Back to Dashboard" option alongside "New Analysis"

---

## 2. Database Schema & Storage

### Storage Approach: **Browser-based with future server upgrade path**

**Phase 1: IndexedDB (Browser Storage)**
- No backend changes required
- Instant implementation
- Data persists per-browser
- ~50MB+ storage capacity (sufficient for 100+ analyses)

**Schema:**

```typescript
interface SavedAnalysis {
  id: string;                          // UUID
  companyName: string;
  location: string;
  industry?: string;
  
  // Metadata
  createdAt: Date;
  updatedAt: Date;
  lastViewedAt?: Date;
  isFavorite?: boolean;
  tags?: string[];                     // User-added tags for categorization
  notes?: string;                      // User notes
  
  // Full analysis data
  result: AnalysisResult;
  
  // State when saved
  assumptions: EditableAssumptions;
  debtConfig: DebtConfiguration;
  birdInHandInputs: BirdInHandInputs;
  twoInBushInputs: TwoInBushInputs;
  uploadedDocuments: UploadedDocument[];
  
  // Quick preview data (denormalized for list view)
  preview: {
    valuationRange: {
      low: number;
      high: number;
    };
    ebitda?: number;
    revenue?: number;
    thumbnailSummary: string;          // First 200 chars of summary
  };
}
```

**Phase 2: Server Storage (Future)**
- Migrate to API endpoint: `POST /api/analyses`
- Enables multi-device sync
- User accounts
- Sharing capabilities

---

## 3. Dashboard UI Component Design

### 3.1 Dashboard Layout Structure

```
┌─────────────────────────────────────────────────────────┐
│ Header: Dealhunter Logo | Search | New Analysis | Logout│
├─────────────────────────────────────────────────────────┤
│                                                         │
│  [Empty State OR Analytics Summary]                     │
│                                                         │
├─────────────────────────────────────────────────────────┤
│ Filters:  [All | Favorites]  Sort: [Most Recent ▾]     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────────────────────────────────────────┐     │
│  │ 🏢 Company Name              $2.5M - $3.8M    │     │
│  │ San Francisco, CA • Technology               │     │
│  │ Analyzed Dec 15, 2024                        │     │
│  │ "Leading provider of cloud infrastructure..." │     │
│  │ [Load] [Export PDF] [⋮ More]                 │     │
│  └───────────────────────────────────────────────┘     │
│                                                         │
│  ┌───────────────────────────────────────────────┐     │
│  │ 🏢 Another Company           $800K - $1.2M    │     │
│  │ ...                                          │     │
│  └───────────────────────────────────────────────┘     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 3.2 Component Breakdown

#### **DashboardPage Component** (`/app/dashboard/page.tsx`)

**Responsibilities:**
- Fetch saved analyses from IndexedDB
- Render list with search/filter
- Handle CRUD operations

**State:**
```typescript
interface DashboardState {
  analyses: SavedAnalysis[];
  filteredAnalyses: SavedAnalysis[];
  searchQuery: string;
  sortBy: 'recent' | 'name' | 'valuation';
  filterBy: 'all' | 'favorites';
  loading: boolean;
  selectedAnalysis?: SavedAnalysis;
  showDeleteConfirm?: string;  // Analysis ID to delete
}
```

#### **AnalysisCard Component** (`/components/AnalysisCard.tsx`)

**Design Specs:**
```tsx
<div className="rounded-xl p-5 transition-all hover:shadow-lg"
     style={{ 
       backgroundColor: 'var(--background-alt)', 
       border: '1px solid var(--border)' 
     }}>
  
  {/* Header Row */}
  <div className="flex items-start justify-between mb-3">
    <div className="flex-1">
      <h3 className="text-lg font-semibold" 
          style={{ fontFamily: 'var(--font-serif)', color: 'var(--foreground)' }}>
        {companyName}
      </h3>
      <p className="text-sm" style={{ color: 'var(--foreground-muted)' }}>
        {location} • {industry}
      </p>
    </div>
    
    {/* Favorite Star */}
    <button onClick={toggleFavorite} className="ml-3">
      {isFavorite ? '⭐' : '☆'}
    </button>
  </div>
  
  {/* Valuation Badge */}
  <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg mb-3"
       style={{ backgroundColor: 'var(--accent-light)' }}>
    <span className="text-sm font-medium" style={{ color: 'var(--accent-hover)' }}>
      {formatCurrency(valuationLow)} - {formatCurrency(valuationHigh)}
    </span>
  </div>
  
  {/* Summary Preview */}
  <p className="text-sm mb-4 line-clamp-2" 
     style={{ color: 'var(--foreground-muted)' }}>
    {thumbnailSummary}
  </p>
  
  {/* Metadata Row */}
  <div className="flex items-center gap-4 mb-4 text-xs"
       style={{ color: 'var(--foreground-subtle)' }}>
    <span>📅 {formatDate(createdAt)}</span>
    {uploadedDocuments.length > 0 && (
      <span>📄 {uploadedDocuments.length} docs</span>
    )}
  </div>
  
  {/* Action Buttons */}
  <div className="flex gap-2">
    <button onClick={handleLoad}
            className="flex-1 py-2 px-4 rounded-lg font-medium"
            style={{ backgroundColor: 'var(--accent)', color: 'white' }}>
      Load Analysis
    </button>
    
    <button onClick={handleExportPDF}
            className="py-2 px-3 rounded-lg"
            style={{ border: '1px solid var(--border)' }}>
      📥
    </button>
    
    <MoreMenu onDuplicate={handleDuplicate} 
              onDelete={handleDelete}
              onAddNote={handleAddNote} />
  </div>
</div>
```

**Card Variants:**
1. **Standard Card** - Default view shown above
2. **Compact Card** - For mobile/narrow screens (stacks vertically)
3. **Grid View** - Optional 2-column grid on large screens

#### **EmptyState Component**

**Design:**
```tsx
<div className="text-center py-16">
  <div className="inline-flex items-center justify-center w-20 h-20 rounded-full mb-6"
       style={{ backgroundColor: 'var(--accent-light)' }}>
    <span className="text-4xl">🎯</span>
  </div>
  
  <h2 className="text-2xl font-semibold mb-3"
      style={{ fontFamily: 'var(--font-serif)', color: 'var(--foreground)' }}>
    No Analyses Yet
  </h2>
  
  <p className="text-base mb-8" style={{ color: 'var(--foreground-muted)' }}>
    Start by analyzing your first company
  </p>
  
  <button onClick={handleNewAnalysis}
          className="px-6 py-3 rounded-lg font-medium"
          style={{ backgroundColor: 'var(--accent)', color: 'white' }}>
    Analyze a Company
  </button>
</div>
```

---

## 4. Search & Filter Implementation

### 4.1 Search Component

**Location:** Dashboard header (always visible)

**Design:**
```tsx
<div className="relative flex-1 max-w-md">
  <input
    type="text"
    placeholder="Search companies..."
    value={searchQuery}
    onChange={handleSearch}
    className="w-full pl-10 pr-4 py-2.5 rounded-lg"
    style={{
      backgroundColor: 'var(--background)',
      border: '1px solid var(--border)',
      color: 'var(--foreground)',
    }}
  />
  <svg className="absolute left-3 top-3 w-5 h-5" 
       style={{ color: 'var(--foreground-muted)' }}>
    {/* Search icon */}
  </svg>
</div>
```

**Search Algorithm:**
- Fuzzy match on: `companyName`, `location`, `industry`, `tags[]`, `notes`
- Real-time filtering (debounced 300ms)
- Highlight matches in results

### 4.2 Filter & Sort Controls

**Filters:**
1. **All Analyses** (default)
2. **Favorites** ⭐

**Sort Options:**
1. **Most Recent** (default) - `updatedAt DESC`
2. **Company Name** (A-Z) - `companyName ASC`
3. **Valuation** (High to Low) - `valuationHigh DESC`

**UI Pattern:**
```tsx
<div className="flex items-center gap-4 mb-6">
  {/* Filter Tabs */}
  <div className="flex gap-2">
    <button className={filterBy === 'all' ? 'active' : ''}>All</button>
    <button className={filterBy === 'favorites' ? 'active' : ''}>⭐ Favorites</button>
  </div>
  
  {/* Sort Dropdown */}
  <select value={sortBy} onChange={handleSort}
          className="px-3 py-2 rounded-lg"
          style={{ border: '1px solid var(--border)' }}>
    <option value="recent">Most Recent</option>
    <option value="name">Name (A-Z)</option>
    <option value="valuation">Valuation (High-Low)</option>
  </select>
</div>
```

---

## 5. Save Flow & Auto-Save

### 5.1 When to Save?

**Approach: Hybrid (Manual + Auto-save)**

**Manual Save Triggers:**
1. **User clicks "Save" button** in Results view
2. **User clicks "New Analysis"** → Prompt: "Save current analysis before starting new one?"

**Auto-save Triggers:**
1. **On assumption changes** - Debounced auto-save after 2 seconds of inactivity
2. **On document upload** - Save immediately after re-analysis completes
3. **Before navigation away** - Browser `beforeunload` event

### 5.2 Save Button Design

**Location:** AnalysisReport header, next to Export buttons

```tsx
<button
  onClick={handleSave}
  className="px-4 py-2.5 rounded-lg font-medium transition-colors flex items-center gap-2"
  style={{ 
    backgroundColor: isSaved ? 'var(--success-light)' : 'var(--accent)',
    color: isSaved ? 'var(--success)' : 'white',
    border: isSaved ? '1px solid var(--success)' : 'none'
  }}>
  {isSaved ? (
    <>
      <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
        <path d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/>
      </svg>
      Saved
    </>
  ) : (
    <>
      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4"/>
      </svg>
      Save Analysis
    </>
  )}
</button>
```

**State Management:**
```typescript
interface SaveState {
  currentAnalysisId?: string;  // null = unsaved, string = saved
  isSaving: boolean;
  lastSavedAt?: Date;
  hasUnsavedChanges: boolean;
}
```

### 5.3 Save Confirmation Modal (Optional)

For first-time saves, show a modal to add optional metadata:

```tsx
<Modal title="Save Analysis">
  <input 
    placeholder="Add tags (optional)" 
    value={tags}
    onChange={setTags}
  />
  <textarea 
    placeholder="Add notes (optional)"
    value={notes}
    onChange={setNotes}
  />
  
  <div className="flex gap-3">
    <button onClick={handleQuickSave}>Save</button>
    <button onClick={handleCancel}>Cancel</button>
  </div>
</Modal>
```

---

## 6. Load Flow

### 6.1 User Clicks "Load Analysis" from Dashboard

**Behavior:**
1. Navigate to `/` (main page)
2. Set `step = 'results'`
3. Populate all state from saved analysis:
   - `result`
   - `assumptions`
   - `debtConfig`
   - `birdInHandInputs`
   - `twoInBushInputs`
   - `uploadedDocuments`
   - `companyName`, `location`
4. Set `currentAnalysisId` for subsequent saves
5. Update `lastViewedAt` in IndexedDB

**Implementation in `page.tsx`:**
```typescript
// Add to Home component state
const [currentAnalysisId, setCurrentAnalysisId] = useState<string | null>(null);

// Listen for analysis loads from dashboard
useEffect(() => {
  const params = new URLSearchParams(window.location.search);
  const loadId = params.get('load');
  
  if (loadId) {
    loadAnalysis(loadId);
  }
}, []);

const loadAnalysis = async (id: string) => {
  const analysis = await db.getAnalysis(id);
  if (!analysis) return;
  
  setCurrentAnalysisId(id);
  setResult(analysis.result);
  setAssumptions(analysis.assumptions);
  setDebtConfig(analysis.debtConfig);
  // ... etc
  setStep('results');
  
  // Update last viewed
  await db.updateAnalysis(id, { lastViewedAt: new Date() });
};
```

### 6.2 Navigation Pattern

**URL Structure:**
- Dashboard: `/dashboard`
- New Analysis: `/` (or `/analyze`)
- Load Specific: `/?load={analysisId}`

**Back Button Behavior:**
- From Results → Dashboard (if loaded from dashboard)
- From Results → New Analysis (if fresh analysis)

---

## 7. Delete & Duplicate Actions

### 7.1 Delete Flow

**Pattern: Inline confirmation**

```tsx
{showDeleteConfirm === analysis.id ? (
  <div className="flex items-center gap-2 p-3 rounded-lg"
       style={{ backgroundColor: 'var(--error-light)' }}>
    <p className="text-sm" style={{ color: 'var(--error)' }}>
      Delete this analysis?
    </p>
    <button onClick={confirmDelete}
            className="px-3 py-1 rounded text-xs"
            style={{ backgroundColor: 'var(--error)', color: 'white' }}>
      Delete
    </button>
    <button onClick={cancelDelete}
            className="px-3 py-1 rounded text-xs"
            style={{ border: '1px solid var(--border)' }}>
      Cancel
    </button>
  </div>
) : (
  <button onClick={() => setShowDeleteConfirm(analysis.id)}>
    🗑️ Delete
  </button>
)}
```

### 7.2 Duplicate Flow

**Use Case:** User wants to create variations (e.g., different debt structures)

**Behavior:**
1. Clone analysis with new ID
2. Append " (Copy)" to company name
3. Reset `createdAt` and `updatedAt`
4. Clear `notes` and `tags`
5. Load the duplicate immediately

```typescript
const handleDuplicate = async (analysis: SavedAnalysis) => {
  const duplicate = {
    ...analysis,
    id: generateUUID(),
    companyName: `${analysis.companyName} (Copy)`,
    createdAt: new Date(),
    updatedAt: new Date(),
    notes: '',
    tags: [],
  };
  
  await db.saveAnalysis(duplicate);
  router.push(`/?load=${duplicate.id}`);
};
```

---

## 8. IndexedDB Implementation

### 8.1 Database Service (`/lib/analysisDB.ts`)

```typescript
class AnalysisDatabase {
  private db: IDBDatabase | null = null;
  
  async init(): Promise<void> {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open('DealhunterDB', 1);
      
      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve();
      };
      
      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;
        
        // Create object store
        const store = db.createObjectStore('analyses', { keyPath: 'id' });
        
        // Create indexes
        store.createIndex('companyName', 'companyName', { unique: false });
        store.createIndex('createdAt', 'createdAt', { unique: false });
        store.createIndex('updatedAt', 'updatedAt', { unique: false });
        store.createIndex('isFavorite', 'isFavorite', { unique: false });
      };
    });
  }
  
  async saveAnalysis(analysis: SavedAnalysis): Promise<void> {
    const transaction = this.db!.transaction(['analyses'], 'readwrite');
    const store = transaction.objectStore('analyses');
    await store.put(analysis);
  }
  
  async getAnalysis(id: string): Promise<SavedAnalysis | undefined> {
    const transaction = this.db!.transaction(['analyses'], 'readonly');
    const store = transaction.objectStore('analyses');
    return await store.get(id);
  }
  
  async getAllAnalyses(): Promise<SavedAnalysis[]> {
    const transaction = this.db!.transaction(['analyses'], 'readonly');
    const store = transaction.objectStore('analyses');
    return await store.getAll();
  }
  
  async deleteAnalysis(id: string): Promise<void> {
    const transaction = this.db!.transaction(['analyses'], 'readwrite');
    const store = transaction.objectStore('analyses');
    await store.delete(id);
  }
  
  async updateAnalysis(id: string, updates: Partial<SavedAnalysis>): Promise<void> {
    const existing = await this.getAnalysis(id);
    if (!existing) throw new Error('Analysis not found');
    
    const updated = { ...existing, ...updates, updatedAt: new Date() };
    await this.saveAnalysis(updated);
  }
}

export const db = new AnalysisDatabase();
```

### 8.2 Initialization

**In `app/layout.tsx`:**
```typescript
useEffect(() => {
  db.init().catch(console.error);
}, []);
```

---

## 9. Mobile Responsiveness

### 9.1 Dashboard Mobile Layout

**Changes for < 768px:**
- Single column card list
- Compact card variant
- Sticky search bar
- Bottom navigation: [Dashboard | New Analysis]

### 9.2 Card Mobile Variant

```tsx
// Mobile: Stack everything vertically
<div className="p-4">
  <h3 className="text-base mb-1">{companyName}</h3>
  <p className="text-xs mb-2">{location}</p>
  <div className="text-sm mb-3">{valuation}</div>
  <div className="flex gap-2">
    <button className="flex-1">Load</button>
    <button>⋮</button>
  </div>
</div>
```

---

## 10. Edge Cases & Error Handling

### 10.1 Quota Exceeded (IndexedDB full)

**Error UI:**
```tsx
<div className="p-4 rounded-lg mb-4" 
     style={{ backgroundColor: 'var(--error-light)', border: '1px solid var(--error)' }}>
  <p style={{ color: 'var(--error)' }}>
    Storage limit reached. Please delete old analyses.
  </p>
</div>
```

**Mitigation:**
- Show storage usage indicator
- Suggest deleting analyses older than 6 months

### 10.2 Corrupt Data

**Behavior:**
- Catch errors during load
- Show error message
- Offer to delete corrupt entry

### 10.3 Browser Incognito Mode

**Detection:**
```typescript
const isIncognito = async (): Promise<boolean> => {
  try {
    await db.init();
    return false;
  } catch (e) {
    return true;
  }
};
```

**Warning UI:**
```tsx
{isIncognito && (
  <div className="p-4 rounded-lg" style={{ backgroundColor: 'var(--accent-light)' }}>
    ⚠️ Incognito mode detected. Analyses won't be saved.
  </div>
)}
```

---

## 11. Analytics Summary (Optional Enhancement)

**Dashboard Header (above list):**

```tsx
<div className="grid grid-cols-3 gap-4 mb-8">
  <div className="p-4 rounded-xl" style={{ backgroundColor: 'var(--accent-light)' }}>
    <p className="text-sm" style={{ color: 'var(--accent)' }}>Total Analyses</p>
    <p className="text-2xl font-semibold">{totalCount}</p>
  </div>
  
  <div className="p-4 rounded-xl" style={{ backgroundColor: 'var(--success-light)' }}>
    <p className="text-sm" style={{ color: 'var(--success)' }}>Avg Valuation</p>
    <p className="text-2xl font-semibold">{avgValuation}</p>
  </div>
  
  <div className="p-4 rounded-xl" style={{ backgroundColor: 'var(--border-subtle)' }}>
    <p className="text-sm" style={{ color: 'var(--foreground-muted)' }}>This Month</p>
    <p className="text-2xl font-semibold">{thisMonthCount}</p>
  </div>
</div>
```

---

## 12. User Flow Walkthrough

### Scenario 1: First-time User
1. Login → See empty dashboard with "Analyze a Company" CTA
2. Click → Go to Input step
3. Complete analysis → See Results with "Save Analysis" button
4. Click Save → Analysis saved, button changes to "Saved ✓"
5. Click "Back to Dashboard" → See their first saved analysis card

### Scenario 2: Returning User
1. Login → Dashboard with 5 saved analyses
2. Search "Tech" → Filters to 2 tech companies
3. Click "Load" on one → Jumps to Results with all data populated
4. Edit assumptions → Auto-save triggers (debounced)
5. Click "New Analysis" → Prompt: "Save changes?" → Yes → Back to Input

### Scenario 3: Power User
1. Dashboard → 50+ analyses
2. Toggle "Favorites" filter → See 5 starred companies
3. Sort by "Valuation (High-Low)"
4. Click "⋮" on top result → "Duplicate"
5. Loads duplicate → Edit debt structure → Save as variation

---

## 13. Implementation Phases

### Phase 1: Core Functionality (MVP)
- IndexedDB service
- Dashboard with list view
- Basic save/load
- Search functionality
- Delete with confirmation

### Phase 2: Enhanced Features
- Favorites
- Sort options
- Duplicate
- Auto-save
- Tags & notes

### Phase 3: Polish
- Analytics summary
- Mobile optimization
- Export from dashboard
- Keyboard shortcuts (ESC to close modals, etc.)

### Phase 4: Server Migration (Future)
- API endpoints
- Multi-device sync
- User accounts
- Sharing

---

## 14. Testing Checklist

- [ ] Save analysis and verify in IndexedDB
- [ ] Load analysis and verify all state restored
- [ ] Search filters correctly
- [ ] Sort works for all options
- [ ] Delete removes from DB and UI
- [ ] Duplicate creates new entry
- [ ] Auto-save triggers after edits
- [ ] "Save before leaving" prompt works
- [ ] Empty state displays correctly
- [ ] Mobile layout responsive
- [ ] Quota exceeded handled gracefully
- [ ] Corrupt data doesn't crash app
- [ ] Browser back/forward work correctly

---

## 15. Future Enhancements (Post-MVP)

1. **Export Multiple Analyses** - Batch export as ZIP
2. **Comparison View** - Side-by-side compare 2 analyses
3. **Templates** - Save assumption sets as templates
4. **Collaboration** - Share analyses via link
5. **Version History** - Track changes over time
6. **AI Insights** - "You usually value tech companies at 4-6x EBITDA"
7. **Reminders** - "Check back on this deal in 30 days"
8. **Integration** - Zapier, Airtable export

