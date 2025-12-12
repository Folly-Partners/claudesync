# Vercel Deployment Plan: Deep Personality App

## Overview

Migrate Deep Personality app to Vercel with Supabase authentication and secure credential management. Enable Google/Email authentication with guest mode for anonymous users who can download results without creating an account.

## Current State

- **File-based storage**: Profiles saved to `/profiles/*.json` (won't work on Vercel serverless)
- **No authentication**: Completely public, no user accounts
- **Exposed credentials**: `.env.local` contains live API keys (not committed, but needs rotation)
- **File-based logging**: `services/logger.ts` writes to disk (incompatible with Vercel)
- **Dark Triad marked "admin only"**: Need to make visible to all users

## User Requirements

1. **Authentication**: Google OAuth, Email/Password, OR Guest mode (download results)
2. **Storage**: Supabase PostgreSQL for authenticated users
3. **Guest Mode**: Allow assessment without account, download results file
4. **Dark Triad**: Remove "admin only" label, show to all users
5. **Email**: Nice to have (keep for admin notifications)
6. **Budget**: ~$5-20/month (Supabase free tier + low Anthropic usage)
7. **Public Access**: Open to anyone on the internet

## Implementation Phases

### Phase 1: Security & Credential Rotation (DAY 1 - 1 hour)

**Priority**: CRITICAL - Do before any deployment

#### 1.1 Rotate API Keys

**Anthropic API Key**:
1. Go to https://console.anthropic.com/settings/keys
2. Create new key: "Deep-Personality-Production-2024"
3. Copy immediately (only shown once)
4. Revoke old key: `sk-ant-api03-y8GPpXr...`

**Gmail Credentials**:
1. Go to https://myaccount.google.com/apppasswords
2. Revoke old "Deep Personality" password
3. Generate new with same name
4. Copy 16-character password

**Generate API Secret**:
```bash
openssl rand -base64 32
```

#### 1.2 Create `.env.example`

Create file for documentation (commit this):
```bash
# Deep Personality - Environment Variables
# Copy to .env.local and fill in your values

# Required: Anthropic API
ANTHROPIC_API_KEY=sk-ant-api03-your-key-here

# Required: Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-key

# Optional: Gmail notifications
GMAIL_USER=your-email@gmail.com
GMAIL_APP_PASSWORD=your-app-password

# Optional: API protection (leave empty for dev)
API_SECRET_KEY=
```

#### 1.3 Update `.gitignore`

Verify these lines exist (they should):
```
.env
.env.local
.env*.local
```

**Files to modify**:
- `.env.example` (CREATE NEW)
- `.gitignore` (verify)

---

### Phase 2: Supabase Setup (DAY 1 - 2 hours)

#### 2.1 Create Supabase Project

1. Go to https://supabase.com
2. Create new project
3. Choose region (US East recommended)
4. Set database password (save securely)
5. Wait for provisioning (~2 minutes)

#### 2.2 Get Credentials

From Supabase Dashboard → Settings → API:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` (public, safe for client)
- `SUPABASE_SERVICE_ROLE_KEY` (secret, server-only)

#### 2.3 Create Database Schema

Execute in Supabase SQL Editor:

```sql
-- Profiles table
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Metadata
  name TEXT NOT NULL,
  email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Demographics
  age INTEGER,

  -- Assessment data (JSONB)
  assessments JSONB NOT NULL DEFAULT '{}',
  custom_responses JSONB DEFAULT '{}',
  dark_triad JSONB,
  ai_analysis TEXT,

  -- Anti-gaming
  restart_count INTEGER DEFAULT 0,
  response_timings JSONB,

  -- Constraints
  CONSTRAINT valid_age CHECK (age >= 13 AND age <= 120)
);

-- Indexes
CREATE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_profiles_created_at ON profiles(created_at DESC);

-- Auto-update timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
```

#### 2.4 Enable Row Level Security (RLS)

```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Users can view own profiles
CREATE POLICY "Users view own profiles"
  ON profiles FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert own profiles
CREATE POLICY "Users create own profiles"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Service role has full access
CREATE POLICY "Service role full access"
  ON profiles FOR ALL
  USING (auth.role() = 'service_role');
```

#### 2.5 Configure Auth Providers

In Supabase Dashboard → Authentication → Providers:

**Enable Email/Password**:
- Toggle on
- Optional: Disable email confirmations for MVP

**Enable Google OAuth**:
1. Go to Google Cloud Console
2. Create OAuth 2.0 credentials
3. Authorized redirect: `https://[project-ref].supabase.co/auth/v1/callback`
4. Copy Client ID and Secret to Supabase

**Files to modify**: None (Supabase UI configuration)

---

### Phase 3: Install Dependencies (DAY 1 - 15 min)

```bash
npm install @supabase/supabase-js @supabase/auth-helpers-nextjs
npm install zod  # Input validation
```

**Files to modify**:
- `package.json` (npm install does this)

---

### Phase 4: Supabase Client Setup (DAY 1 - 30 min)

#### 4.1 Create Client Utilities

**File**: `lib/supabase/client.ts` (CREATE NEW)
```typescript
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

**File**: `lib/supabase/server.ts` (CREATE NEW)
```typescript
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value
        },
        set(name: string, value: string, options) {
          try {
            cookieStore.set({ name, value, ...options })
          } catch {}
        },
        remove(name: string, options) {
          try {
            cookieStore.set({ name, value: '', ...options })
          } catch {}
        },
      },
    }
  )
}
```

**File**: `lib/supabase/service.ts` (CREATE NEW)
```typescript
import { createClient } from '@supabase/supabase-js'

// Service role for admin operations (Dark Triad, etc.)
export function createServiceClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    }
  )
}
```

**Files to create**:
- `lib/supabase/client.ts`
- `lib/supabase/server.ts`
- `lib/supabase/service.ts`

---

### Phase 5: Authentication UI (DAY 2 - 3 hours)

#### 5.1 Auth Modal Component

**File**: `components/AuthModal.tsx` (CREATE NEW)

Create modal with:
- Google OAuth button
- Email/Password form
- Mode switching (Sign In / Sign Up / Magic Link)
- Error handling
- Loading states

Key features:
```typescript
const handleGoogleSignIn = async () => {
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: { redirectTo: `${window.location.origin}/auth/callback` }
  })
}

const handleEmailSignUp = async () => {
  const { error } = await supabase.auth.signUp({
    email, password,
    options: { data: { name } }
  })
}
```

#### 5.2 Auth Callback Route

**File**: `app/auth/callback/route.ts` (CREATE NEW)

```typescript
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const requestUrl = new URL(request.url)
  const code = requestUrl.searchParams.get('code')

  if (code) {
    const supabase = await createClient()
    await supabase.auth.exchangeCodeForSession(code)
  }

  return NextResponse.redirect(new URL('/', requestUrl.origin))
}
```

**Files to create**:
- `components/AuthModal.tsx`
- `app/auth/callback/route.ts`

---

### Phase 6: Update Wizard Component (DAY 2 - 2 hours)

**File**: `components/Wizard.tsx` (MODIFY)

#### 6.1 Add Auth State

Add at top of component:
```typescript
import { createClient } from '@/lib/supabase/client'
import { AuthModal } from './AuthModal'

const [user, setUser] = useState<User | null>(null)
const [showAuthModal, setShowAuthModal] = useState(false)
const supabase = createClient()

useEffect(() => {
  supabase.auth.getSession().then(({ data: { session } }) => {
    setUser(session?.user ?? null)
  })

  const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
    setUser(session?.user ?? null)
  })

  return () => subscription.unsubscribe()
}, [])
```

#### 6.2 Add Auth Prompt After Completion

Modify ResultsStep (around line 473) to show auth choice before displaying results:

```typescript
if (currentStep.type === 'finish') {
  const profile = generateProfile(basicInfo, answers);

  if (!user) {
    return (
      <div className="space-y-6">
        <h3 className="text-2xl font-bold">Assessment Complete!</h3>
        <p>Create an account to save your results, or continue as guest to download only.</p>

        <div className="flex flex-col gap-4 max-w-sm mx-auto">
          <button
            onClick={() => setShowAuthModal(true)}
            className="bg-blue-600 text-white px-8 py-4 rounded-xl font-semibold"
          >
            Sign Up to Save Results
          </button>

          <button
            onClick={() => setGuestMode(true)}
            className="text-slate-600 hover:text-slate-900"
          >
            Continue as guest (download only)
          </button>
        </div>

        <AuthModal
          isOpen={showAuthModal}
          onClose={() => setShowAuthModal(false)}
          onSuccess={() => setShowAuthModal(false)}
        />
      </div>
    )
  }

  return <ResultsStep profile={profile} rawAnswers={answers} user={user} />
}
```

#### 6.3 Update API Call to Include User ID

In ResultsStep component (line 484-490), update fetch:
```typescript
const response = await fetch('/api/complete', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    profile,
    rawAnswers,
    userId: user?.id || null  // Add this
  })
});
```

**Files to modify**:
- `components/Wizard.tsx` (multiple sections)

---

### Phase 7: Update API Routes (DAY 2-3 - 3 hours)

#### 7.1 Modify `/api/complete/route.ts`

**Replace file save logic** (lines 348-360) with Supabase:

```typescript
import { createServiceClient } from '@/lib/supabase/service'

// Remove fs.writeFileSync code, replace with:
try {
  const supabase = createServiceClient()
  const userId = body.userId || null  // From request

  if (userId) {
    // Authenticated user - save to database
    const { data, error } = await supabase
      .from('profiles')
      .insert({
        user_id: userId,
        name: profile.name,
        email: profile.email || profile.demographics?.email,
        age: profile.demographics?.age,
        assessments: profile.assessments,
        custom_responses: profile.customQuestionResponses,
        dark_triad: darkTriad,
        ai_analysis: aiAnalysis,
        restart_count: profile._internal?.restartCount || 0,
        response_timings: profile._internal?.responseTimings
      })
      .select()
      .single()

    if (error) throw error
    logServerEvent(`💾 Profile saved to Supabase: ${data.id}`)
    profile.id = data.id
  } else {
    // Guest mode - no save, just process
    logServerEvent(`👤 Guest profile generated (not saved)`)
  }

} catch (saveError) {
  logServerEvent(`❌ Failed to save: ${saveError.message}`, 'ERROR')
}
```

**Add Dark Triad to response** (remove "admin only"):

```typescript
const cleanProfile = {
  ...profile,
  darkTriad: {
    machiavellianism: darkTriad.machiavellianism,
    narcissism: darkTriad.narcissism,
    psychopathy: darkTriad.psychopathy
  }
};
return NextResponse.json({ success: true, profile: cleanProfile });
```

#### 7.2 Update Logger (Remove File Writes)

**File**: `services/logger.ts` (MODIFY)

Replace entire file content:
```typescript
export type LogLevel = 'INFO' | 'WARN' | 'ERROR';

export function logServerEvent(message: string, level: LogLevel = 'INFO', errorDetails?: any) {
  const timestamp = new Date().toISOString();
  let logMessage = `[${timestamp}] [${level}] ${message}`;

  if (errorDetails) {
    if (errorDetails instanceof Error) {
      logMessage += `\n Stack: ${errorDetails.stack}`;
    } else {
      logMessage += `\n Details: ${JSON.stringify(errorDetails)}`;
    }
  }

  // Vercel automatically captures console logs
  if (level === 'ERROR') {
    console.error(logMessage);
  } else if (level === 'WARN') {
    console.warn(logMessage);
  } else {
    console.log(logMessage);
  }
}
```

**Files to modify**:
- `app/api/complete/route.ts` (major changes)
- `services/logger.ts` (complete rewrite)

---

### Phase 8: Guest Download Enhancement (DAY 3 - 2 hours)

#### 8.1 Add PDF Download Option

Install dependencies:
```bash
npm install jspdf html2canvas
```

#### 8.2 Create Report Template

**File**: `lib/reportTemplate.ts` (CREATE NEW)

```typescript
export function generateReportHTML(profile: IndividualProfile): string {
  return `
    <div class="report" style="font-family: sans-serif; max-width: 800px; margin: 0 auto;">
      <h1 style="color: #1e40af; border-bottom: 3px solid #3b82f6;">
        Personality Assessment Report
      </h1>
      <p><strong>Name:</strong> ${profile.name}</p>
      <p><strong>Date:</strong> ${new Date(profile.timestamp).toLocaleDateString()}</p>

      <h2>Big Five Personality</h2>
      ${renderBigFiveTable(profile.assessments.ipip_50)}

      <h2>Attachment Style</h2>
      <p><strong>${profile.assessments.ecr_s?.attachmentStyleLabel}</strong></p>

      <!-- Add all other sections -->
    </div>
  `;
}

function renderBigFiveTable(ipip: any) {
  return `
    <table style="width:100%; border-collapse: collapse;">
      <tr>
        <th style="border-bottom: 2px solid #e5e7eb; padding: 12px; text-align: left;">Trait</th>
        <th style="border-bottom: 2px solid #e5e7eb; padding: 12px; text-align: left;">Percentile</th>
      </tr>
      ${Object.entries(ipip.domainScores).map(([domain, data]: [string, any]) => `
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #e5e7eb;">${capitalize(domain)}</td>
          <td style="padding: 12px; border-bottom: 1px solid #e5e7eb;">${data.percentile}th</td>
        </tr>
      `).join('')}
    </table>
  `;
}
```

#### 8.3 Add Download Buttons to ResultsStep

In `components/Wizard.tsx` ResultsStep, add:

```typescript
import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';
import { generateReportHTML } from '@/lib/reportTemplate';

const downloadPDF = async () => {
  setGeneratingPDF(true);
  const reportDiv = document.createElement('div');
  reportDiv.innerHTML = generateReportHTML(cleanProfile || profile);
  reportDiv.style.cssText = 'position:absolute;left:-9999px;width:800px;';
  document.body.appendChild(reportDiv);

  const canvas = await html2canvas(reportDiv, { scale: 2 });
  const pdf = new jsPDF('portrait', 'mm', 'a4');
  const imgData = canvas.toDataURL('image/png');
  const pdfWidth = 210;
  const pdfHeight = (canvas.height * pdfWidth) / canvas.width;

  pdf.addImage(imgData, 'PNG', 0, 0, pdfWidth, pdfHeight);
  pdf.save(`personality-report-${profile.name}.pdf`);

  document.body.removeChild(reportDiv);
  setGeneratingPDF(false);
};
```

**Files to create/modify**:
- `lib/reportTemplate.ts` (CREATE)
- `components/Wizard.tsx` (add PDF download)

---

### Phase 9: Security Headers & Vercel Config (DAY 3 - 1 hour)

#### 9.1 Update `next.config.js`

```javascript
const nextConfig = {
  reactStrictMode: true,

  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'X-XSS-Protection', value: '1; mode=block' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
        ],
      },
      {
        source: '/api/:path*',
        headers: [
          { key: 'Access-Control-Allow-Origin', value: '*' },
          { key: 'Access-Control-Allow-Methods', value: 'POST, OPTIONS' },
          { key: 'Cache-Control', value: 'no-store' },
        ],
      },
    ];
  },
};

module.exports = nextConfig;
```

#### 9.2 Create `vercel.json`

```json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "functions": {
    "app/api/analyze/route.ts": {
      "maxDuration": 60,
      "memory": 1024
    },
    "app/api/complete/route.ts": {
      "maxDuration": 60,
      "memory": 1024
    }
  },
  "regions": ["iad1"]
}
```

**Note**: Free tier = 60s max, Pro tier = 180s. Start with 60s, reduce timeouts in code if needed.

**Files to create/modify**:
- `next.config.js` (modify)
- `vercel.json` (create)

---

### Phase 10: Deployment (DAY 4 - 1 hour)

#### 10.1 Set Environment Variables in Vercel

Go to Vercel Dashboard → Project → Settings → Environment Variables:

Set these for **Production, Preview, Development**:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `ANTHROPIC_API_KEY` (NEW rotated key)
- `GMAIL_USER`
- `GMAIL_APP_PASSWORD` (NEW rotated password)
- `API_SECRET_KEY` (optional, for Production only)

#### 10.2 Deploy to Vercel

```bash
npm install -g vercel
vercel login
vercel  # Preview deployment
# Test thoroughly
vercel --prod  # Production deployment
```

#### 10.3 Verify Deployment

- [ ] Visit homepage - loads correctly
- [ ] Complete quiz as guest - download works
- [ ] Sign up with Google - redirects correctly
- [ ] Complete quiz authenticated - saves to Supabase
- [ ] Check Vercel logs - no errors
- [ ] Verify Dark Triad visible in results

---

## Critical Files Summary

### Files to CREATE:
1. `.env.example` - Environment variable template
2. `lib/supabase/client.ts` - Browser Supabase client
3. `lib/supabase/server.ts` - Server Supabase client
4. `lib/supabase/service.ts` - Service role client
5. `components/AuthModal.tsx` - Authentication UI
6. `app/auth/callback/route.ts` - OAuth callback handler
7. `lib/reportTemplate.ts` - PDF report generator
8. `vercel.json` - Vercel configuration

### Files to MODIFY:
1. `components/Wizard.tsx` - Add auth state, update API call
2. `app/api/complete/route.ts` - Replace file writes with Supabase
3. `services/logger.ts` - Remove fs, use console.log
4. `next.config.js` - Add security headers
5. `.env.local` - Update with new credentials (local only, don't commit)

### Files to VERIFY:
1. `.gitignore` - Ensure `.env.local` excluded
2. `package.json` - Verify all dependencies installed

---

## Cost Breakdown

| Service | Tier | Monthly Cost |
|---------|------|--------------|
| **Supabase** | Free | $0 (500MB DB, 50K users) |
| **Vercel** | Hobby | $0 (100GB bandwidth) |
| **Anthropic** | Pay-per-use | ~$5-20 (depends on usage) |
| **Total** | | **$5-20/month** |

---

## Testing Checklist

### Guest Flow
- [ ] Complete quiz without signing in
- [ ] Download JSON works
- [ ] Download PDF works (if implemented)
- [ ] No data saved to database

### Authenticated Flow
- [ ] Sign up with Google OAuth
- [ ] Sign up with Email/Password
- [ ] Complete quiz - saves to Supabase
- [ ] Logout and login - can see saved profile
- [ ] Dark Triad scores visible

### Security
- [ ] API routes require authentication in production
- [ ] RLS prevents cross-user access
- [ ] Credentials rotated and working
- [ ] No sensitive data in logs

---

## Rollback Plan

If deployment fails:
```bash
vercel rollback [deployment-url]
```

Or via Vercel Dashboard → Deployments → Previous → "Promote to Production"

---

## Next Steps After Deployment

1. Monitor Vercel logs for errors
2. Check Anthropic usage vs budget
3. Set up alerts (Sentry optional)
4. Document API_SECRET_KEY usage
5. Test from multiple devices/browsers
6. Collect user feedback

---

## Estimated Timeline

- **Day 1**: Security rotation + Supabase setup (3-4 hours)
- **Day 2**: Auth UI + Wizard updates (5-6 hours)
- **Day 3**: API changes + Guest downloads + Security config (5-6 hours)
- **Day 4**: Testing + Deployment (2-3 hours)

**Total**: 15-20 hours over 4 days

---

## Success Criteria

✅ No file system operations (Vercel-compatible)
✅ Users can sign up via Google or Email
✅ Guest mode allows download without account
✅ Dark Triad visible to all users
✅ All profiles stored in Supabase with RLS
✅ Credentials rotated and secure
✅ Cost under $20/month
✅ Public access working correctly
