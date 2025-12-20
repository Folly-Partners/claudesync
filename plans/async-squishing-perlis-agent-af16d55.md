# Deep Personality Monetization Plan - Code Review

## CRITICAL ISSUES - MUST FIX BEFORE IMPLEMENTATION

### 1. TYPE SAFETY VIOLATIONS - BLOCKING

#### 1.1 Complete Absence of Types in API Routes
**Location**: All proposed API routes (`app/api/checkout/route.ts`, `app/api/webhooks/stripe/route.ts`, `app/api/check-unlock/route.ts`)

**Problem**: The plan shows NO TypeScript types. Every single variable is `any`.

```typescript
// CURRENT PLAN - FAIL
export async function POST(request: Request) {
  const { productType, productId, email } = await request.json();
  // ^ All implicitly any - what if productType is "hacker_premium"?
```

**Required**:
```typescript
// REQUIRED - Strict types
type ProductType = 'full_report' | 'comparison';

interface CheckoutRequest {
  productType: ProductType;
  productId: string;
  email: string;
}

interface CheckoutResponse {
  sessionId: string;
  url: string;
}

export async function POST(request: Request): Promise<Response> {
  const body = await request.json();

  // Runtime validation REQUIRED
  const parsed = CheckoutRequestSchema.parse(body);
  const { productType, productId, email } = parsed;

  // Now type-safe...
}
```

**Why This is Critical**:
- No validation means attackers can send `productType: "admin_bypass"`
- No types means you'll ship bugs that TypeScript should catch
- You're literally throwing away the entire value of TypeScript

**Fix Required**: Add Zod schemas for ALL request/response types. No exceptions.

---

#### 1.2 Missing Database Type Definitions

**Problem**: The migration SQL is fine, but there are ZERO TypeScript types for database records.

**Required**:
```typescript
// types/billing.ts - MUST CREATE

interface Purchase {
  id: string;
  user_id: string | null;
  email: string;
  product_type: 'full_report' | 'comparison';
  product_id: string;
  amount_cents: number;
  stripe_payment_intent_id: string | null;
  stripe_session_id: string | null;
  status: 'pending' | 'completed' | 'refunded';
  created_at: string;
}

interface UnlockedContent {
  id: string;
  user_id: string | null;
  email: string;
  content_type: 'full_report' | 'comparison';
  content_id: string;
  purchase_id: string;
  unlocked_at: string;
}

// Supabase client type augmentation
import { Database } from '@/types/supabase';

type Tables = Database['public']['Tables'];
type PurchaseRow = Tables['purchases']['Row'];
type UnlockedContentRow = Tables['unlocked_content']['Row'];
```

**Why This Matters**:
- Without types, you'll query `status: "compete"` (typo) and wonder why nothing works
- Supabase won't catch column name errors
- Refactoring becomes impossible

---

#### 1.3 Stripe Types Completely Missing

**Problem**: The plan uses Stripe SDK with ZERO type safety.

```typescript
// CURRENT PLAN - FAIL
const prices = {
  full_report: 'price_xxx',  // What if this is wrong?
  comparison: 'price_yyy'
};

const session = await stripe.checkout.sessions.create({
  mode: 'payment',
  // ... no validation that required fields exist
});
```

**Required**:
```typescript
// config/stripe.ts
import Stripe from 'stripe';

export const STRIPE_PRICE_IDS = {
  full_report: process.env.STRIPE_PRICE_ID_FULL_REPORT!,
  comparison: process.env.STRIPE_PRICE_ID_COMPARISON!,
} as const;

// Runtime validation on startup
if (!STRIPE_PRICE_IDS.full_report || !STRIPE_PRICE_IDS.comparison) {
  throw new Error('Missing required Stripe price IDs in environment');
}

type ProductType = keyof typeof STRIPE_PRICE_IDS;

// Type-safe price lookup
function getPriceId(productType: ProductType): string {
  return STRIPE_PRICE_IDS[productType];
}
```

---

### 2. SECURITY VULNERABILITIES - CRITICAL

#### 2.1 Email-Based Authentication Bypass

**Location**: Migration SQL line 52-55

```sql
CREATE POLICY "Users view own purchases" ON purchases
  FOR SELECT USING (auth.uid() = user_id OR email = auth.jwt()->>'email');
```

**CRITICAL VULNERABILITY**:

What if I'm logged in as `attacker@evil.com` and I change my email in Supabase auth to `victim@gmail.com`? I can now see all of victim's purchases.

**Why This Happens**:
- Email in JWT is user-controlled after signup
- Anyone can sign up with any email (no verification required in current flow)
- Email-based policies create a trivial bypass

**Fix Required**:
```sql
-- OPTION 1: Guest purchases use a secure token instead of email
CREATE TABLE purchases (
  -- ... existing columns ...
  guest_token UUID,  -- For non-authenticated purchases
  -- Email removed from critical queries
);

-- Authenticated users: user_id only
CREATE POLICY "Users view own purchases" ON purchases
  FOR SELECT USING (auth.uid() = user_id);

-- Guest users: token-based (passed as secure cookie)
CREATE POLICY "Guest view own purchases" ON purchases
  FOR SELECT USING (
    auth.uid() IS NULL
    AND guest_token = current_setting('app.guest_token')::uuid
  );

-- OPTION 2: Email verification required
-- Add email_verified column
-- Only allow email-based access if email_verified = true
```

**Impact**: Without this fix, any user can access any other user's purchases by knowing their email.

---

#### 2.2 No Webhook Signature Verification Error Handling

**Location**: `app/api/webhooks/stripe/route.ts`

```typescript
// CURRENT PLAN - FAIL
export async function POST(request: Request) {
  const body = await request.text();
  const sig = request.headers.get('stripe-signature')!;  // <- Asserting non-null

  const event = stripe.webhooks.constructEvent(
    body, sig, process.env.STRIPE_WEBHOOK_SECRET!
  );
  // No try/catch - if signature invalid, crashes entire route
```

**Problems**:
1. No error handling - invalid signatures crash the route
2. Attackers can spam your webhook endpoint
3. No logging of failed attempts
4. Using `!` assertions instead of proper null checks

**Required**:
```typescript
export async function POST(request: Request): Promise<Response> {
  const body = await request.text();
  const sig = request.headers.get('stripe-signature');

  if (!sig) {
    logServerEvent('Webhook: Missing signature', 'WARN');
    return Response.json({ error: 'Missing signature' }, { status: 400 });
  }

  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!webhookSecret) {
    logServerEvent('Webhook: Missing secret in env', 'ERROR');
    return Response.json({ error: 'Server misconfiguration' }, { status: 500 });
  }

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, sig, webhookSecret);
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : 'Unknown error';
    logServerEvent(`Webhook: Invalid signature - ${errorMessage}`, 'WARN');
    return Response.json({ error: 'Invalid signature' }, { status: 400 });
  }

  // Now process the event...
}
```

---

#### 2.3 Race Condition in Webhook Processing

**Location**: `app/api/webhooks/stripe/route.ts` lines 148-158

**Problem**: Webhook updates purchase THEN inserts unlock. If insert fails, purchase is marked completed but content isn't unlocked.

```typescript
// CURRENT PLAN - FAIL
// Update purchase status
await supabase.from('purchases')
  .update({ status: 'completed', stripe_payment_intent_id: session.payment_intent })
  .eq('stripe_session_id', session.id);

// Unlock content - WHAT IF THIS FAILS?
await supabase.from('unlocked_content').insert({
  email,
  content_type: productType,
  content_id: productId
});
```

**Scenarios Where This Breaks**:
1. Database constraint violation (duplicate unlock)
2. Network timeout between the two calls
3. User paid, purchase marked complete, but unlock fails silently

**Fix Required**:
```typescript
// Use Supabase RPC with transaction or error handling
try {
  // CRITICAL: Check if already unlocked first (idempotency)
  const { data: existing } = await supabase
    .from('unlocked_content')
    .select('id')
    .eq('email', email)
    .eq('content_type', productType)
    .eq('content_id', productId)
    .single();

  if (!existing) {
    // Insert unlock FIRST, then update purchase
    const { error: unlockError } = await supabase
      .from('unlocked_content')
      .insert({
        email,
        user_id: null, // Set via trigger if user exists
        content_type: productType,
        content_id: productId,
        purchase_id: purchaseId, // Must track this
      });

    if (unlockError) {
      logServerEvent(`Failed to unlock content: ${unlockError.message}`, 'ERROR');
      // DO NOT mark purchase complete if unlock fails
      return Response.json({ error: 'Unlock failed' }, { status: 500 });
    }
  }

  // Only AFTER unlock succeeds, mark purchase complete
  const { error: purchaseError } = await supabase
    .from('purchases')
    .update({
      status: 'completed',
      stripe_payment_intent_id: session.payment_intent
    })
    .eq('stripe_session_id', session.id);

  if (purchaseError) {
    logServerEvent(`Failed to complete purchase: ${purchaseError.message}`, 'ERROR');
    // Content is unlocked but purchase not marked complete
    // This is safer than the reverse
  }

  return Response.json({ received: true });
} catch (error) {
  logServerEvent(`Webhook processing error: ${error}`, 'ERROR');
  return Response.json({ error: 'Processing failed' }, { status: 500 });
}
```

**Why This Order**: Better to have unlocked content with incomplete purchase (user happy) than completed purchase with no unlock (user angry, refund request).

---

#### 2.4 Missing CORS and Rate Limiting

**Problem**: No mention of protecting API routes from abuse.

**Required for `/api/checkout`**:
```typescript
// middleware.ts or in route
import { ratelimit } from '@/lib/redis'; // Use Upstash or similar

export async function POST(request: Request) {
  // Rate limit by IP
  const ip = request.headers.get('x-forwarded-for') || 'unknown';
  const { success, limit, remaining } = await ratelimit.limit(ip);

  if (!success) {
    return Response.json(
      { error: 'Too many requests' },
      { status: 429, headers: { 'X-RateLimit-Remaining': remaining.toString() } }
    );
  }

  // Continue with checkout...
}
```

**Why**: Without rate limiting, attackers can:
- Spam checkout sessions
- Cost you money in Stripe API calls
- DDoS your payment flow

---

### 3. ERROR HANDLING - PRODUCTION WILL BREAK

#### 3.1 No Error Recovery in Checkout Flow

**Location**: `app/api/checkout/route.ts`

```typescript
// CURRENT PLAN - FAIL
const session = await stripe.checkout.sessions.create({
  // ... config
});

// What if Stripe is down? No try/catch.
await supabase.from('purchases').insert({
  // ... data
});
// What if this fails? User sees success, but no purchase record.
```

**Required**:
```typescript
export async function POST(request: Request): Promise<Response> {
  let body: CheckoutRequest;
  try {
    body = CheckoutRequestSchema.parse(await request.json());
  } catch (error) {
    return Response.json(
      { error: 'Invalid request data' },
      { status: 400 }
    );
  }

  const { productType, productId, email } = body;

  let session: Stripe.Checkout.Session;
  try {
    session = await stripe.checkout.sessions.create({
      mode: 'payment',
      payment_method_types: ['card'],
      customer_email: email,
      line_items: [{
        price: getPriceId(productType),
        quantity: 1
      }],
      success_url: `${process.env.NEXT_PUBLIC_URL}/dashboard?unlocked=true`,
      cancel_url: `${process.env.NEXT_PUBLIC_URL}/dashboard`,
      metadata: { productType, productId, email }
    });
  } catch (error) {
    logServerEvent(`Stripe session creation failed: ${error}`, 'ERROR');
    return Response.json(
      { error: 'Payment system unavailable' },
      { status: 503 }
    );
  }

  // Create pending purchase AFTER Stripe session succeeds
  const { error: dbError } = await supabase.from('purchases').insert({
    email,
    product_type: productType,
    product_id: productId,
    amount_cents: productType === 'full_report' ? 900 : 700,
    stripe_session_id: session.id,
    status: 'pending'
  });

  if (dbError) {
    logServerEvent(`Purchase record creation failed: ${dbError}`, 'ERROR');
    // Session created in Stripe but no DB record
    // Log this for manual reconciliation
    // Still return session to user (they can complete payment)
  }

  return Response.json({
    sessionId: session.id,
    url: session.url
  });
}
```

---

#### 3.2 Frontend Check-Unlock Has No Error State

**Location**: `components/Dashboard.tsx` (proposed changes)

```typescript
// CURRENT PLAN - FAIL
useEffect(() => {
  if (profile?.id && userEmail) {
    fetch(`/api/check-unlock?type=full_report&id=${profile.id}&email=${userEmail}`)
      .then(r => r.json())
      .then(data => setIsUnlocked(data.unlocked));
  }
}, [profile?.id, userEmail]);
// No error handling. If API is down, user assumes content is locked.
```

**Required**:
```typescript
const [isUnlocked, setIsUnlocked] = useState(false);
const [unlockCheckLoading, setUnlockCheckLoading] = useState(true);
const [unlockCheckError, setUnlockCheckError] = useState<string | null>(null);

useEffect(() => {
  if (!profile?.id || !userEmail) {
    setUnlockCheckLoading(false);
    return;
  }

  setUnlockCheckLoading(true);
  setUnlockCheckError(null);

  const checkUnlock = async () => {
    try {
      const response = await fetch(
        `/api/check-unlock?type=full_report&id=${encodeURIComponent(profile.id)}&email=${encodeURIComponent(userEmail)}`
      );

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data: CheckUnlockResponse = await response.json();
      setIsUnlocked(data.unlocked);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      setUnlockCheckError(message);
      logClientEvent(`Unlock check failed: ${message}`, 'ERROR');
      // Default to showing paywall if check fails (safe default)
      setIsUnlocked(false);
    } finally {
      setUnlockCheckLoading(false);
    }
  };

  checkUnlock();
}, [profile?.id, userEmail]);

// In render:
if (unlockCheckLoading) {
  return <div>Checking access...</div>;
}

if (unlockCheckError) {
  return <div>Unable to verify access. Please refresh or contact support.</div>;
}
```

---

### 4. CODE ORGANIZATION - MAINTAINABILITY NIGHTMARE

#### 4.1 No Service Layer Abstraction

**Problem**: Business logic scattered directly in API routes.

**Current Approach (BAD)**:
```
app/api/checkout/route.ts - 126 lines mixing Stripe, DB, validation
app/api/webhooks/stripe/route.ts - All webhook logic inline
```

**Required Structure**:
```
lib/
  billing/
    stripe.ts          - Stripe client + session creation
    purchases.ts       - Purchase DB operations
    unlocks.ts         - Unlock logic
    types.ts           - All billing types
    validation.ts      - Zod schemas

app/api/
  checkout/
    route.ts           - Thin route calling billing services
  webhooks/
    stripe/
      route.ts         - Thin webhook handler
```

**Example Service Layer**:
```typescript
// lib/billing/stripe.ts
import Stripe from 'stripe';
import { STRIPE_PRICE_IDS } from '@/config/stripe';
import type { ProductType } from './types';

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2023-10-16',
});

export async function createCheckoutSession(
  productType: ProductType,
  email: string,
  metadata: Record<string, string>
): Promise<Stripe.Checkout.Session> {
  return stripe.checkout.sessions.create({
    mode: 'payment',
    payment_method_types: ['card'],
    customer_email: email,
    line_items: [{
      price: STRIPE_PRICE_IDS[productType],
      quantity: 1
    }],
    success_url: `${process.env.NEXT_PUBLIC_URL}/dashboard?unlocked=true`,
    cancel_url: `${process.env.NEXT_PUBLIC_URL}/dashboard`,
    metadata
  });
}

// lib/billing/purchases.ts
import { createServiceClient } from '@/lib/supabase/service';
import type { Purchase, ProductType } from './types';

export async function createPendingPurchase(
  email: string,
  productType: ProductType,
  productId: string,
  stripeSessionId: string
): Promise<{ data: Purchase | null; error: Error | null }> {
  const supabase = createServiceClient();

  const { data, error } = await supabase
    .from('purchases')
    .insert({
      email,
      product_type: productType,
      product_id: productId,
      amount_cents: productType === 'full_report' ? 900 : 700,
      stripe_session_id: stripeSessionId,
      status: 'pending'
    })
    .select()
    .single();

  return {
    data,
    error: error ? new Error(error.message) : null
  };
}

// Now route is clean:
// app/api/checkout/route.ts
import { createCheckoutSession } from '@/lib/billing/stripe';
import { createPendingPurchase } from '@/lib/billing/purchases';
import { CheckoutRequestSchema } from '@/lib/billing/validation';

export async function POST(request: Request): Promise<Response> {
  const body = CheckoutRequestSchema.parse(await request.json());

  const session = await createCheckoutSession(
    body.productType,
    body.email,
    { productId: body.productId }
  );

  await createPendingPurchase(
    body.email,
    body.productType,
    body.productId,
    session.id
  );

  return Response.json({ sessionId: session.id, url: session.url });
}
```

**Why This Matters**:
- Testing: Can't test business logic without mocking entire Next.js request flow
- Reusability: Can't reuse checkout logic elsewhere
- Debugging: 126-line route files are hard to debug
- Maintenance: Changes to Stripe API require editing routes directly

---

#### 4.2 Premium Gate Component is Too Complex

**Problem**: `components/PremiumGate.tsx` in the plan is 367 lines doing EVERYTHING.

**Issues**:
1. Mixing data fetching, UI, and business logic
2. Teaser generation has complex logic inline
3. Checkout handling embedded in component
4. No separation of concerns

**Required Refactoring**:
```
components/
  billing/
    PremiumGate.tsx           - Main gate component (UI only)
    TeaserCard.tsx            - Individual teaser display
    CheckoutButton.tsx        - Checkout button with loading state
    PriceDisplay.tsx          - Price + trust signals

hooks/
  usePremiumUnlock.ts         - Unlock check + checkout logic

lib/
  billing/
    teasers.ts                - Teaser generation logic
```

**Example Hook Extraction**:
```typescript
// hooks/usePremiumUnlock.ts
export function usePremiumUnlock(
  profileId: string | undefined,
  email: string | undefined,
  contentType: 'full_report' | 'comparison'
) {
  const [isUnlocked, setIsUnlocked] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const checkUnlock = useCallback(async () => {
    if (!profileId || !email) return;

    setIsLoading(true);
    try {
      const response = await fetch(
        `/api/check-unlock?type=${contentType}&id=${profileId}&email=${email}`
      );
      const data = await response.json();
      setIsUnlocked(data.unlocked);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Unknown error'));
    } finally {
      setIsLoading(false);
    }
  }, [profileId, email, contentType]);

  useEffect(() => {
    checkUnlock();
  }, [checkUnlock]);

  const initiateCheckout = useCallback(async () => {
    // Checkout logic here
  }, [profileId, email, contentType]);

  return {
    isUnlocked,
    isLoading,
    error,
    initiateCheckout,
    recheckUnlock: checkUnlock
  };
}

// Now component is simple:
export function PremiumGate({ profile }: { profile: IndividualProfile }) {
  const { isUnlocked, isLoading, initiateCheckout } = usePremiumUnlock(
    profile.id,
    profile.email,
    'full_report'
  );

  if (isLoading) return <LoadingState />;
  if (isUnlocked) return null;

  return (
    <div className="premium-gate">
      <TeaserList profile={profile} />
      <PriceDisplay price={9} />
      <CheckoutButton onClick={initiateCheckout} />
    </div>
  );
}
```

---

### 5. MISSING CRITICAL FEATURES

#### 5.1 No Refund Handling

**Problem**: Plan mentions "100% refund guarantee" but zero implementation.

**What Happens When User Requests Refund**:
1. You process refund in Stripe Dashboard
2. Stripe sends `charge.refunded` webhook
3. Current plan has NO HANDLER for this
4. User keeps access to unlocked content forever

**Required**:
```typescript
// app/api/webhooks/stripe/route.ts
if (event.type === 'charge.refunded') {
  const charge = event.data.object as Stripe.Charge;
  const paymentIntentId = charge.payment_intent as string;

  // Mark purchase as refunded
  await supabase
    .from('purchases')
    .update({ status: 'refunded' })
    .eq('stripe_payment_intent_id', paymentIntentId);

  // Remove unlock
  await supabase
    .from('unlocked_content')
    .delete()
    .eq('purchase_id', purchaseId); // Need to track purchase_id in unlocked_content

  logServerEvent(`Refund processed: ${paymentIntentId}`);
}
```

**Also Need**:
- UI to show "Access Revoked - Refund Processed"
- Grace period (24 hours?) before actually removing access
- Email notification about refund

---

#### 5.2 No Analytics/Metrics Tracking

**Problem**: Plan says "Metrics to Track" but provides zero implementation.

**Required Events to Track**:
```typescript
// lib/analytics.ts
export async function trackBillingEvent(
  event: 'gate_viewed' | 'checkout_clicked' | 'checkout_completed' | 'checkout_failed',
  metadata: {
    productType: ProductType;
    productId: string;
    email: string;
    amount?: number;
    error?: string;
  }
) {
  // Log to your analytics platform
  await fetch('/api/analytics/track', {
    method: 'POST',
    body: JSON.stringify({ event, metadata, timestamp: new Date().toISOString() })
  });

  // Also log to Supabase for internal queries
  const supabase = createServiceClient();
  await supabase.from('billing_events').insert({
    event_type: event,
    product_type: metadata.productType,
    product_id: metadata.productId,
    email: metadata.email,
    metadata: metadata,
    created_at: new Date().toISOString()
  });
}

// Use in components:
<PremiumGate
  onView={() => trackBillingEvent('gate_viewed', { ... })}
  onCheckoutClick={() => trackBillingEvent('checkout_clicked', { ... })}
/>
```

**Why Critical**: Without tracking, you have ZERO visibility into:
- Conversion funnel drop-off points
- Which features drive purchases
- A/B test results
- Revenue attribution

---

#### 5.3 No Idempotency for Webhook Processing

**Problem**: Stripe sends webhooks multiple times (network issues, retries).

**What Happens Now**:
1. Webhook arrives, creates unlock, marks purchase complete
2. Webhook arrives again (retry), tries to create unlock again
3. Database constraint error OR duplicate unlock record

**Required**:
```typescript
// Track processed webhooks
CREATE TABLE webhook_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_event_id TEXT UNIQUE NOT NULL,
  event_type TEXT NOT NULL,
  processed_at TIMESTAMPTZ DEFAULT NOW(),
  processing_status TEXT DEFAULT 'success'
);

// In webhook handler:
export async function POST(request: Request): Promise<Response> {
  const event = stripe.webhooks.constructEvent(body, sig, secret);

  // Check if already processed
  const { data: existing } = await supabase
    .from('webhook_events')
    .select('id')
    .eq('stripe_event_id', event.id)
    .single();

  if (existing) {
    logServerEvent(`Webhook ${event.id} already processed, skipping`);
    return Response.json({ received: true, duplicate: true });
  }

  // Mark as processing
  await supabase.from('webhook_events').insert({
    stripe_event_id: event.id,
    event_type: event.type,
    processing_status: 'processing'
  });

  try {
    // Process the event...

    // Mark as success
    await supabase
      .from('webhook_events')
      .update({ processing_status: 'success' })
      .eq('stripe_event_id', event.id);

    return Response.json({ received: true });
  } catch (error) {
    // Mark as failed
    await supabase
      .from('webhook_events')
      .update({ processing_status: 'failed' })
      .eq('stripe_event_id', event.id);

    throw error;
  }
}
```

---

### 6. AI PROMPT MODIFICATION - DANGEROUS APPROACH

#### 6.1 Split Marker is Fragile

**Location**: Plan line 225

```typescript
const [freePart, premiumPart] = useMemo(() => {
  if (!aiResponse) return ['', ''];
  const parts = aiResponse.split('<!-- PREMIUM_SPLIT -->');
  return [parts[0] || '', parts[1] || ''];
}, [aiResponse]);
```

**Problems**:
1. What if AI doesn't include the marker?
2. What if AI includes it twice?
3. What if AI includes it in a code block?
4. What if marker appears in user content?

**Better Approach**:
```typescript
// Don't rely on AI to insert markers correctly
// Instead, structure the prompt to return JSON:

const systemPrompt = `
Return your analysis as JSON with two sections:

{
  "free_content": "markdown for free tier",
  "premium_content": "markdown for premium tier"
}
`;

// Then in frontend:
const [freePart, premiumPart] = useMemo(() => {
  if (!aiResponse) return ['', ''];

  try {
    const parsed = JSON.parse(aiResponse);
    return [parsed.free_content || '', parsed.premium_content || ''];
  } catch (error) {
    // Fallback to split if AI doesn't follow instructions
    const parts = aiResponse.split('<!-- PREMIUM_SPLIT -->');
    return [parts[0] || '', parts[1] || ''];
  }
}, [aiResponse]);
```

**Why**: AI models are non-deterministic. Relying on exact string matching for critical business logic is asking for bugs.

---

#### 6.2 No Handling for Existing Cached Analyses

**Problem**: You have cached analyses in DB (from `/api/analyze` code). These don't have the split.

**What Happens**:
1. User generated report 1 week ago (no split marker)
2. You ship premium feature
3. User loads report from cache
4. `split('<!-- PREMIUM_SPLIT -->')` returns `[fullReport, '']`
5. Premium part is empty, gate doesn't work

**Required**:
```typescript
// Migration to add premium flag to cached analyses
ALTER TABLE analysis_cache ADD COLUMN has_premium_split BOOLEAN DEFAULT false;

// When loading from cache:
const { data: cached } = await supabase
  .from('analysis_cache')
  .select('analysis_text, has_premium_split')
  .eq('profile_hash', cacheKey)
  .single();

if (cached && !cached.has_premium_split) {
  // Re-generate with new prompt OR
  // Apply heuristic split (risky)
  logServerEvent(`Cache hit but no premium split, regenerating`);
  // ... regenerate logic
}
```

---

### 7. TESTING STRATEGY - COMPLETELY MISSING

**Problem**: Plan has "Testing Checklist" but zero actual test code.

**Required Test Coverage**:

```typescript
// __tests__/api/checkout.test.ts
describe('/api/checkout', () => {
  it('should create checkout session with valid data', async () => {
    const response = await POST(
      new Request('http://localhost/api/checkout', {
        method: 'POST',
        body: JSON.stringify({
          productType: 'full_report',
          productId: 'test-profile-id',
          email: 'test@example.com'
        })
      })
    );

    expect(response.status).toBe(200);
    const data = await response.json();
    expect(data).toHaveProperty('sessionId');
    expect(data).toHaveProperty('url');
  });

  it('should reject invalid product type', async () => {
    const response = await POST(
      new Request('http://localhost/api/checkout', {
        method: 'POST',
        body: JSON.stringify({
          productType: 'hacker_access',
          productId: 'test',
          email: 'test@example.com'
        })
      })
    );

    expect(response.status).toBe(400);
  });

  it('should handle Stripe API failure gracefully', async () => {
    // Mock Stripe to fail
    jest.spyOn(stripe.checkout.sessions, 'create')
      .mockRejectedValueOnce(new Error('Stripe down'));

    const response = await POST(validRequest);
    expect(response.status).toBe(503);
  });
});

// __tests__/api/webhooks/stripe.test.ts
describe('Stripe Webhooks', () => {
  it('should process checkout.session.completed', async () => {
    const event = createMockStripeEvent('checkout.session.completed', {
      metadata: {
        productType: 'full_report',
        productId: 'test-id',
        email: 'test@example.com'
      }
    });

    const response = await POST(createWebhookRequest(event));
    expect(response.status).toBe(200);

    // Verify unlock was created
    const unlock = await supabase
      .from('unlocked_content')
      .select('*')
      .eq('email', 'test@example.com')
      .single();

    expect(unlock.data).toBeDefined();
  });

  it('should handle duplicate webhook delivery', async () => {
    const event = createMockStripeEvent('checkout.session.completed', {
      id: 'evt_duplicate_test'
    });

    // Process once
    await POST(createWebhookRequest(event));

    // Process again (duplicate)
    const response = await POST(createWebhookRequest(event));
    expect(response.status).toBe(200);

    // Verify only one unlock exists
    const unlocks = await supabase
      .from('unlocked_content')
      .select('*')
      .eq('email', 'test@example.com');

    expect(unlocks.data).toHaveLength(1);
  });
});

// __tests__/components/PremiumGate.test.tsx
describe('PremiumGate', () => {
  it('should show gate when content is locked', () => {
    const { getByText } = render(
      <PremiumGate profile={mockProfile} />
    );

    expect(getByText(/Unlock Your Full Report/i)).toBeInTheDocument();
  });

  it('should track gate view event', () => {
    render(<PremiumGate profile={mockProfile} />);

    expect(trackBillingEvent).toHaveBeenCalledWith(
      'gate_viewed',
      expect.objectContaining({
        productType: 'full_report'
      })
    );
  });

  it('should initiate checkout on button click', async () => {
    const { getByRole } = render(<PremiumGate profile={mockProfile} />);

    const button = getByRole('button', { name: /Unlock/i });
    fireEvent.click(button);

    await waitFor(() => {
      expect(window.location.href).toContain('stripe.com/checkout');
    });
  });
});
```

**Why This is Blocking**:
- Payment bugs cost real money
- Webhook failures = angry customers
- Can't refactor without tests
- Can't deploy with confidence

---

## MODERATE ISSUES - FIX BEFORE PRODUCTION

### 8. Performance Concerns

#### 8.1 N+1 Query in Unlock Check

**Location**: Frontend calling `/api/check-unlock` for every profile view

**Problem**:
- User with 5 profiles = 5 API calls on dashboard load
- Each call hits database separately
- Slow page load, poor UX

**Better Approach**:
```typescript
// Instead of individual checks, batch them:
// GET /api/check-unlocks?ids=profile1,profile2,profile3&email=user@example.com

export async function GET(request: Request): Promise<Response> {
  const { searchParams } = new URL(request.url);
  const idsParam = searchParams.get('ids');
  const email = searchParams.get('email');

  if (!idsParam || !email) {
    return Response.json({ error: 'Missing parameters' }, { status: 400 });
  }

  const ids = idsParam.split(',');

  const { data } = await supabase
    .from('unlocked_content')
    .select('content_id')
    .eq('email', email)
    .eq('content_type', 'full_report')
    .in('content_id', ids);

  const unlockedIds = new Set(data?.map(d => d.content_id) || []);
  const result = ids.map(id => ({ id, unlocked: unlockedIds.has(id) }));

  return Response.json({ unlocks: result });
}
```

---

#### 8.2 Missing Database Indexes

**Location**: Migration SQL

**Problem**: Queries will be slow without proper indexes.

**Required Additions**:
```sql
-- Already in plan:
CREATE INDEX idx_purchases_user ON purchases(user_id);
CREATE INDEX idx_purchases_email ON purchases(email);

-- MISSING (add these):
CREATE INDEX idx_unlocked_content_lookup ON unlocked_content(email, content_type, content_id);
CREATE INDEX idx_purchases_stripe_session ON purchases(stripe_session_id);
CREATE INDEX idx_purchases_status ON purchases(status) WHERE status = 'pending';

-- For webhook idempotency:
CREATE INDEX idx_webhook_events_stripe_id ON webhook_events(stripe_event_id);
```

---

### 9. UX Issues

#### 9.1 No Loading State During Checkout

**Problem**: User clicks "Unlock" → nothing happens for 1-2 seconds → Stripe page opens

**Better UX**:
```typescript
function CheckoutButton({ onClick }: { onClick: () => Promise<void> }) {
  const [isLoading, setIsLoading] = useState(false);

  const handleClick = async () => {
    setIsLoading(true);
    try {
      await onClick();
    } catch (error) {
      // Show error toast
      toast.error('Checkout failed. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <button
      onClick={handleClick}
      disabled={isLoading}
      className="checkout-button"
    >
      {isLoading ? (
        <>
          <Loader2 className="animate-spin" />
          Opening checkout...
        </>
      ) : (
        'Unlock Your Full Report'
      )}
    </button>
  );
}
```

---

#### 9.2 No Confirmation After Payment

**Problem**: User returns from Stripe → URL has `?unlocked=true` → nothing happens

**Better Flow**:
```typescript
// app/dashboard/page.tsx
export default function DashboardPage() {
  const searchParams = useSearchParams();
  const [showSuccessModal, setShowSuccessModal] = useState(false);

  useEffect(() => {
    if (searchParams.get('unlocked') === 'true') {
      setShowSuccessModal(true);
      // Remove query param to prevent showing again on refresh
      window.history.replaceState({}, '', '/dashboard');
    }
  }, [searchParams]);

  return (
    <>
      {showSuccessModal && (
        <SuccessModal
          title="Content Unlocked!"
          message="Your full report is now available. Scroll down to read your deep insights."
          onClose={() => setShowSuccessModal(false)}
        />
      )}
      {/* Rest of dashboard */}
    </>
  );
}
```

---

## MINOR ISSUES - POLISH BEFORE LAUNCH

### 10. Environment Variables Missing Validation

**Required**:
```typescript
// lib/env.ts
import { z } from 'zod';

const envSchema = z.object({
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
  STRIPE_WEBHOOK_SECRET: z.string().startsWith('whsec_'),
  NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: z.string().startsWith('pk_'),
  STRIPE_PRICE_ID_FULL_REPORT: z.string().startsWith('price_'),
  STRIPE_PRICE_ID_COMPARISON: z.string().startsWith('price_'),
});

export const env = envSchema.parse(process.env);
```

---

### 11. Teaser Personalization Functions Don't Exist

**Location**: Plan references `generatePersonalizedTeasers()` but never implements it.

**Required**:
```typescript
// lib/billing/teasers.ts
import { IndividualProfile } from '@/types';

export function generatePersonalizedTeasers(profile: IndividualProfile) {
  const { assessments, name } = profile;

  const attachment = assessments.ecr_s?.attachmentStyleLabel || 'Secure';
  const topTrait = getHighestBigFiveTrait(assessments.ipip_50);

  return [
    {
      icon: 'ghost',
      title: 'Your Shadow Self',
      preview: `Based on your ${topTrait} nature and ${attachment} attachment, your primary blind spot involves`
    },
    // ... rest of teasers
  ];
}

function getHighestBigFiveTrait(ipip50: any): string {
  const traits = {
    neuroticism: ipip50.domainScores.neuroticism.percentileEstimate,
    extraversion: ipip50.domainScores.extraversion.percentileEstimate,
    openness: ipip50.domainScores.openness.percentileEstimate,
    agreeableness: ipip50.domainScores.agreeableness.percentileEstimate,
    conscientiousness: ipip50.domainScores.conscientiousness.percentileEstimate,
  };

  return Object.entries(traits)
    .sort((a, b) => b[1] - a[1])[0][0];
}
```

---

## SUMMARY: READINESS ASSESSMENT

### BLOCKING (Must Fix Before Any Code)
1. Add complete TypeScript types for ALL API routes
2. Fix email-based security vulnerability in RLS policies
3. Add proper error handling to ALL async operations
4. Implement webhook signature verification + error handling
5. Fix race condition in webhook processing
6. Create service layer abstraction

### CRITICAL (Must Fix Before Production)
1. Implement refund handling
2. Add webhook idempotency
3. Add analytics tracking
4. Write comprehensive tests
5. Add rate limiting
6. Fix AI response parsing fragility

### IMPORTANT (Fix Before Launch)
1. Add database indexes
2. Batch unlock checks
3. Add loading states
4. Add success confirmations
5. Validate environment variables

### NICE TO HAVE (Polish)
1. Implement teaser generation functions
2. Better error messages
3. Email notifications

---

## RECOMMENDATIONS

### DO NOT PROCEED until:
1. Every API route has Zod schemas
2. Security review of RLS policies complete
3. Service layer extraction complete
4. Test coverage > 80% for payment flow

### TIMELINE IMPACT:
Original plan: 8 hours
Revised with fixes: 20-25 hours

The plan is architecturally sound but **execution quality is dangerously low**. This reads like a rough draft, not production-ready code.

**Grade: D+ (Needs Major Revision)**
- Concept: B
- Type Safety: F
- Security: D
- Error Handling: F
- Code Organization: C-
- Testing: F

Would not approve this for implementation without significant rewrites.
