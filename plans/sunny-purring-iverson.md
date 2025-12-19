# Plan: Admin PDF Download & Regenerate Analysis Feature

## Overview
Add two new capabilities to the admin page (`/admin`):
1. **Download PDF** - Download any user's AI analysis as a professionally formatted PDF
2. **Regenerate** - Regenerate the AI analysis for any user (with streaming progress)

## Files to Modify/Create

| File | Action | Purpose |
|------|--------|---------|
| `/app/admin/page.tsx` | Modify | Add PDF/Regenerate buttons, handlers, progress modal |
| `/app/api/admin/regenerate/route.ts` | **Create** | Admin-only endpoint for regenerating analysis |

## Implementation Details

### 1. Admin Page Changes (`/app/admin/page.tsx`)

**New imports:**
- `FileText`, `RefreshCw` icons from lucide-react

**New state:**
```typescript
const [pdfDownloadingId, setPdfDownloadingId] = useState<string | null>(null);
const [regeneratingId, setRegeneratingId] = useState<string | null>(null);
const [regeneratingProgress, setRegeneratingProgress] = useState<string>('');
```

**New functions:**

1. `markdownToHtml(md: string)` - Copy from Dashboard.tsx lines 1707-1787
2. `handleDownloadPDF(profile: Profile)` - Adapted from Dashboard.tsx lines 1324-1704
   - Checks if profile has `ai_analysis`
   - Opens print window with formatted HTML
   - Uses same cover page and styling as Dashboard
3. `handleRegenerate(profileId: string, profileName: string)` - New function
   - Calls `/api/admin/regenerate` with streaming
   - Shows progress modal during generation
   - Updates local state on completion

**UI changes:**
- Add PDF and Regenerate buttons in Actions column (next to JSON button)
- Add progress modal for regeneration (shows streaming status)
- Disable buttons appropriately (no analysis = no PDF, no assessments = no regen)

### 2. New API Endpoint (`/app/api/admin/regenerate/route.ts`)

**Security:** Admin-only (same pattern as `/api/admin/profiles/route.ts`)

**Flow:**
1. Verify admin authentication via session + ADMIN_EMAILS check
2. Get `profileId` from request body
3. Fetch full profile using service role client (bypasses RLS)
4. Validate profile has assessments
5. Strip dark triad data (same as existing analyze endpoint)
6. Call Anthropic API with streaming (reuse prompts from `/api/analyze`)
7. Save result to `profiles.ai_analysis`
8. Clear analysis_cache for this profile
9. Return streaming response to client

**Response format:** SSE with STATUS: and analysis text (same as `/api/analyze`)

## UI Design

**Action buttons in table row:**
```
[JSON] [PDF] [Regen]
```

**Button states:**
- PDF disabled + tooltip if no `ai_analysis`
- Regen disabled + tooltip if no `assessments`
- Loading spinner when in progress

**Regeneration modal:**
- Fixed overlay with progress message
- Shows streaming status updates
- Auto-closes on completion

## Edge Cases Handled

1. **No AI analysis** - PDF button disabled with "No AI analysis available" tooltip
2. **No assessments** - Regen button disabled with "No assessments to analyze" tooltip
3. **Stream error** - Show error message in modal, allow retry
4. **Concurrent actions** - Disable row during any operation

## Dependencies

No new packages needed. Uses:
- Browser print dialog for PDF (existing pattern)
- Anthropic API for analysis (existing)
- Supabase service client (existing)

## Critical Reference Files

- `/components/Dashboard.tsx:1324-1787` - PDF generation + markdownToHtml
- `/app/api/analyze/route.ts` - Streaming pattern + prompts
- `/app/api/admin/profiles/route.ts` - Admin auth pattern
- `/lib/supabase/service.ts` - Service role client
