# Plan: Deprecate /api/analyze (Legacy Route)

## Overview
Remove the legacy `/api/analyze` route since all active code paths now use `/api/analyze-parallel`. No client-side code calls the legacy endpoint.

## Files to Delete
1. `app/api/analyze/route.ts` - entire legacy route (1,878 lines)

## Files to Modify

### 1. middleware.ts (line 38)
Remove rate limit entry:
```typescript
'/api/analyze': { maxRequests: 5, methods: ['POST'] },
```

### 2. instrumentation-client.ts (line 14)
Remove BotID protection rule:
```typescript
{ path: '/api/analyze', method: 'POST', advancedOptions: { checkLevel: 'deepAnalysis' } },
```

### 3. vercel.json (lines 5-7)
Remove Vercel function config:
```json
"app/api/analyze/route.ts": {
  "maxDuration": 300
},
```

### 4. README.md (lines 184, 231)
- Update line 184: Change section header from `app/api/analyze/route.ts` to `app/api/analyze-parallel/route.ts`
- Update line 231: Change instruction to reference analyze-parallel

### 5. services/analyze/prompts.ts (line 1718)
Update comment from:
```
* This is the same prompt used in /api/analyze for individual mode
```
to:
```
* This is the same prompt used in /api/analyze-parallel for individual mode
```

## Verification
- No frontend calls to `/api/analyze` exist (Dashboard.tsx uses analyze-parallel)
- No server-side calls to `/api/analyze` exist (complete/route.ts uses analyze-parallel)
- Route is completely isolated and safe to remove

## Post-Deletion
- Run `npm run build` to verify no broken imports
- Deploy to verify no 404 errors in logs (confirming nothing was calling it)
