# Deep Personality Monetization - Simplified Plan

**Pricing:** $9 full report (one-time), $7 comparison (one-time)

---

## Phase 1: Database (ONE Table)

**File:** `supabase/migrations/006_billing.sql`

```sql
CREATE TABLE purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  content_type TEXT NOT NULL,  -- 'full_report' | 'comparison'
  content_id TEXT NOT NULL,    -- profile_id or sorted "idA_idB"
  amount_cents INTEGER NOT NULL,
  stripe_payment_intent_id TEXT UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(email, content_type, content_id)
);

CREATE INDEX idx_purchases_lookup
ON purchases(email, content_type, content_id)
WHERE stripe_payment_intent_id IS NOT NULL;

ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;

-- Simple: only service role can write (webhook), users can read own
CREATE POLICY "Users view own purchases" ON purchases
  FOR SELECT USING (true);  -- Public read, filter in app
```

**Why simplified:**
- No `unlocked_content` table (derive from purchases)
- No `user_id` (email is identifier)
- No `status` field (has payment_intent_id = paid)
- No `stripe_session_id` (only need payment_intent)

---

## Phase 2: Stripe Setup

### 2.1 Environment Variables
**File:** `.env.local` (add)
```
STRIPE_SECRET_KEY=sk_live_51NXCZpKIPzic4nTX...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_51NXCZpKIPzic4nTX...
STRIPE_WEBHOOK_SECRET=whsec_...  # After webhook setup
```

### 2.2 Install
```bash
npm install stripe @stripe/stripe-js zod
```

### 2.3 Stripe Dashboard
Create two products:
- "Full Personality Report" — $9.00 (get price_id)
- "Compatibility Analysis" — $7.00 (get price_id)

---

## Phase 3: API Routes (TWO Routes Only)

### 3.1 Checkout Session
**File:** `app/api/checkout/route.ts`

```typescript
import Stripe from 'stripe';
import { z } from 'zod';
import { NextResponse } from 'next/server';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2024-12-18.acacia'
});

const CheckoutSchema = z.object({
  productType: z.enum(['full_report', 'comparison']),
  productId: z.string().min(1),
  email: z.string().email()
});

const PRICES = {
  full_report: process.env.STRIPE_PRICE_FULL_REPORT!,
  comparison: process.env.STRIPE_PRICE_COMPARISON!
} as const;

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { productType, productId, email } = CheckoutSchema.parse(body);

    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      payment_method_types: ['card', 'link'],
      customer_email: email,
      line_items: [{ price: PRICES[productType], quantity: 1 }],
      success_url: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard?unlocked=true&session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard`,
      metadata: { productType, productId, email }
    });

    return NextResponse.json({ url: session.url });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: 'Invalid request' }, { status: 400 });
    }
    console.error('Checkout error:', error);
    return NextResponse.json({ error: 'Checkout failed' }, { status: 500 });
  }
}
```

**Key points:**
- Zod validation
- Error handling with try/catch
- No pending purchase record (webhook-only)

### 3.2 Stripe Webhook (Idempotent)
**File:** `app/api/webhooks/stripe/route.ts`

```typescript
import Stripe from 'stripe';
import { createServiceClient } from '@/lib/supabase/service';
import { NextResponse } from 'next/server';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export async function POST(request: Request) {
  const body = await request.text();
  const sig = request.headers.get('stripe-signature');

  if (!sig) {
    return NextResponse.json({ error: 'No signature' }, { status: 400 });
  }

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(
      body, sig, process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch (err) {
    console.error('Webhook signature failed:', err);
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session;
    const { productType, productId, email } = session.metadata!;
    const paymentIntentId = session.payment_intent as string;

    const supabase = createServiceClient();

    // Upsert for idempotency (webhook may fire multiple times)
    const { error } = await supabase.from('purchases').upsert({
      email,
      content_type: productType,
      content_id: productId,
      amount_cents: session.amount_total!,
      stripe_payment_intent_id: paymentIntentId
    }, {
      onConflict: 'stripe_payment_intent_id'
    });

    if (error) {
      console.error('Purchase insert failed:', error);
      return NextResponse.json({ error: 'DB error' }, { status: 500 });
    }
  }

  return NextResponse.json({ received: true });
}

export const config = {
  api: { bodyParser: false }
};
```

**Key points:**
- Signature verification with error handling
- Upsert for idempotency (handles duplicate webhooks)
- Uses service client to bypass RLS

---

## Phase 4: Secure Content - No Leaking Premium

**Critical:** Users must NOT be able to access premium content without paying.

### 4.1 API-Level Gating
**File:** `app/api/analyze/route.ts`

The AI generates the FULL report but we only return Part 1 to unpaid users:

```typescript
// After generating full analysis, split before returning
const marker = '<!-- PREMIUM_SPLIT -->';
const [freePart, premiumPart] = fullAnalysis.split(marker);

// Check if user has paid
const { data: purchase } = await supabase
  .from('purchases')
  .select('id')
  .eq('email', email)
  .eq('content_type', 'full_report')
  .eq('content_id', profileId)
  .not('stripe_payment_intent_id', 'is', null)
  .single();

// Only return premium if paid
const responseText = purchase
  ? fullAnalysis
  : freePart + '\n\n<!-- PREMIUM_SPLIT -->\n\n[PREMIUM_LOCKED]';
```

### 4.2 Database Storage
When saving `ai_analysis` to the profiles table:
- **Always store the FULL analysis** (for when they pay later)
- **Always serve gated version** based on purchase status

### 4.3 Download Protection
**File:** `components/Dashboard.tsx`

The JSON download button must exclude premium content for unpaid users:

```typescript
// In download handler
const downloadData = {
  ...profile,
  ai_analysis: isUnlocked ? aiResponse : freePart
};
```

### 4.4 Share Link Protection
Shared profiles should also respect the paywall - premium sections only visible if the SHARER has paid.

---

## Phase 5: AI Prompt Split

**File:** `app/api/analyze/route.ts`

Add to the system prompt:

```typescript
const PREMIUM_SPLIT_INSTRUCTION = `

IMPORTANT: Structure your response in TWO PARTS separated by exactly this marker on its own line:

<!-- PREMIUM_SPLIT -->

PART 1 (before marker) - FREE CONTENT:
- The Real You (Core Personality)
- Your Emotional World
- What Drives You
- Your Superpowers
- Growth Opportunities

End Part 1 with: "---\\n**That's your core personality profile.** [1-sentence summary of who they are.]\\n---"

PART 2 (after marker) - PREMIUM CONTENT:
- 🔮 Your Deeper Patterns (shadow self, blind spots, core wound)
- Your Ideal Life (job, partner, friends, environment)
- ⚠️ Inversions: What to Avoid
- 💬 The Uncomfortable Truth
- 🔮 Specific Predictions
- ❓ The Question Your Life Is Answering
`;
```

---

## Phase 5: PremiumGate Component

**File:** `components/PremiumGate.tsx`

```tsx
'use client';

import { useState } from 'react';
import { Sparkles, Lock, Shield, Ghost, Heart, Target, TrendingUp } from 'lucide-react';

// Static teasers - simple and effective
const TEASERS = [
  {
    icon: Ghost,
    title: "Your Shadow Self",
    preview: "The parts of your personality you don't see—but others do"
  },
  {
    icon: Heart,
    title: "Relationship Triggers",
    preview: "The specific patterns that may be sabotaging your connections"
  },
  {
    icon: Target,
    title: "Your Ideal Partner",
    preview: "The personality type most likely to complement yours"
  },
  {
    icon: TrendingUp,
    title: "Growth Roadmap",
    preview: "Specific steps to develop your potential"
  }
];

interface PremiumGateProps {
  email: string;
  contentType: 'full_report' | 'comparison';
  contentId: string;
  onUnlock?: () => void;
}

export function PremiumGate({ email, contentType, contentId, onUnlock }: PremiumGateProps) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const price = contentType === 'full_report' ? 9 : 7;

  async function handleCheckout() {
    setLoading(true);
    setError(null);

    try {
      const res = await fetch('/api/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          productType: contentType,
          productId: contentId,
          email
        })
      });

      const data = await res.json();

      if (!res.ok) throw new Error(data.error || 'Checkout failed');
      if (data.url) window.location.href = data.url;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong');
      setLoading(false);
    }
  }

  return (
    <div className="my-12 relative">
      {/* Fade from content above */}
      <div className="absolute -top-16 left-0 right-0 h-16 bg-gradient-to-t from-white to-transparent dark:from-slate-800" />

      <div className="bg-gradient-to-br from-slate-50 to-blue-50 dark:from-slate-800 dark:to-slate-700 rounded-2xl p-8 border border-slate-200 dark:border-slate-600 shadow-lg">

        {/* Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center gap-2 bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200 px-4 py-1.5 rounded-full text-sm font-medium mb-4">
            <Sparkles className="w-4 h-4" />
            Part 2: Deep Insights
          </div>
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">
            Ready to see what's beneath the surface?
          </h2>
          <p className="text-slate-600 dark:text-slate-300">
            Your shadow self, blind spots, and the patterns holding you back.
          </p>
        </div>

        {/* Teasers */}
        <div className="grid gap-3 mb-8">
          {TEASERS.map((teaser, i) => (
            <div key={i} className="bg-white dark:bg-slate-700 rounded-xl p-4 border border-slate-200 dark:border-slate-600">
              <div className="flex items-center gap-4">
                <div className="p-2 bg-purple-100 dark:bg-purple-900 rounded-lg shrink-0">
                  <teaser.icon className="w-5 h-5 text-purple-600 dark:text-purple-300" />
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-slate-900 dark:text-white">{teaser.title}</h3>
                  <p className="text-slate-600 dark:text-slate-300 text-sm truncate">
                    {teaser.preview}...
                  </p>
                </div>
                <Lock className="w-5 h-5 text-slate-400 shrink-0" />
              </div>
            </div>
          ))}
        </div>

        {/* CTA */}
        <div className="text-center">
          <div className="mb-4">
            <span className="text-4xl font-bold text-slate-900 dark:text-white">${price}</span>
            <span className="text-slate-500 dark:text-slate-400 ml-2">one-time</span>
          </div>

          {error && (
            <p className="text-red-600 text-sm mb-4">{error}</p>
          )}

          <button
            onClick={handleCheckout}
            disabled={loading}
            className="w-full sm:w-auto px-8 py-4 bg-gradient-to-r from-blue-600 to-purple-600
                       text-white font-semibold rounded-xl shadow-lg
                       hover:shadow-xl hover:-translate-y-0.5
                       disabled:opacity-50 disabled:cursor-not-allowed
                       transition-all"
          >
            {loading ? 'Opening checkout...' : 'Unlock Your Full Report'}
          </button>

          <div className="mt-4 flex items-center justify-center gap-2 text-sm text-slate-500 dark:text-slate-400">
            <Shield className="w-4 h-4" />
            <span>100% money-back guarantee</span>
          </div>
        </div>
      </div>
    </div>
  );
}
```

**Key points:**
- Static teasers (no personalization complexity)
- Error handling with user feedback
- Loading states
- Dark mode support
- One component for both report types

---

## Phase 6: Dashboard Integration

**File:** `components/Dashboard.tsx`

Add imports and state:
```typescript
import { PremiumGate } from './PremiumGate';

// In component, after aiResponse state:
const [isUnlocked, setIsUnlocked] = useState(false);
```

Add unlock check on mount:
```typescript
// Check if unlocked (runs once on load)
useEffect(() => {
  async function checkUnlock() {
    if (!profile?.id || !userEmail) return;

    const { data } = await supabase
      .from('purchases')
      .select('id')
      .eq('email', userEmail)
      .eq('content_type', 'full_report')
      .eq('content_id', profile.id)
      .not('stripe_payment_intent_id', 'is', null)
      .single();

    setIsUnlocked(!!data);
  }
  checkUnlock();
}, [profile?.id, userEmail]);

// Also check URL param for immediate unlock after payment
useEffect(() => {
  const params = new URLSearchParams(window.location.search);
  if (params.get('unlocked') === 'true') {
    setIsUnlocked(true);
    // Clean URL
    window.history.replaceState({}, '', '/dashboard');
  }
}, []);
```

Modify AI response rendering:
```typescript
// Split content at marker
const [freePart, premiumPart] = useMemo(() => {
  if (!aiResponse) return ['', ''];
  const marker = '<!-- PREMIUM_SPLIT -->';
  const idx = aiResponse.indexOf(marker);
  if (idx === -1) return [aiResponse, '']; // No marker = show all
  return [aiResponse.slice(0, idx), aiResponse.slice(idx + marker.length)];
}, [aiResponse]);

// In render:
{aiResponse && (
  <div className="prose-report">
    <ReactMarkdown remarkPlugins={[remarkGfm]} components={MarkdownComponents}>
      {freePart}
    </ReactMarkdown>

    {premiumPart && (
      isUnlocked ? (
        <ReactMarkdown remarkPlugins={[remarkGfm]} components={MarkdownComponents}>
          {premiumPart}
        </ReactMarkdown>
      ) : (
        <PremiumGate
          email={userEmail}
          contentType="full_report"
          contentId={profile.id}
          onUnlock={() => setIsUnlocked(true)}
        />
      )
    )}
  </div>
)}
```

---

## Phase 7: Copy Updates (ONE Change)

**File:** `components/LandingHero.tsx`

Find the trust signals section (around line 370) and update:

**Current:**
```tsx
<span className="text-xs text-gray-500">No payment required</span>
```

**New:**
```tsx
<span className="text-xs text-gray-500">Free profile • Deep insights $9</span>
```

That's it. One line. Ship and iterate.

---

## Files Summary

| Action | File |
|--------|------|
| CREATE | `supabase/migrations/006_billing.sql` |
| CREATE | `app/api/checkout/route.ts` |
| CREATE | `app/api/webhooks/stripe/route.ts` |
| CREATE | `components/PremiumGate.tsx` |
| MODIFY | `app/api/analyze/route.ts` (add split instruction) |
| MODIFY | `components/Dashboard.tsx` (add gate logic) |
| MODIFY | `components/LandingHero.tsx` (one line copy change) |
| MODIFY | `.env.local` (add Stripe keys) |

---

## Implementation Order

1. **Env + Install** — Add Stripe keys, `npm install stripe @stripe/stripe-js zod`
2. **Database** — Run migration
3. **Stripe Dashboard** — Create products, get price IDs, add to env
4. **API Routes** — Checkout + Webhook
5. **AI Prompt** — Add split marker instruction
6. **PremiumGate** — Create component
7. **Dashboard** — Integrate gate
8. **Copy** — One line change
9. **Deploy** — Set up webhook URL in Stripe
10. **Test** — End-to-end payment flow

---

## Post-Launch Iteration

Only add these IF conversion is low:
- Personalized teasers (read from profile data)
- Price anchoring ("vs $150 therapy")
- Social proof counter
- Additional copy pre-framing

Ship simple. Measure. Iterate.
