# Fix CSP Errors in Deep Personality

## Problem
Console errors on analyze page:
1. Google Fonts stylesheet blocked by `style-src` (x2)
2. `frame-ancestors 'none'` blocking framing (x2)

## Root Cause
**File:** `~/Deep-Personality/middleware.ts` (lines 20-30)

Current CSP:
```typescript
"style-src 'self' 'unsafe-inline'",  // Missing fonts.googleapis.com
"font-src 'self' data:",              // Missing fonts.gstatic.com
"frame-ancestors 'none'",             // Blocking third-party iframes
```

## Investigation Findings
The frame-ancestors errors come from **Vercel Analytics**, **Speed Insights**, or **Botid** bot protection attempting iframe-based tracking. These services have fallback mechanisms and work fine without iframes. The CSP is correctly blocking them.

## Recommended Fix

### 1. Allow Google Fonts (Required)
Edit `middleware.ts` lines 23 and 25:
```typescript
"style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
"font-src 'self' data: https://fonts.gstatic.com",
```

### 2. Frame-ancestors (No change)
Keep `frame-ancestors 'none'` - the errors are benign noise from third-party analytics trying iframe tracking. The security benefit of blocking clickjacking outweighs hiding console warnings.

## File to Modify
- `~/Deep-Personality/middleware.ts` - lines 23 and 25
