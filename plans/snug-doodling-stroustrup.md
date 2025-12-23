# Deep Personality - Pre-Release Fixes (Small Instance: 2GB/2-core)

## CRITICAL (Fix Now)

### 1. Purchases RLS Leak
`supabase/migrations/006_billing.sql` - Anyone can read ALL purchases
```sql
DROP POLICY "Allow read access" ON purchases;
CREATE POLICY "Users read own" ON purchases FOR SELECT USING (email = auth.jwt()->>'email');
```

### 2. Add Checkout Rate Limit
`middleware.ts:37` - Add:
```typescript
'/api/checkout': { maxRequests: 5, methods: ['POST'] },
```

### 3. Sanitize Markdown Links (XSS)
`app/api/complete/route.ts:50` - Change link replacement to:
```typescript
html = html.replace(/\[([^\]]+)\]\(([^\)]+)\)/g, (m, text, url) => {
  if (url.startsWith('javascript:') || url.startsWith('data:')) return text;
  return `<a href="${url}">${text}</a>`;
});
```

### 4. Generic AI Error Messages
`app/api/complete/route.ts:241-244` - Don't expose `e.message`

---

## HIGH (Fix Before Heavy Traffic)

### 5. Rate Limit DB Bottleneck ⚠️
`middleware.ts` hits Supabase on EVERY request. With 2GB/2-core this will choke.
**Options:**
- Move to Vercel KV ($0 for 30k req/day)
- Or add in-memory cache (Map) with 60s TTL

### 6. Add Timeout to Wizard Fetch
`components/Wizard.tsx:392` - Add 30s abort controller

### 7. Missing Index
```sql
CREATE INDEX idx_saved_partners_last_used ON saved_partners(last_used_at DESC NULLS LAST);
```

---

## MANUAL CHECKS

- [ ] Supabase: RLS enabled on `profiles` table?
- [ ] Supabase: Connection pooling ON (Dashboard → Settings → Database)
- [ ] Supabase: "Leaked Password Protection" enabled

---

## Files to Change

| File | Change |
|------|--------|
| `migrations/009_fixes.sql` | Purchases RLS, index |
| `middleware.ts` | Checkout rate limit |
| `app/api/complete/route.ts` | XSS fix, generic errors |
| `components/Wizard.tsx` | Timeout |
