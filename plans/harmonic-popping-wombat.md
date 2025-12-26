# Overstory Codebase Analysis

## Critical Issues (Fix Immediately)

### 1. XSS Vulnerability
- **File:** `components/pipeline/content-editor.tsx:157`
- **Issue:** `dangerouslySetInnerHTML` with unsanitized markdown preview
- **Fix:** Use DOMPurify or similar sanitization library

### 2. Unhandled JSON Parse Errors
- **File:** `app/api/moderation/action/route.ts:34`
- **File:** `app/api/pipeline/stream/route.ts:55`
- **Issue:** `JSON.parse()` without try-catch crashes requests on malformed data
- **Fix:** Wrap in try-catch with fallback handling

### 3. Missing Stripe Refund on Rejection
- **File:** `app/api/moderation/action/route.ts:50`
- **Issue:** TODO comment - rejected ads don't trigger refunds
- **Fix:** Implement Stripe refund API call

### 4. Race Condition in Pipeline Jobs
- **File:** `app/api/pipeline/run/route.ts:44-60`
- **Issue:** No locking between job existence check and creation
- **Fix:** Add atomic check-and-create or database lock

---

## High Priority Issues

### Error Handling
| File | Line | Issue |
|------|------|-------|
| `api/pipeline/run/route.ts` | 59-60 | Fire-and-forget async without error propagation |
| `api/bookings/create/route.ts` | 114-122 | Silent moderation trigger failure |
| `api/moderation/review/route.ts` | 107-108 | Unsafe type assertion on message.content |
| `api/pipeline/stream/route.ts` | 68-77 | No max timeout for polling loop |

### Missing Input Validation
| File | Line | Issue |
|------|------|-------|
| `api/bookings/create/route.ts` | 29-35 | Empty strings pass validation, no email/URL format check |
| `api/pipeline/save/route.ts` | 16-25 | Path traversal possible via symlinks |

---

## Performance Issues

### N+1 Queries
- `app/moderation/page.tsx:39-59` - 3 sequential queries, should batch
- `app/revenue/page.tsx:37-95` - 4 separate queries + JS aggregation

### Missing Memoization (causing re-renders)
- `components/pipeline/streaming-output.tsx:74` - onComplete dependency
- `components/pipeline/pipeline-controller.tsx:76,111` - runStage/cancelJob recreated
- `components/pipeline/activity-feed.tsx:80,163` - parseOutputToActivities not debounced

### Missing Loading States
- `app/revenue/page.tsx` - No skeleton during data fetch
- `app/moderation/page.tsx` - No loading state
- No Suspense boundaries anywhere

### Large Unvirtualized Lists
- `app/[pub]/publication-tabs.tsx:177,206,260` - All stories/events rendered at once
- `app/moderation/page.tsx:139-258` - All pending items, no pagination
- `app/revenue/page.tsx:247-273` - All bookings in table

---

## Code Quality Issues

### Duplicated Constants (extract to lib/constants.ts)
- Publication colors: `moderation/page.tsx:22-34`, `revenue/page.tsx:7-19`, `advertise/page.tsx:39-44`
- Publication config: hardcoded in multiple API routes

### Type Safety
- `lib/data.ts:73-79` - `Record<string, object>` too generic
- `app/moderation/page.tsx:141,217` - JSON.parse without type validation
- No zod/validation library for API schemas

### Resource Management
- `lib/db.ts:14-24` - DB connection never closed, no error recovery
- `lib/process-tracker.ts` - Potential memory leak from stale Map entries
- 19 console.log statements should use proper logger

---

## Quick Wins (< 2 hours each)

1. **Wrap JSON.parse calls in try-catch** (30 min)
2. **Add useCallback to pipeline event handlers** (1 hr)
3. **Extract publication constants to shared file** (30 min)
4. **Add DOMPurify for markdown preview** (1 hr)
5. **Add basic input validation (email, URL format)** (1 hr)
6. **Add pagination to moderation page** (2 hrs)

---

## Files Most Needing Attention

1. `app/api/moderation/action/route.ts` - Missing refunds, unsafe JSON parse
2. `components/pipeline/content-editor.tsx` - XSS vulnerability
3. `app/api/pipeline/run/route.ts` - Race condition, fire-and-forget async
4. `app/moderation/page.tsx` - No pagination, duplicated constants
5. `lib/db.ts` - Connection management, string concatenation for output

---

## Implementation Order

### Phase 1: Critical Security & Stability
1. Add DOMPurify for XSS protection in `content-editor.tsx`
2. Wrap all JSON.parse calls in try-catch (3 files)
3. Implement Stripe refund on rejection in `moderation/action/route.ts`
4. Add locking mechanism for pipeline job creation

### Phase 2: Error Handling & Validation
5. Add proper error propagation in `pipeline/run/route.ts`
6. Add retry/notification for failed moderation triggers
7. Fix unsafe type assertions in moderation review
8. Add max timeout to stream polling
9. Add input validation (email, URL, empty string checks)
10. Improve path traversal protection with normalize()
11. Add rate limiting consideration (document for future)

### Phase 3: Performance
12. Batch database queries in moderation page
13. Batch database queries in revenue page
14. Add useCallback to pipeline components (4 files)
15. Add debouncing to parseOutputToActivities
16. Add Suspense boundaries and loading skeletons
17. Add pagination to moderation page
18. Add pagination to revenue page
19. Consider virtualization for large lists (document)

### Phase 4: Code Quality
20. Extract publication constants to `lib/constants.ts`
21. Add proper TypeScript types for database results
22. Add zod validation schemas for API routes
23. Add proper DB connection cleanup
24. Replace console.logs with structured logger
25. Clean up process tracker memory management
26. Remove dead code and unused patterns
27. Standardize API response format
28. Fix naming inconsistencies

---

## Files to Modify

| File | Changes |
|------|---------|
| `components/pipeline/content-editor.tsx` | Add DOMPurify |
| `app/api/moderation/action/route.ts` | JSON try-catch, Stripe refund |
| `app/api/pipeline/stream/route.ts` | JSON try-catch, max timeout |
| `app/api/pipeline/run/route.ts` | Error propagation, job locking |
| `app/api/bookings/create/route.ts` | Input validation |
| `app/api/pipeline/save/route.ts` | Path validation |
| `app/api/moderation/review/route.ts` | Type safety |
| `app/moderation/page.tsx` | Pagination, constants |
| `app/revenue/page.tsx` | Batch queries, pagination |
| `components/pipeline/streaming-output.tsx` | useCallback |
| `components/pipeline/pipeline-controller.tsx` | useCallback |
| `components/pipeline/activity-feed.tsx` | useCallback, debounce |
| `lib/constants.ts` | NEW - shared constants |
| `lib/db.ts` | Connection cleanup |
| `lib/data.ts` | TypeScript types |
| `lib/process-tracker.ts` | Memory cleanup |

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 4 |
| High | 8 |
| Medium | 15 |
| Low | 12 |

**Total: 39 issues to fix**
