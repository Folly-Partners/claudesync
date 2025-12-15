# Current Tasks

## Task 1: Remove Test Save Button & Clean Test Data

### Changes
1. Remove `testSaving` state and `handleTestSave` function (lines 679-709)
2. Remove Test Save button from UI (lines 1860-1866)
3. Delete `app/api/test-save/route.ts` file

### SQL to run in Supabase:
```sql
DELETE FROM profiles WHERE user_id = (SELECT id FROM auth.users WHERE email = 'andrew@tiny.com');
```

---

## Task 2: Rename Alex → Alexa

Line 172: Change `"name": "Alex"` to `"name": "Alexa"`
Also update UI button text around lines 2044-2051.

---

## Task 3: Auto-Save Comparison Profiles

When a comparison profile is uploaded, automatically save it (no checkbox).
Modify the `handleDrop` function around line 1080 and file input handler.

---

## Task 4: Fix Export Profile Button Layout

Add `flex-shrink-0` to prevent buttons from shrinking when name is long.
Line 1590: Add `flex-shrink-0` class to button.

---

## Task 5: Store Real Profiles

### Andrew's profile:
Insert from `/Users/andrewwilkinson/Deep-Personality/profiles/andrew@tiny.com_2025-12-12T01-45-27-707Z.json`

### Zoe as saved partner:
Insert from `/Users/andrewwilkinson/Deep-Personality/profiles/zolpeterson@gmail.com_2025-12-12T02-10-05-157Z.json`

---

## Task 6: Security Hardening for Psychological Data (CRITICAL)

### Current Security Posture Assessment

| Layer | Current Status | Risk Level |
|-------|----------------|------------|
| Transport (HTTPS) | ✅ Vercel SSL | Low |
| Authentication | ✅ Supabase Auth (Google OAuth, email) | Low |
| Row-Level Security | ✅ RLS Policies on all tables | Low |
| Encryption at Rest | ⚠️ Supabase default AES-256 | Medium |
| Field-Level Encryption | ❌ None - sensitive data in plaintext | **HIGH** |
| Audit Logging | ❌ No access logs | Medium |
| Data Export/Deletion | ❌ No GDPR endpoints | Medium |
| Rate Limiting | ✅ Implemented | Low |

### Sensitive Data Classification (HIGHLY CONFIDENTIAL)

**Level 1 - Maximum Sensitivity (Weaponizable):**
- Dark Triad scores (Machiavellianism, Narcissism, Psychopathy)
- Suicidal ideation flags
- PTSD indicators
- AI psychological analysis/dossiers

**Level 2 - High Sensitivity (Medical/Mental Health):**
- Anxiety scores (GAD-7)
- Depression scores (PHQ-9)
- ACE scores (childhood trauma)
- Personality disorder cluster scores
- Emotional dysregulation scores

**Level 3 - Moderate Sensitivity (Personal):**
- Big Five personality traits
- Attachment styles
- Values and motivations
- Relationship satisfaction scores

### Recommended Security Enhancements

#### TIER 1: IMMEDIATE (Must Implement)

**A. Audit Logging**
```sql
CREATE TABLE audit_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_user ON audit_log(user_id);
CREATE INDEX idx_audit_time ON audit_log(created_at);
```

**B. GDPR Data Export/Delete API**
```
GET /api/user/data - Export all user data as JSON
DELETE /api/user/data - Permanently delete all user data
```

**C. Remove Sensitive Data from Share Links**
Never include in shared profiles:
- `_admin.darkTriad`
- `_admin.aiAnalysis`
- Mental health scores (GAD-7, PHQ-9, PCL-5, ACE)

#### TIER 2: IMPORTANT (Should Implement)

**D. Client-Side Encryption for Level 1 Data**
- Encrypt `_admin` field before storage
- User's key derived from session, never stored on server
- Server cannot decrypt without active user session

**E. Sensitive Data Separation**
- Move Level 1 data to separate `sensitive_assessments` table
- Stricter RLS policies
- Access only through audited functions

**F. Session Security Hardening**
- Shorter session duration (4 hours vs 7 days)
- Re-authentication required for viewing Dark Triad/AI analysis
- "Sensitive data accessed" email notifications

#### TIER 3: BEST PRACTICE (Nice to Have)

**G. Zero-Knowledge Architecture**
- User encryption key from password hash
- Even database admins cannot read sensitive fields

**H. Anomaly Detection**
- Alert on bulk data exports
- Multiple failed auth attempts
- Unusual access patterns

### Compliance Considerations

**HIPAA (if healthcare context):**
- Would need BAA with Supabase
- Encryption requirements met with Tier 2
- Audit logging required (Tier 1)

**GDPR (if EU users):**
- Right to access ✅ Need Tier 1B
- Right to deletion ✅ Need Tier 1B
- Data portability ✅ Need Tier 1B
- Consent management ⚠️ Currently implicit

### Implementation Priority

| Priority | Task | Effort | Impact |
|----------|------|--------|--------|
| 1 | Remove sensitive data from shares | 1 hour | High |
| 2 | Audit logging table | 2 hours | High |
| 3 | GDPR data export/delete | 3 hours | High |
| 4 | Client-side encryption | 8 hours | Very High |
| 5 | Sensitive data separation | 4 hours | High |

---

## COMPLETED (Previous Session)

---

## Task 2: Filter AI Analysis by Relationship Type (NEW)

### Problem
When user selects a focus area (romantic/work/friend), the AI analysis still includes ALL sections (friends, work partners, romantic). User wants **only relevant sections** shown.

### Current Behavior
- `relationshipType` passed to chunks but only adds "extra depth" to selected section
- All chunks still generated regardless of selection

### Solution: Filter Chunks Based on `relationshipType`

**File**: `app/api/analyze-parallel/route.ts`

In `getComparisonChunks()` function, filter which chunks are generated:

```typescript
function getComparisonChunks(nameA: string, nameB: string, relationshipType: string): ChunkDefinition[] {
  const allChunks = [
    { id: 'overview', ... },   // Always include
    { id: 'friends', ... },    // Skip if relationshipType === 'romantic' or 'work'
    { id: 'work', ... },       // Skip if relationshipType === 'romantic' or 'friend'
    { id: 'romantic', ... },   // Skip if relationshipType === 'work' or 'friend'
    { id: 'conflict', ... },   // Always include
    { id: 'toolkit', ... },    // Always include
  ];

  // Filter based on relationship type
  return allChunks.filter(chunk => {
    if (relationshipType === 'romantic') {
      return !['friends', 'work'].includes(chunk.id);
    }
    if (relationshipType === 'work') {
      return !['friends', 'romantic'].includes(chunk.id);
    }
    if (relationshipType === 'friend') {
      return !['work', 'romantic'].includes(chunk.id);
    }
    // 'everything' or default - include all
    return true;
  });
}
```

**Also update function call** at line 790:
```typescript
// OLD:
const chunks = isComparison
  ? getComparisonChunks(nameA, nameB)
  : getIndividualChunks(nameA);

// NEW:
const chunks = isComparison
  ? getComparisonChunks(nameA, nameB, relationshipType)
  : getIndividualChunks(nameA);
```

### Filtering Logic
| relationshipType | Include Chunks |
|------------------|----------------|
| `romantic` | overview, romantic, conflict, toolkit |
| `work` | overview, work, conflict, toolkit |
| `friend` | overview, friends, conflict, toolkit |
| `everything` | ALL chunks |

---

## Task 1 Details: Life Satisfaction Bars

### Visual Before/After

**Before (sparse):**
```
┌─────────────────────┐  ┌─────────────────────┐
│ ● Alex              │  │ ● Sam               │
│   28        4       │  │   18        7       │
│   Sat.    Lonely    │  │   Sat.    Lonely    │
└─────────────────────┘  └─────────────────────┘
           [lots of empty space]
```

**After (rich bars like PERMA):**
```
Life Satisfaction (SWLS)
Alex  ████████████████████████████░░░░░  28 Satisfied
Sam   ██████████████████░░░░░░░░░░░░░░░  18 Slightly Satisfied

Loneliness (UCLA-3)
Alex  ████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  4 Not Lonely
Sam   ███████░░░░░░░░░░░░░░░░░░░░░░░░░░  7 Moderate
```

---

## Implementation

### File: `components/Visualizations.tsx`

**Replace lines 1700-1758** (the comparison mode section of `WellbeingGauges`):

```tsx
// Comparison mode
if (profileB) {
  return (
    <div className="space-y-5">
      {/* Life Satisfaction Comparison */}
      {(swlsA || swlsB) && (
        <div>
          <h5 className="text-xs font-semibold text-slate-500 dark:text-slate-400 mb-3 uppercase tracking-wider">
            Life Satisfaction (SWLS)
          </h5>
          <div className="space-y-2">
            {/* Profile A bar */}
            <div className="flex items-center gap-3">
              <div className="w-16 flex items-center gap-2">
                <div className="w-2.5 h-2.5 bg-blue-500 rounded-full flex-shrink-0" />
                <span className="text-xs font-medium text-slate-600 dark:text-slate-400 truncate">{profileA.name}</span>
              </div>
              <div className="flex-1 h-5 bg-slate-100 dark:bg-slate-700 rounded-full overflow-hidden">
                <div
                  className="h-full bg-blue-500 rounded-full transition-all"
                  style={{ width: `${((swlsA?.score || 0) / 35) * 100}%` }}
                />
              </div>
              <div className="w-24 text-right flex items-baseline gap-1">
                <span className="text-base font-bold" style={{ color: getSWLSColor(swlsA?.score || 0) }}>
                  {swlsA?.score ?? '-'}
                </span>
                <span className="text-[10px] text-slate-500 dark:text-slate-400">{swlsA?.label || ''}</span>
              </div>
            </div>
            {/* Profile B bar */}
            <div className="flex items-center gap-3">
              <div className="w-16 flex items-center gap-2">
                <div className="w-2.5 h-2.5 bg-teal-500 rounded-full flex-shrink-0" />
                <span className="text-xs font-medium text-slate-600 dark:text-slate-400 truncate">{profileB.name}</span>
              </div>
              <div className="flex-1 h-5 bg-slate-100 dark:bg-slate-700 rounded-full overflow-hidden">
                <div
                  className="h-full bg-teal-500 rounded-full transition-all"
                  style={{ width: `${((swlsB?.score || 0) / 35) * 100}%` }}
                />
              </div>
              <div className="w-24 text-right flex items-baseline gap-1">
                <span className="text-base font-bold" style={{ color: getSWLSColor(swlsB?.score || 0) }}>
                  {swlsB?.score ?? '-'}
                </span>
                <span className="text-[10px] text-slate-500 dark:text-slate-400">{swlsB?.label || ''}</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Loneliness Comparison */}
      {(uclaA || uclaB) && (
        <div>
          <h5 className="text-xs font-semibold text-slate-500 dark:text-slate-400 mb-3 uppercase tracking-wider">
            Loneliness (UCLA-3)
          </h5>
          <div className="space-y-2">
            {/* Profile A bar */}
            <div className="flex items-center gap-3">
              <div className="w-16 flex items-center gap-2">
                <div className="w-2.5 h-2.5 bg-blue-500 rounded-full flex-shrink-0" />
                <span className="text-xs font-medium text-slate-600 dark:text-slate-400 truncate">{profileA.name}</span>
              </div>
              <div className="flex-1 h-5 bg-slate-100 dark:bg-slate-700 rounded-full overflow-hidden">
                <div
                  className="h-full bg-blue-500 rounded-full transition-all"
                  style={{ width: `${((uclaA?.score || 0) / 9) * 100}%` }}
                />
              </div>
              <div className="w-24 text-right flex items-baseline gap-1">
                <span className="text-base font-bold" style={{ color: getUCLAColor(uclaA?.score || 0) }}>
                  {uclaA?.score ?? '-'}
                </span>
                <span className="text-[10px] text-slate-500 dark:text-slate-400">{uclaA?.label || ''}</span>
              </div>
            </div>
            {/* Profile B bar */}
            <div className="flex items-center gap-3">
              <div className="w-16 flex items-center gap-2">
                <div className="w-2.5 h-2.5 bg-teal-500 rounded-full flex-shrink-0" />
                <span className="text-xs font-medium text-slate-600 dark:text-slate-400 truncate">{profileB.name}</span>
              </div>
              <div className="flex-1 h-5 bg-slate-100 dark:bg-slate-700 rounded-full overflow-hidden">
                <div
                  className="h-full bg-teal-500 rounded-full transition-all"
                  style={{ width: `${((uclaB?.score || 0) / 9) * 100}%` }}
                />
              </div>
              <div className="w-24 text-right flex items-baseline gap-1">
                <span className="text-base font-bold" style={{ color: getUCLAColor(uclaB?.score || 0) }}>
                  {uclaB?.score ?? '-'}
                </span>
                <span className="text-[10px] text-slate-500 dark:text-slate-400">{uclaB?.label || ''}</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Interpretation note */}
      <div className="bg-slate-50 dark:bg-slate-700/50 border border-slate-200 dark:border-slate-600 rounded-lg p-3 text-xs text-slate-600 dark:text-slate-400">
        <strong>Note:</strong> Higher life satisfaction is better. Lower loneliness scores indicate less loneliness.
      </div>
    </div>
  );
}
```

---

## Files to Modify

| File | Lines | Change |
|------|-------|--------|
| `components/Visualizations.tsx` | 1700-1758 | Replace sparse card layout with horizontal bar comparison |

---

## Benefits
1. **Visual consistency** with PERMA chart style
2. **Easier comparison** at a glance via bar lengths
3. **No empty space** - content fills the area naturally
4. **Color-coded scores** maintained for interpretation

---

## Task 3: Profile Storage & Auto-Load Feature (NEW)

### Current State (Already Implemented!)
- **Authentication**: Google OAuth, email/password, magic link via Supabase ✓
- **Profile Storage**: `profiles` table saves assessments linked to `user_id` ✓
- **Historical Profiles**: Dashboard loads `pastAssessments` for logged-in users ✓
- **Profile Loading**: `/api/profiles` endpoint retrieves user's saved profiles ✓

### What's Missing

**1. Auto-Load Default Profile in Analysis Mode**
When user is logged in, automatically load their most recent profile for AI analysis instead of requiring manual selection.

**2. Store Comparison Profiles (Partners)**
Save uploaded partner profiles so users don't have to re-upload them each time.

### Implementation

#### A. Auto-Load Profile (Dashboard.tsx)
When user is authenticated and has saved profiles, automatically set the most recent as `selectedProfileA`:

```typescript
// In Dashboard.tsx auth state change handler (around line 490)
if (session?.user) {
  const res = await fetch('/api/profiles');
  const data = await res.json();
  setPastAssessments(data.profiles || []);

  // NEW: Auto-set most recent profile if none selected
  if (data.profiles?.length > 0 && !selectedProfileA) {
    setSelectedProfileA(data.profiles[0]);
  }
}
```

#### B. Store Partner Profiles (New DB Table + API)

**New Table: `saved_partners`**
```sql
CREATE TABLE saved_partners (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  profile_data JSONB NOT NULL,
  name TEXT NOT NULL,
  relationship_type TEXT, -- 'partner', 'friend', 'colleague'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ,
  UNIQUE(user_id, name)
);

-- RLS policy
ALTER TABLE saved_partners ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own partners" ON saved_partners
  FOR ALL USING (auth.uid() = user_id);
```

**New API: `/api/partners`**
```typescript
// GET - List user's saved partners
// POST - Save a new partner profile
// DELETE - Remove a saved partner
```

**Update Dashboard.tsx:**
- When user uploads partner profile for comparison, offer to save it
- Show dropdown of saved partners when selecting comparison profile
- "Remember this person" checkbox when uploading

### Files to Modify

| File | Change |
|------|--------|
| `supabase/migrations/002_saved_partners.sql` | **NEW** - Create saved_partners table |
| `app/api/partners/route.ts` | **NEW** - CRUD API for partner profiles |
| `components/Dashboard.tsx` | Auto-load profile, saved partners dropdown |

---

## Files to Modify (All Tasks)

| File | Lines | Change |
|------|-------|--------|
| `components/Visualizations.tsx` | 1700-1758 | Task 1: Replace sparse cards with horizontal bar comparisons |
| `app/api/analyze-parallel/route.ts` | 400, 790 | Task 2: Add relationshipType filter to getComparisonChunks() |
| `supabase/migrations/002_saved_partners.sql` | NEW | Task 3: Create saved_partners table |
| `app/api/partners/route.ts` | NEW | Task 3: CRUD API for partner profiles |
| `components/Dashboard.tsx` | ~490 | Task 3: Auto-load profile, saved partners UI |
