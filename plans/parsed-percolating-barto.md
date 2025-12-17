# Plan: Deploy Email Triage on Supabase + Vercel (Insanely Fast)

## Overview

Deploy the email triage app on Supabase + Vercel with a multi-layer caching architecture designed for maximum speed. The goal is sub-100ms UI responses with intelligent server-side caching that eliminates redundant AI calls.

## Current Architecture (Problems)

- **28 AI API routes** using Anthropic SDK (Node.js only, no Edge)
- **IndexedDB only** - no cross-device sync, lost on browser clear
- **Client-side OAuth tokens** - security risk, no server-side refresh
- **No persistent cache** - AI results recomputed on every session
- **6 parallel AI calls per email** - expensive, slow for new emails

## Target Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER DEVICE                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐          │
│  │  IndexedDB  │    │   React +   │    │   Service   │          │
│  │  (Offline)  │◄──►│   Zustand   │◄──►│   Worker    │          │
│  └─────────────┘    └──────┬──────┘    └─────────────┘          │
└────────────────────────────┼────────────────────────────────────┘
                             │
┌────────────────────────────┼────────────────────────────────────┐
│                    VERCEL EDGE NETWORK                          │
│  ┌─────────────┐    ┌──────┴──────┐    ┌─────────────┐          │
│  │ Edge Cache  │    │   Vercel    │    │  Vercel KV  │          │
│  │  (Static)   │    │  Functions  │    │  (Redis)    │          │
│  └─────────────┘    └──────┬──────┘    └─────────────┘          │
└────────────────────────────┼────────────────────────────────────┘
                             │
┌────────────────────────────┼────────────────────────────────────┐
│                        SUPABASE                                  │
│  ┌─────────────┐    ┌──────┴──────┐    ┌─────────────┐          │
│  │  Auth +     │    │  PostgreSQL │    │  Realtime   │          │
│  │  Tokens     │    │  (Patterns) │    │  (Sync)     │          │
│  └─────────────┘    └─────────────┘    └─────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Supabase Setup

### 1.1 Database Schema

**Core Tables:**

```sql
-- Users (linked to Supabase Auth)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- OAuth tokens (encrypted, server-side only)
CREATE TABLE oauth_tokens (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  access_token_encrypted TEXT NOT NULL,
  refresh_token_encrypted TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  gmail_email TEXT NOT NULL
);

-- Email analysis cache (cross-device, 4hr TTL)
CREATE TABLE email_analysis_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  email_id TEXT NOT NULL,
  summary TEXT,
  adaptive_summary JSONB,
  decision JSONB,
  priority JSONB,
  reply_options JSONB,
  questions JSONB,
  sender_intelligence JSONB,
  cached_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '4 hours'),
  UNIQUE(user_id, email_id)
);

-- Learned patterns (persisted across devices)
CREATE TABLE learned_patterns (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  writing_style JSONB DEFAULT '{}',
  action_patterns JSONB DEFAULT '{}',
  contacts JSONB DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ultra-deep patterns (voice profiles, examples)
CREATE TABLE ultra_deep_patterns (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  writing_style JSONB DEFAULT '{}',
  formality_spectrum JSONB DEFAULT '{}',
  recipient_profiles JSONB DEFAULT '[]',
  example_replies JSONB DEFAULT '[]',
  analyzed_at TIMESTAMPTZ,
  emails_analyzed INTEGER DEFAULT 0
);

-- Action history (for learning loop)
CREATE TABLE action_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  email_id TEXT NOT NULL,
  action_type TEXT NOT NULL,
  ai_suggested JSONB,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes for Speed:**
```sql
CREATE INDEX idx_cache_user_email ON email_analysis_cache(user_id, email_id);
CREATE INDEX idx_cache_expires ON email_analysis_cache(expires_at);
CREATE INDEX idx_actions_user ON action_history(user_id, timestamp DESC);
```

**RLS Policies:**
```sql
ALTER TABLE email_analysis_cache ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users access own cache" ON email_analysis_cache
  FOR ALL USING (auth.uid() = user_id);
-- Same for all tables
```

### 1.2 Files to Create

| File | Purpose |
|------|---------|
| `/lib/supabase/client.ts` | Browser Supabase client |
| `/lib/supabase/server.ts` | Server Supabase client with service role |
| `/lib/supabase/schema.sql` | Full database schema |
| `/lib/auth/tokenStorage.ts` | Encrypted token storage/refresh |

---

## Phase 2: Authentication Migration

### 2.1 Replace Gmail OAuth with Supabase Auth + Google

**Current Flow:**
```
User → Google OAuth → Client stores tokens in IndexedDB
```

**New Flow:**
```
User → Supabase Auth (Google provider) → Server stores encrypted tokens
```

### 2.2 Files to Modify

| File | Changes |
|------|---------|
| `/app/setup/page.tsx` | Use Supabase Auth signInWithOAuth |
| `/app/api/auth/callback/route.ts` | Handle Supabase callback, store tokens |
| `/app/api/auth/refresh/route.ts` | Server-side token refresh from Supabase |
| `/lib/gmail/client.ts` | Fetch access token from server, not IndexedDB |
| `/middleware.ts` | NEW: Protect routes, verify session |

### 2.3 Implementation

```typescript
// lib/supabase/auth.ts
export async function signInWithGoogle() {
  const supabase = createBrowserClient();
  return supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      scopes: 'https://www.googleapis.com/auth/gmail.readonly ...',
      redirectTo: `${origin}/api/auth/callback`,
      queryParams: { access_type: 'offline', prompt: 'consent' }
    }
  });
}
```

---

## Phase 3: Multi-Layer Caching

### 3.1 Cache Hierarchy (Fastest → Slowest)

1. **React State** (0ms) - Current email's data
2. **IndexedDB** (1-5ms) - Offline-first local cache
3. **Vercel KV/Redis** (10-50ms) - Hot session data, pending writes
4. **Supabase PostgreSQL** (50-150ms) - Persistent cross-device cache
5. **AI API** (1-5s) - Only when all caches miss

### 3.2 Cache Lookup Strategy

```typescript
async function getEmailAnalysis(userId: string, emailId: string) {
  // 1. Check IndexedDB (instant)
  const local = await db.prefetchCache.get(emailId);
  if (local && !isExpired(local)) return local;

  // 2. Check Vercel KV (fast)
  const redis = await kv.get(`analysis:${userId}:${emailId}`);
  if (redis) {
    await db.prefetchCache.put(redis); // Sync to local
    return redis;
  }

  // 3. Check Supabase (slower but persistent)
  const { data } = await supabase
    .from('email_analysis_cache')
    .select('*')
    .eq('user_id', userId)
    .eq('email_id', emailId)
    .single();

  if (data) {
    await kv.set(`analysis:${userId}:${emailId}`, data, { ex: 3600 });
    await db.prefetchCache.put(data);
    return data;
  }

  // 4. Cache miss - fetch from AI
  return null;
}
```

### 3.3 Write-Through Strategy

```typescript
// After AI generates analysis
async function cacheAnalysis(userId: string, emailId: string, result: any) {
  // Write to all layers in parallel
  await Promise.all([
    db.prefetchCache.put({ emailId, ...result, cachedAt: Date.now() }),
    kv.set(`analysis:${userId}:${emailId}`, result, { ex: 14400 }), // 4hrs
    supabase.from('email_analysis_cache').upsert({
      user_id: userId,
      email_id: emailId,
      ...result
    })
  ]);
}
```

### 3.4 Files to Create/Modify

| File | Changes |
|------|---------|
| `/lib/cache/multi-layer.ts` | NEW: Unified cache lookup |
| `/lib/cache/redis.ts` | NEW: Vercel KV helpers |
| `/lib/storage/syncedDb.ts` | Modify db.ts to sync with Supabase |
| `/lib/prefetch/emailPrefetcher.ts` | Use multi-layer cache |

---

## Phase 4: Vercel Deployment Config

### 4.1 Runtime Configuration

**Edge Runtime (fast cold start, global):**
- `/api/auth/*` - OAuth flows
- `/api/gmail/labels` - Simple proxy
- `/api/google/contacts` - Simple proxy

**Node.js Runtime (required for Anthropic SDK):**
- `/api/ai/*` - All AI routes (SDK doesn't support Edge)

### 4.2 Streaming for Long AI Responses

Add streaming to slow routes for perceived performance:

```typescript
// /api/ai/generate-replies-stream/route.ts
export async function POST(req: Request) {
  const stream = new TransformStream();
  const writer = stream.writable.getWriter();

  // Stream tokens as they arrive
  const response = await anthropic.messages.create({
    model: 'claude-haiku-4-5-20251001',
    stream: true,
    messages: [...]
  });

  for await (const event of response) {
    if (event.type === 'content_block_delta') {
      await writer.write(encode(event.delta.text));
    }
  }

  return new Response(stream.readable, {
    headers: { 'Content-Type': 'text/event-stream' }
  });
}
```

### 4.3 Configuration Files

**next.config.ts:**
```typescript
export default {
  experimental: { ppr: true },
  headers: async () => [{
    source: '/:path*.(js|css|png)',
    headers: [{ key: 'Cache-Control', value: 'public, max-age=31536000, immutable' }]
  }]
};
```

**vercel.json:**
```json
{
  "functions": {
    "app/api/ai/**/*.ts": { "maxDuration": 60 }
  },
  "crons": [{
    "path": "/api/cron/cleanup-cache",
    "schedule": "0 */6 * * *"
  }]
}
```

---

## Phase 5: Performance Optimizations

### 5.1 Parallel Data Fetching

Fetch all cache layers simultaneously, use first response:

```typescript
const result = await Promise.race([
  getFromIndexedDB(emailId).then(r => r || SKIP),
  getFromRedis(userId, emailId).then(r => r || SKIP),
  getFromSupabase(userId, emailId).then(r => r || SKIP)
].filter(p => p !== SKIP));
```

### 5.2 Optimistic UI Updates

Archive immediately in UI, sync to server in background:

```typescript
const handleArchive = async () => {
  // Instant UI update
  setEmailQueue(prev => prev.filter(e => e.id !== currentEmail.id));
  moveToNextEmail();

  // Background sync (don't await)
  archiveOnServer(currentEmail.id).catch(rollback);
};
```

### 5.3 Batch Cache Persistence

Queue AI results in Redis, batch-write to Supabase every 30s:

```typescript
// In Vercel KV - queue pending writes
await kv.lpush(`pending:${userId}`, { emailId, result, ts: Date.now() });

// Cron job or on session end - batch persist
const pending = await kv.lrange(`pending:${userId}`, 0, -1);
await supabase.from('email_analysis_cache').upsert(pending);
await kv.del(`pending:${userId}`);
```

---

## Implementation Order (Speed MVP)

**Goal: Deploy to Vercel ASAP, add Supabase caching progressively**

### Day 1: Deploy to Vercel (No Changes)
1. [ ] `vercel` CLI deploy as-is
2. [ ] Configure env vars (ANTHROPIC_API_KEY, GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET)
3. [ ] Test on production URL
4. [ ] Fix any deployment issues

### Day 2: Basic Optimization
5. [ ] Create `vercel.json` with `maxDuration: 60` for AI routes
6. [ ] Update `next.config.ts` with static asset caching headers
7. [ ] Redeploy and verify AI routes work

### Day 3: Supabase Setup
8. [ ] Create Supabase project
9. [ ] Run schema.sql (just `email_analysis_cache` + `learned_patterns` tables)
10. [ ] Create `/lib/supabase/client.ts` (minimal client)
11. [ ] Add `@supabase/supabase-js` to package.json

### Day 4: Server-Side Cache
12. [ ] Create `/lib/cache/supabase-cache.ts` - simple read/write helpers
13. [ ] Update `/lib/prefetch/emailPrefetcher.ts`:
    - On cache hit from IndexedDB → return immediately
    - On cache miss → check Supabase before calling AI
    - After AI call → write to both IndexedDB AND Supabase
14. [ ] Test: Clear IndexedDB, verify Supabase cache works

### Day 5: Cross-Device Sync
15. [ ] On page load: fetch patterns from Supabase → merge with IndexedDB
16. [ ] After sync completes: push patterns to Supabase
17. [ ] Add simple "Last synced" indicator in UI

### Future (Post-MVP):
- [ ] Auth migration to Supabase Auth
- [ ] Vercel KV for hot session data
- [ ] Streaming AI responses
- [ ] Cron cleanup jobs

---

## Environment Variables (Vercel)

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# Google OAuth (keep existing)
NEXT_PUBLIC_GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# Anthropic (keep existing)
ANTHROPIC_API_KEY=

# Vercel KV (auto-configured)
KV_URL=
KV_REST_API_URL=
KV_REST_API_TOKEN=

# Security
TOKEN_ENCRYPTION_KEY=  # openssl rand -hex 32
CRON_SECRET=
```

---

## Expected Performance Gains

| Metric | Current | Target |
|--------|---------|--------|
| First email load (cached) | 500ms | <100ms |
| First email load (uncached) | 3-5s | 1-2s (streaming) |
| Cross-device sync | None | Instant |
| Cache hit rate | ~30% | >80% |
| Cold start | 2-3s | <500ms (Edge routes) |

---

## Files Summary

### New Files
- `/lib/supabase/client.ts`
- `/lib/supabase/server.ts`
- `/lib/supabase/schema.sql`
- `/lib/auth/tokenStorage.ts`
- `/lib/cache/redis.ts`
- `/lib/cache/multi-layer.ts`
- `/middleware.ts`
- `/vercel.json`
- `/app/api/cron/cleanup-cache/route.ts`

### Modified Files
- `/app/setup/page.tsx` - Supabase Auth
- `/app/api/auth/callback/route.ts` - Supabase callback
- `/app/api/auth/refresh/route.ts` - Server-side refresh
- `/lib/gmail/client.ts` - Server token fetch
- `/lib/storage/db.ts` - Sync with Supabase
- `/lib/prefetch/emailPrefetcher.ts` - Multi-layer cache
- `/next.config.ts` - Caching headers
- `/package.json` - Add @supabase/supabase-js, @vercel/kv
