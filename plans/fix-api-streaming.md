# Plan: Fix "Analysis completed but no response data was received" Error

## Problem Analysis

The error "Analysis completed but no response data was received" means:
- The API call starts successfully
- STATUS messages are being received (the loading spinner works)
- But the DATA payload is never received by the client
- This happens despite the new code being deployed (Export JSON button visible)

## Root Cause Hypotheses

1. **Vercel Function Timeout**: The 60s limit is being hit before DATA is sent
2. **Claude API Timeout**: The Claude API takes too long to respond
3. **Stream Corruption**: The DATA payload is being corrupted or truncated
4. **Large Response Issue**: The response is too large for the stream buffer
5. **Client-Side Parsing Bug**: The frontend isn't parsing DATA correctly

## Debugging Plan

### Phase 1: Add Comprehensive Logging (5 min)

Add timestamps and detailed logging to track exactly where the process fails:
- Log when API request starts
- Log when Claude responds
- Log response size
- Log when DATA is being written
- Log when stream closes

### Phase 2: Create Simple Test Endpoint (5 min)

Create `/api/test-analyze` that:
- Skips Claude API entirely
- Returns a mock DATA payload immediately
- Verifies the streaming mechanism works

### Phase 3: Reduce Response Size (5 min)

If Claude is responding but it's too slow:
- Reduce max_tokens to 4000 (half current)
- Shorten the system prompt
- Test with a minimal profile

### Phase 4: Add Client-Side Debug Panel (5 min)

Add visible debug info to the UI:
- Show all STATUS messages received
- Show if DATA was received
- Show response headers
- Show any errors

### Phase 5: Implement Streaming from Claude (15 min)

Instead of waiting for full response:
- Use Claude's streaming API
- Send chunks as they arrive
- This avoids the timeout entirely

## Implementation Order

1. First: Create test endpoint to verify streaming works
2. Second: Add client-side debug panel
3. Third: Reduce timeouts and response size
4. Fourth: If still failing, implement true streaming

## Success Criteria

- API analysis completes without error
- User sees personality report
- Works consistently (not intermittent)
