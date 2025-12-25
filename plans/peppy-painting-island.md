# Plan: Save Guest Profiles to Database

## Summary
Enable guest users to provide a name/alias and save their assessment results to the database, visible on the admin page.

## Changes Required

### 1. Database Migration (Run Automatically)
**Approach:** Create a Node.js script to run SQL directly via Postgres connection.

**Prerequisite:** Need `DATABASE_URL` from Supabase Dashboard → Settings → Database → Connection string (URI format)

**File:** `scripts/migrate-guest-profiles.js` (temporary, delete after running)

```javascript
const { Client } = require('pg');

async function migrate() {
  const client = new Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  await client.connect();

  await client.query(`
    ALTER TABLE profiles ALTER COLUMN user_id DROP NOT NULL;
    ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_guest BOOLEAN DEFAULT false;
    CREATE INDEX IF NOT EXISTS idx_profiles_is_guest ON profiles(is_guest);
  `);

  console.log('Migration complete!');
  await client.end();
}
migrate();
```

**Run:**
```bash
npm install pg
DATABASE_URL="postgresql://postgres:PASSWORD@db.isacmcgxnldcvlbnkurb.supabase.co:5432/postgres" node scripts/migrate-guest-profiles.js
```
*(Replace PASSWORD with actual database password)*

### 2. StartAssessmentModal.tsx
**File:** `components/StartAssessmentModal.tsx`

The `name` state already exists (line 18). Changes needed:

- **Line 126-141**: Update `handleGuestContinue()` to require name:
  ```typescript
  if (!name.trim()) {
    setError('Please enter your name or alias')
    return
  }
  sessionStorage.setItem('deep_personality_guest_name', name.trim())
  ```

- **After line 251**: Show name field for guest mode (currently only shows for signup):
  ```tsx
  {mode === 'guest' && (
    <div>
      <label>Name <span className="text-red-500">*</span></label>
      <input value={name} onChange={(e) => setName(e.target.value)} required />
    </div>
  )}
  ```

- **Line 292**: Update disabled condition:
  ```typescript
  disabled={... || (mode === 'guest' && !name.trim())}
  ```

- **Line 336**: Clear name when switching to guest mode:
  ```typescript
  onClick={() => { setMode('guest'); ...; setName(''); }}
  ```

### 3. Wizard.tsx
**File:** `components/Wizard.tsx`

Around line 1060, read guest name from sessionStorage:
```typescript
const guestName = sessionStorage.getItem('deep_personality_guest_name') || '';
const mergedBasicInfo = {
  ...basicInfo,
  name: (basicInfo.name || user?.user_metadata?.name || guestName || '').trim(),
  ...
};
```

Around line 462, pass `isGuest` flag to API:
```typescript
const isGuest = sessionStorage.getItem('deep_personality_is_guest') === 'true';
body: JSON.stringify({ profile, rawAnswers, userId: user?.id || null, isGuest })
```

### 4. app/api/complete/route.ts
**File:** `app/api/complete/route.ts`

- **~Line 143**: Extract `isGuest` from request body
- **Lines 344-376**: Update save logic to handle guests:
  ```typescript
  if (userId || isGuest) {
    const insertData = {
      name: profile.name,
      email: ...,
      is_guest: isGuest || false,
      // ... other fields
    };
    if (userId) insertData.user_id = userId;  // Only for auth users

    await supabase.from('profiles').insert(insertData)...
  }
  ```

### 5. app/api/admin/profiles/route.ts
**File:** `app/api/admin/profiles/route.ts`

Update SELECT query to include `is_guest`:
```typescript
.select('id, user_id, name, email, age, created_at, assessments, dark_triad, ai_analysis, is_guest')
```

### 6. app/admin/page.tsx
**File:** `app/admin/page.tsx`

- Update `Profile` interface to include `is_guest: boolean`
- Add "Guest" badge in the status column for guest profiles:
  ```tsx
  {profile.is_guest && (
    <span className="... bg-slate-100 text-slate-600">Guest</span>
  )}
  ```

## Implementation Order
1. Database migration (must run first)
2. StartAssessmentModal.tsx (collect guest name)
3. Wizard.tsx (pass guest info to API)
4. app/api/complete/route.ts (save guest profiles)
5. app/api/admin/profiles/route.ts (include is_guest in query)
6. app/admin/page.tsx (show guest badge)

## Files to Modify
- `supabase/migrations/011_guest_profiles.sql` (new)
- `components/StartAssessmentModal.tsx`
- `components/Wizard.tsx`
- `app/api/complete/route.ts`
- `app/api/admin/profiles/route.ts`
- `app/admin/page.tsx`
