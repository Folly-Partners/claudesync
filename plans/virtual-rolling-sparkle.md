# Plan: Save Comparison AI Analysis (Like Individual Analysis)

## Problem
When comparing two profiles, the AI analysis regenerates every time instead of loading saved analysis. Individual profile analysis correctly saves and loads from DB, but comparison analysis doesn't follow the same pattern.

## Current Behavior

**Individual Analysis (works correctly):**
- When profile loads, `aiAnalysis` is fetched from DB and auto-displayed
- Saved to `profiles.ai_analysis` column (permanent)
- User sees saved analysis immediately without regeneration

**Comparison Analysis (broken):**
- When loading a **saved partner**, compatibility analysis loads correctly (lines 688-696)
- Saved to `saved_partners.compatibility_analysis` after generation
- BUT: `handleAiAnalysis()` doesn't check for existing saved analysis before making API call
- Clicking "Analyze" always regenerates, even when valid saved analysis exists

## Root Cause
Two issues:

1. **savedPartners state is incomplete** (Dashboard.tsx:418)
   - Only stores: `{ id, name, relationship_type }`
   - Missing: `compatibilityAnalysis`, `compatibilityProfileId`

2. **GET /api/partners doesn't return compatibility data** (partners/route.ts:17)
   - Only returns: `id, name, relationship_type, created_at, last_used_at`
   - Missing: `compatibility_analysis`, `compatibility_profile_id`

3. **handleAiAnalysis() doesn't check for existing saved analysis**
   - Immediately makes API call without checking if analysis already exists

## Solution

**Key Decision:** Store separate analyses per relationship type using JSONB column `compatibility_analyses` (plural) with structure:
```json
{
  "romantic": { "analysis": "...", "profileId": "...", "updatedAt": "..." },
  "work": { "analysis": "...", "profileId": "...", "updatedAt": "..." },
  "friend": { "analysis": "...", "profileId": "...", "updatedAt": "..." },
  "everything": { "analysis": "...", "profileId": "...", "updatedAt": "..." }
}
```

### Step 1: Database Migration

**File: `supabase/migrations/005_compatibility_analyses.sql`**

```sql
-- Add JSONB column for storing multiple analyses per relationship type
ALTER TABLE saved_partners
ADD COLUMN IF NOT EXISTS compatibility_analyses JSONB DEFAULT '{}';

-- Migrate existing data from old columns (if they exist)
UPDATE saved_partners
SET compatibility_analyses = jsonb_build_object(
  COALESCE(relationship_type, 'everything'),
  jsonb_build_object(
    'analysis', compatibility_analysis,
    'profileId', compatibility_profile_id,
    'updatedAt', compatibility_updated_at
  )
)
WHERE compatibility_analysis IS NOT NULL;

-- Drop old columns (optional, can keep for backward compat)
-- ALTER TABLE saved_partners DROP COLUMN compatibility_analysis;
-- ALTER TABLE saved_partners DROP COLUMN compatibility_profile_id;
-- ALTER TABLE saved_partners DROP COLUMN compatibility_updated_at;
```

### Step 2: Update savedPartners type and API

**File: `components/Dashboard.tsx` (line ~418)**

```typescript
interface CompatibilityEntry {
  analysis: string;
  profileId: string;
  updatedAt: string;
}

const [savedPartners, setSavedPartners] = useState<{
  id: string;
  name: string;
  relationship_type: string | null;
  compatibilityAnalyses?: Record<string, CompatibilityEntry>;
}[]>([]);
```

**File: `app/api/partners/route.ts`**

GET endpoint (line ~17):
```typescript
.select('id, name, relationship_type, created_at, last_used_at, compatibility_analyses')
```

Return (line ~26):
```typescript
return NextResponse.json({
  success: true,
  partners: (partners || []).map(p => ({
    ...p,
    compatibilityAnalyses: p.compatibility_analyses || {}
  }))
});
```

PATCH endpoint - update to save to JSONB:
```typescript
const updateData = {
  compatibility_analyses: {
    ...existingAnalyses,
    [relationshipType]: {
      analysis: compatibilityAnalysis,
      profileId: profileId,
      updatedAt: new Date().toISOString()
    }
  }
};
```

POST (get partner) - return all analyses:
```typescript
return NextResponse.json({
  success: true,
  partner: partner.profile_data,
  compatibilityAnalyses: partner.compatibility_analyses || {},
  partnerId: partner.id
});
```

### Step 3: Add pre-check in handleAiAnalysis

**File: `components/Dashboard.tsx` (line ~1789)**

```typescript
const handleAiAnalysis = async (forceRefresh: boolean = false) => {
  if (!profileA) return;

  // Check for saved compatibility analysis before regenerating
  if (!forceRefresh && profileB) {
    const partnerId = savedAnalysisPartnerId ||
      savedPartners.find(p => p.name === profileB.name)?.id;

    if (partnerId) {
      const partner = savedPartners.find(p => p.id === partnerId);
      const savedEntry = partner?.compatibilityAnalyses?.[relationshipType];

      if (savedEntry?.analysis &&
          savedEntry.analysis.length > 100 &&
          savedEntry.profileId === profileA?.id) {
        // Use saved analysis instead of regenerating
        setAiResponse(savedEntry.analysis);
        setIsSavedAnalysis(true);
        setSavedAnalysisPartnerId(partnerId);
        return; // Skip API call
      }
    }
  }

  // ... rest of existing code
```

### Step 4: Update savedPartners after saving

**File: `components/Dashboard.tsx` (line ~2023-2028)**

```typescript
if (saveRes.ok) {
  setIsSavedAnalysis(true);
  setSavedAnalysisPartnerId(partnerIdToSave);

  // Update savedPartners with the new compatibility analysis
  setSavedPartners(prev => prev.map(p =>
    p.id === partnerIdToSave
      ? {
          ...p,
          compatibilityAnalyses: {
            ...p.compatibilityAnalyses,
            [relationshipType]: {
              analysis: receivedAnalysisText,
              profileId: profileA.id,
              updatedAt: new Date().toISOString()
            }
          }
        }
      : p
  ));
}
```

### Step 5: Update loadSavedPartner

**File: `components/Dashboard.tsx` (line ~688-696)**

When loading a saved partner, check for analysis matching current relationshipType:

```typescript
if (data.compatibilityAnalyses) {
  const savedEntry = data.compatibilityAnalyses[relationshipType];
  if (savedEntry?.analysis &&
      savedEntry.analysis.length > 100 &&
      savedEntry.profileId === profileA?.id) {
    setAiResponse(savedEntry.analysis);
    setIsSavedAnalysis(true);
    setSavedAnalysisPartnerId(data.partnerId);
  }
}
```

## Files to Modify

1. **`~/Deep-Personality/supabase/migrations/005_compatibility_analyses.sql`** (NEW)
   - Add `compatibility_analyses` JSONB column
   - Migrate existing data

2. **`~/Deep-Personality/components/Dashboard.tsx`**
   - Line ~418: Update savedPartners type with `compatibilityAnalyses`
   - Line ~688-696: Update loadSavedPartner to use new structure
   - Line ~1789: Add pre-check in `handleAiAnalysis()`
   - Line ~2023: Update savedPartners state after saving

3. **`~/Deep-Personality/app/api/partners/route.ts`**
   - GET: Add compatibility_analyses to select
   - POST (get partner): Return compatibilityAnalyses
   - PATCH: Save to JSONB structure with relationship type key

## Testing

1. Load two profiles, run comparison (romantic) - should generate and save
2. Click Analyze again (romantic) - should load saved instantly
3. Change to "work" - should regenerate (different type)
4. Click Analyze again (work) - should load saved work analysis
5. Switch back to "romantic" - should load saved romantic analysis
6. Force refresh - should regenerate and overwrite
7. Reload page - should load from DB correctly
