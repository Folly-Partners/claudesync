# Bug Fix: Profile Save Failure for Existing Users

## Problem Summary
When a user who already has a profile (andrew@tiny.com) completes the assessment again, the save fails with "Could not save to server. Your profile is stored locally as backup."

## Root Cause Analysis

### Primary Issue: UNIQUE Constraint on `email` Column
The `profiles` table has a **UNIQUE constraint on `email`**. When a user completes the assessment a second time:

1. User is authenticated → `user_id` is set
2. API calls `.insert()` on profiles table
3. Database rejects INSERT due to duplicate email
4. All 3 retry attempts fail with the same constraint violation
5. Client shows "Could not save to server" error

### Code Path
```
Wizard.tsx (ResultsStep)
  → POST /api/complete
    → supabase.from('profiles').insert(insertData)  ← FAILS HERE
      → UNIQUE constraint violation on email
```

### Evidence
- `/app/api/complete/route.ts` line 385: Uses `.insert()` not `.upsert()`
- `/app/api/save-progress/route.ts` lines 30-37: Queries by email alone (assumes uniqueness)
- `/app/api/admin/import/route.ts` lines 81-97: Returns 409 on duplicate email

## Solution Options

### Option A: Use UPSERT (Recommended)
Change `.insert()` to `.upsert()` with conflict resolution on email:
```typescript
const { data, error } = await supabase
  .from('profiles')
  .upsert(insertData, {
    onConflict: 'email',
    ignoreDuplicates: false  // Update existing record
  })
  .select()
  .single();
```

**Pros:** Simple, one-line change, preserves single profile per email
**Cons:** Overwrites existing profile (may not want this)

### Option B: Check-then-Update Pattern
1. Query for existing profile by email/user_id
2. If exists: UPDATE the record
3. If not exists: INSERT new record

**Pros:** More control over update logic
**Cons:** Two database calls, race condition possible

### Option C: Allow Multiple Profiles (Schema Change)
Remove UNIQUE constraint on email, add versioning:
```sql
ALTER TABLE profiles DROP CONSTRAINT profiles_email_key;
ALTER TABLE profiles ADD COLUMN version INTEGER DEFAULT 1;
```

**Pros:** Preserves history of all assessments
**Cons:** Schema migration required, more complex queries

## Chosen Approach: Archive Old + Insert New (Keep History)

User confirmed:
- Keep old profiles accessible (archive them)
- Schema columns may not exist
- Show current profile only in UI (history hidden by default)
- Only archive raw assessment data, not AI analysis (regenerate on-demand)

### Strategy
1. **Remove UNIQUE constraint on email** (via migration)
2. Mark existing profile(s) as `is_current: false`
3. Insert new profile with `is_current: true`
4. Add `version` column to track assessment number

### Files to Modify

**1. `/app/api/complete/route.ts`** (lines 383-398)
```typescript
// Step 1: Archive any existing profiles for this email
await supabase
  .from('profiles')
  .update({ is_current: false })
  .eq('email', profileEmail);

// Step 2: Count existing profiles for version number
const { count } = await supabase
  .from('profiles')
  .select('*', { count: 'exact', head: true })
  .eq('email', profileEmail);

// Step 3: Insert new profile as current
const { data, error } = await supabase
  .from('profiles')
  .insert({
    ...insertData,
    is_current: true,
    version: (count || 0) + 1,
  })
  .select()
  .single();
```

**2. Database Migration** (new file in `/supabase/migrations/`)
```sql
-- Remove unique constraint on email to allow multiple profiles
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_email_key;

-- Add columns for versioning
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_current BOOLEAN DEFAULT true;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Index for fast lookup of current profile
CREATE INDEX IF NOT EXISTS idx_profiles_email_current
ON profiles(email, is_current) WHERE is_current = true;
```

**3. Update profile queries** (various files)
- `/app/api/profiles/route.ts` - Filter by `is_current: true` for default view
- Add option to view profile history

### Database Schema After Migration
```
profiles:
  - email TEXT (no longer unique)
  - is_current BOOLEAN DEFAULT true
  - version INTEGER DEFAULT 1
  - updated_at TIMESTAMPTZ
  ... (existing columns)
```

## Risk Assessment
- **Medium risk**: Schema migration required
- **Data preserved**: Old profiles remain accessible
- **Query updates**: Need to filter by `is_current` in some places
- **Rollback**: Can re-add unique constraint if needed

## Deployment Steps

1. **Run migration in Supabase dashboard** (SQL Editor)
   - Copy the SQL migration above
   - Execute in production Supabase

2. **Deploy code changes** to Vercel
   - Update `/app/api/complete/route.ts`
   - Update any queries that need `is_current` filter

3. **Test** with andrew@tiny.com account

## Testing Plan
1. After migration: Verify existing profiles have `is_current=true`, `version=1`
2. New user → INSERT (version=1, is_current=true)
3. Existing user retakes → Old marked is_current=false, new INSERT (version=2, is_current=true)
4. Verify andrew@tiny.com can complete without error
5. Verify old profile history is accessible via API
