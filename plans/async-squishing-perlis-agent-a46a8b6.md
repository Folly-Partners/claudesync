# Deep Personality Codebase: Comprehensive Simplicity & Maintainability Review

## Executive Summary

This Next.js 15 application has **significant complexity issues** that violate YAGNI principles and reduce maintainability. While the codebase demonstrates solid psychological domain knowledge, it suffers from:

- **Massive component files** (1,264 lines in Wizard.tsx)
- **Duplicate configuration** (two Tailwind config files)
- **Premature abstractions** (multiple Supabase client creators for minimal benefit)
- **Inconsistent patterns** across the codebase
- **Over-engineering** in several areas
- **Dead code** and unused exports

**Estimated LOC Reduction Potential: 30-40%** (removing ~600-800 lines of unnecessary code)

---

## Core Purpose

The application provides:
1. A multi-step psychological assessment wizard
2. AI-powered personality analysis using Claude API
3. User profile management with Supabase
4. Stripe payment integration for premium features
5. Relationship compatibility analysis

---

## Critical Issues Found

### 1. MASSIVE COMPONENT FILES (HIGH PRIORITY)

**File: `/Users/andrewwilkinson/Deep-Personality/components/Wizard.tsx`**
- **1,264 lines** - This is unacceptable for a single component
- Contains 8+ sub-components that should be extracted
- Mixing engagement logic, UI, auth, storage management

**Violations:**
```typescript
// Lines 22-137: SECTION_META - 115 lines of static config data (EXTRACT)
const SECTION_META: Record<string, { icon: any; timeEstimate: string; insight: string; color: string }> = {
  'ipip_50': { icon: Brain, timeEstimate: '~8 min', ... },
  // ... 25+ more entries
}

// Lines 139-172: MilestoneCelebration component (EXTRACT)
// Lines 175-229: RestartConfirmModal component (EXTRACT)
// Lines 232-269: SectionPreview component (EXTRACT)
// Lines 273-289: StreakIndicator component (EXTRACT)
// Lines 294-320: LikertScale component (EXTRACT)
// Lines 322-487: SectionIntro component (EXTRACT - 165 lines!)
// Lines 489-566: TestStep component (EXTRACT)
// Lines 568-621: MultipleChoiceStep component (EXTRACT)
// Lines 623-766: ResultsStep component (EXTRACT - 143 lines!)
```

**What to do:**
- Split into at least 10 separate files
- Create `/components/wizard/` directory
- Each sub-component in its own file
- Move SECTION_META to `/lib/wizard-config.ts`

**Estimated savings: 0 lines** (split, not removed, but massive maintainability gain)

---

### 2. DUPLICATE CONFIGURATION FILES

**Files:**
- `/Users/andrewwilkinson/Deep-Personality/tailwind.config.js` (exists)
- `/Users/andrewwilkinson/Deep-Personality/tailwnd.config.js` (typo - likely dead code)

**Issue:** Two Tailwind config files - one is clearly a typo and unused.

**Fix:**
```bash
rm tailwnd.config.js  # Delete the typo file
```

**Estimated savings: 42 lines**

---

### 3. OVER-ABSTRACTED SUPABASE CLIENTS

**Files:**
- `/Users/andrewwilkinson/Deep-Personality/lib/supabase/client.ts` (8 lines)
- `/Users/andrewwilkinson/Deep-Personality/lib/supabase/server.ts` (likely similar)
- `/Users/andrewwilkinson/Deep-Personality/lib/supabase/service.ts` (likely similar)

**Current code:**
```typescript
// lib/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

**Issue:**
- Three nearly identical files for minimal abstraction benefit
- Forces developers to remember which to import where
- Adds cognitive load with no real benefit

**Alternative (YAGNI approach):**
```typescript
// lib/supabase.ts - ONE FILE
import { createBrowserClient } from '@supabase/ssr'
import { createServerClient } from '@supabase/ssr'

// For client components
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}

// For server components/API routes
export function createServerClient() { /* ... */ }

// For admin operations
export function createServiceClient() { /* ... */ }
```

**Estimated savings: ~20 lines** (consolidating 3 files into 1)

---

### 4. DEAD CODE AND UNUSED FILES

**Root-level Files:**
- `/Users/andrewwilkinson/Deep-Personality/App.tsx` (326 lines) - This looks like an old version
- `/Users/andrewwilkinson/Deep-Personality/index.tsx` - Likely unused in Next.js 15
- `/Users/andrewwilkinson/Deep-Personality/index.html` - Unused in Next.js
- `/Users/andrewwilkinson/Deep-Personality/metadata.json` - Unclear purpose

**Issue:** Next.js 15 uses the `app/` directory structure. Root-level App.tsx/index files are legacy.

**Fix:**
```bash
# Verify these aren't imported anywhere
grep -r "from.*App.tsx" . --exclude-dir=node_modules
grep -r "from.*index.tsx" . --exclude-dir=node_modules

# If unused, delete:
rm App.tsx index.tsx index.html metadata.json
```

**Estimated savings: ~400 lines**

---

### 5. MIDDLEWARE COMPLEXITY ISSUES

**File: `/Users/andrewwilkinson/Deep-Personality/middleware.ts` (195 lines)**

**Issues:**

1. **Security headers defined inline (30 lines) - Should be config**
```typescript
// Lines 6-31: SECURITY_HEADERS object - EXTRACT to config file
const SECURITY_HEADERS = {
  'X-Frame-Options': 'DENY',
  // ... 10 more headers
}
```

2. **Rate limiting logic mixed with security headers**
   - Rate limiting: Lines 33-182 (149 lines!)
   - This should be a separate middleware or utility

3. **Supabase client creation repeated**
```typescript
// Lines 38-47: Inline Supabase client - should use shared util
function getSupabaseClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) return null;
  return createClient(url, key, {
    auth: { autoRefreshToken: false, persistSession: false }
  });
}
```

**Refactor:**
```typescript
// middleware.ts - SIMPLIFIED (should be ~50 lines)
import { addSecurityHeaders } from '@/lib/middleware/security'
import { checkRateLimit } from '@/lib/middleware/rate-limit'

export async function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;

  // Apply security headers to all routes
  let response = NextResponse.next();
  response = addSecurityHeaders(response);

  // Apply rate limiting only to analyze endpoints
  if (pathname.startsWith('/api/analyze') && request.method === 'POST') {
    const rateLimitResult = await checkRateLimit(request);
    if (rateLimitResult.limited) {
      return rateLimitResult.response;
    }
  }

  return response;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
```

**Create new files:**
- `/lib/middleware/security.ts` - Security headers logic
- `/lib/middleware/rate-limit.ts` - Rate limiting logic
- `/lib/config/security-headers.ts` - Header definitions

**Estimated savings: 0 lines** (refactored, not removed, but much clearer)

---

### 6. MASSIVE SCORING FUNCTION

**File: `/Users/andrewwilkinson/Deep-Personality/services/scoring.ts` (639 lines)**

**Lines 133-639: `generateProfile()` function - 506 lines!**

**Issues:**
- Single function doing 15+ different psychological assessments
- Each assessment is 20-40 lines of similar scoring logic
- Massive duplication in pattern

**Example duplication:**
```typescript
// GAD-7 scoring (lines 305-317)
const gad7Vals = GAD_7.items.map(i => {
  const val = responses[i.id] as number || 1;
  return Math.min(3, val - 1);
});
const gad7Total = sum(gad7Vals);
let gad7Label = 'Minimal';
if (gad7Total >= 15) gad7Label = 'Severe';
else if (gad7Total >= 10) gad7Label = 'Moderate';
else if (gad7Total >= 5) gad7Label = 'Mild';

// PHQ-9 scoring (lines 319-334) - NEARLY IDENTICAL PATTERN
const phq9Vals = PHQ_9.items.map(i => {
  const val = responses[i.id] as number || 1;
  return Math.min(3, val - 1);
});
const phq9Total = sum(phq9Vals);
let phq9Label = 'Minimal';
if (phq9Total >= 20) phq9Label = 'Severe';
// ... same pattern repeated
```

**Refactor approach:**
```typescript
// Create assessment-specific scorers
const scorers = {
  scoreGAD7: (responses) => { /* GAD-7 logic */ },
  scorePHQ9: (responses) => { /* PHQ-9 logic */ },
  scoreIPIP: (responses) => { /* IPIP logic */ },
  // ... etc
}

export const generateProfile = (basicInfo, responses) => {
  return {
    id: generateUUID(),
    name: basicInfo.name,
    timestamp: new Date().toISOString(),
    demographics: extractDemographics(basicInfo),
    assessments: {
      ipip_50: scorers.scoreIPIP(responses),
      gad_7: scorers.scoreGAD7(responses),
      phq_9: scorers.scorePHQ9(responses),
      // ... etc - ONE LINE EACH
    },
    customQuestionResponses: extractCustomResponses(responses)
  };
};
```

**Better approach - separate files:**
```
/services/scoring/
  index.ts          - Main generateProfile function (should be ~50 lines)
  ipip.ts           - IPIP-50 scoring
  clinical.ts       - GAD-7, PHQ-9, PCL-5
  attachment.ts     - ECR-S scoring
  values.ts         - PVQ-21, WEIMS, ONET
  wellbeing.ts      - SWLS, UCLA, PERMA
  utils.ts          - Shared scoring utilities
```

**Estimated savings: 200-250 lines** (through deduplication and extraction)

---

### 7. CONSOLE.LOG POLLUTION

**Found 85 console statements across 12 files**

**Files with most console usage:**
- components/Dashboard.tsx: ~51 instances
- components/Wizard.tsx: ~6 instances
- middleware.ts: ~3 instances

**Issues:**
- Production logs shouldn't use console.log
- Should use structured logger (already exists at `services/logger.ts`)
- Inconsistent usage - some files use logger, others use console

**Fix:**
```typescript
// BAD
console.log('User authenticated:', user);
console.error('Failed to fetch:', error);

// GOOD
logServerEvent('[Auth] User authenticated', 'INFO', { userId: user.id });
logServerEvent('[Fetch] Failed to load profiles', 'ERROR', { error });
```

**Estimated cleanup: Replace ~85 console statements**

---

### 8. HARDCODED MAGIC NUMBERS

**File: `/Users/andrewwilkinson/Deep-Personality/components/Wizard.tsx`**

```typescript
// Lines 139-146: Magic milestone values
const MILESTONES = [25, 50, 75, 100];
const MILESTONE_MESSAGES = {
  25: { emoji: '🎯', message: "Great start! You're building momentum." },
  50: { emoji: '🔥', message: "Halfway there! Your profile is taking shape." },
  // ... etc
};
```

**File: `/Users/andrewwilkinson/Deep-Personality/services/scoring.ts`**

```typescript
// Lines 27-33: IPIP norms hardcoded
const IPIP_NORMS: Record<string, { mean: number; sd: number }> = {
  openness: { mean: 37.4, sd: 6.5 },
  conscientiousness: { mean: 35.1, sd: 6.8 },
  // ... etc
};

// Lines 42-44: ECR thresholds
const ECR_THRESHOLDS = {
  anxietyHigh: 3.2,
  avoidanceHigh: 3.2
};

// Many more scattered throughout
```

**Issue:** These are good - they're named constants. But they should be in config files, not embedded in components/logic.

**Recommendation:**
```
/lib/config/
  assessment-norms.ts    - All psychological norms and thresholds
  engagement.ts          - Milestone config
  ui-constants.ts        - UI-related constants
```

**Estimated savings: 0 lines** (organization, not reduction)

---

### 9. COMPLEX COLOR CLASS MAPPING

**File: `/Users/andrewwilkinson/Deep-Personality/components/Wizard.tsx` (Lines 237-251)**

```typescript
const colorClasses: Record<string, string> = {
  blue: 'bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 border-blue-200 dark:border-blue-800',
  purple: 'bg-purple-50 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400 border-purple-200 dark:border-purple-800',
  rose: 'bg-rose-50 dark:bg-rose-900/30 text-rose-600 dark:text-rose-400 border-rose-200 dark:border-rose-800',
  // ... 10 more similar entries
};
```

**Issue:**
- 15 lines of Tailwind class strings that are hard to read
- Repeated pattern that could be generated
- Should use Tailwind's @apply or component styles

**Refactor:**
```typescript
// lib/ui/color-variants.ts
export const getColorClasses = (color: string) =>
  `bg-${color}-50 dark:bg-${color}-900/30 text-${color}-600 dark:text-${color}-400 border-${color}-200 dark:border-${color}-800`;

// OR better - use CSS classes in global stylesheet
// .card-blue { @apply bg-blue-50 dark:bg-blue-900/30 ... }
```

**Estimated savings: 12 lines**

---

### 10. INCONSISTENT AUTH PATTERNS

**Different auth checks across files:**

```typescript
// Pattern 1: middleware.ts (lines 79-90)
const supabaseAuth = await createClient();
const { data: { user } } = await supabaseAuth.auth.getUser();
if (!user) {
  const authHeader = req.headers.get('x-api-key');
  if (!API_SECRET_KEY || authHeader !== API_SECRET_KEY) {
    return new Response("Unauthorized", { status: 401 });
  }
}

// Pattern 2: components/Wizard.tsx (lines 806-843)
useEffect(() => {
  const checkUserAndProfiles = async (session: any, isInitialCheck: boolean = false) => {
    const currentUser = session?.user ?? null;
    setUser(currentUser);
    if (currentUser) {
      try {
        const response = await fetch('/api/profiles');
        // ...
      }
    }
  };
});

// Pattern 3: App.tsx (lines 35-84)
useEffect(() => {
  const supabase = createClient();
  const checkAuthAndProgress = async () => {
    const { data: { user: authUser } } = await supabase.auth.getUser();
    if (authUser) {
      setUser(authUser);
      // ...
    }
  };
});
```

**Issue:** Three different patterns for doing essentially the same thing (check auth).

**Fix:** Create consistent auth hooks/utilities:
```typescript
// lib/hooks/useAuth.ts
export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const supabase = createClient();
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      setLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });

    return () => subscription.unsubscribe();
  }, []);

  return { user, loading };
}

// Usage: const { user, loading } = useAuth();
```

**Estimated savings: ~60 lines** (deduplicated auth logic)

---

### 11. OVER-ENGINEERED SAMPLE PROFILES

**File: `/Users/andrewwilkinson/Deep-Personality/components/Dashboard.tsx` (Lines 173-475)**

**303 lines of hardcoded sample profile data!**

```typescript
const ALEX_PROFILE = {
  "id": "alex-sample-uuid",
  "name": "Alexa",
  "timestamp": "2023-10-27T10:00:00.000Z",
  // ... 150 more lines
};

const SAM_PROFILE = {
  "id": "sam-sample-uuid",
  "name": "Sam",
  // ... 150 more lines
};
```

**Issue:**
- Embedding 300+ lines of JSON in a component file
- Should be in separate JSON files
- Bloats component unnecessarily

**Fix:**
```typescript
// Move to /lib/sample-data/profiles.json or separate files
import ALEX_PROFILE from '@/lib/sample-data/alex-profile.json';
import SAM_PROFILE from '@/lib/sample-data/sam-profile.json';
```

**Estimated savings: 0 lines moved** (but massive readability improvement)

---

### 12. UNNECESSARILY COMPLEX MARKDOWN COMPONENTS

**File: `/Users/andrewwilkinson/Deep-Personality/components/Dashboard.tsx` (Lines 33-156)**

**124 lines of custom Markdown component overrides**

**Issue:**
- Every HTML element gets a custom styled component
- Many are just adding Tailwind classes
- Could use a theme system instead

**Current:**
```typescript
const MarkdownComponents = {
  h1: ({ children, ...props }) => (
    <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100 mb-2 pb-4 border-b-2 border-blue-100 dark:border-blue-900 flex items-center gap-3" {...props}>
      <Sparkles className="w-7 h-7 text-blue-500 dark:text-blue-400" />
      {children}
    </h1>
  ),
  h2: ({ children, ...props }) => { /* 30 lines of icon selection logic */ },
  h3: ({ children, ...props }) => { /* 15 lines */ },
  // ... 10 more elements
};
```

**Simplified approach:**
```css
/* globals.css - Let CSS do the work */
.markdown h1 { @apply text-3xl font-bold text-slate-900 dark:text-slate-100 mb-2 pb-4 border-b-2 border-blue-100 dark:border-blue-900; }
.markdown h2 { @apply text-xl font-bold mt-10 mb-4 p-4 rounded-xl; }
/* ... etc */
```

```typescript
// Much simpler component
<div className="markdown prose dark:prose-invert">
  <ReactMarkdown>{content}</ReactMarkdown>
</div>
```

**Note:** The icon logic in h2 is actually valuable - keep that, but simplify the rest.

**Estimated savings: ~60 lines**

---

### 13. STORAGE KEY DUPLICATION

**Multiple storage keys scattered across files:**

```typescript
// Wizard.tsx (line 13)
const STORAGE_KEY = 'deep_personality_quiz_v2';
const RESTART_COUNT_KEY = 'deep_personality_restart_count';
const TIMING_KEY = 'deep_personality_timings';

// App.tsx (line 22)
const STORAGE_KEY = 'deep_personality_quiz_v2';

// Other places:
localStorage.setItem('deep_personality_user_email', ...)
localStorage.setItem('deep_personality_is_guest', ...)
localStorage.setItem('deep_personality_submitted', 'true')
```

**Issue:**
- Same constants duplicated across files
- Easy to create bugs if one is changed and another isn't
- No single source of truth

**Fix:**
```typescript
// lib/constants/storage.ts
export const STORAGE_KEYS = {
  QUIZ_STATE: 'deep_personality_quiz_v2',
  RESTART_COUNT: 'deep_personality_restart_count',
  TIMING: 'deep_personality_timings',
  USER_EMAIL: 'deep_personality_user_email',
  IS_GUEST: 'deep_personality_is_guest',
  SUBMITTED: 'deep_personality_submitted',
} as const;

// Usage:
import { STORAGE_KEYS } from '@/lib/constants/storage';
localStorage.getItem(STORAGE_KEYS.QUIZ_STATE);
```

**Estimated savings: ~5 lines** (but prevents future bugs)

---

### 14. OVERLY DEFENSIVE VALIDATION

**File: `/Users/andrewwilkinson/Deep-Personality/components/Wizard.tsx` (Lines 898-927)**

```typescript
if (saved) {
  try {
    const parsed = JSON.parse(saved);

    // Validate the parsed data structure
    if (typeof parsed !== 'object' || parsed === null) {
      throw new Error('Invalid progress data structure');
    }

    // Safety check if step is out of bounds
    if (typeof parsed.step === 'number' && parsed.step >= 0 && parsed.step < steps.length) {
      setStep(parsed.step);
    } else {
      setStep(0);
    }

    setBasicInfo({ name: '', age: '', email: '', gender: '', occupation: '', relationshipStatus: '', ...parsed.basicInfo });
    setAnswers(parsed.answers || {});
    setStorageError(null);
  } catch (parseError) {
    console.error("Failed to parse saved progress:", parseError);
    localStorage.removeItem(STORAGE_KEY);
    setStorageError("Your saved progress was corrupted and has been cleared. Please start fresh.");
  }
}
```

**Issue:**
- Nested try-catch inside try-catch
- Over-validation that adds complexity
- The `typeof parsed.step === 'number'` check is YAGNI

**Simplified:**
```typescript
if (saved) {
  try {
    const parsed = JSON.parse(saved);
    setStep(parsed.step ?? 0);
    setBasicInfo({ name: '', age: '', email: '', ...parsed.basicInfo });
    setAnswers(parsed.answers ?? {});
  } catch {
    localStorage.removeItem(STORAGE_KEY);
    setStorageError("Saved progress was corrupted. Starting fresh.");
  }
}
```

**Estimated savings: 15 lines**

---

### 15. REDUNDANT ERROR HANDLING

**Pattern repeated throughout:**

```typescript
// Wizard.tsx (lines 813-825)
if (currentUser) {
  try {
    const response = await fetch('/api/profiles');
    if (response.ok) {
      const data = await response.json();
      if (data.profiles && data.profiles.length > 0) {
        setAlreadySubmitted(true);
        setLastMilestone(100);
      }
    }
  } catch (err) {
    console.error('Failed to check for existing profiles:', err);
  }
}
```

**Issue:**
- Silent error handling everywhere
- No user feedback on failures
- "Fail silently" is not always the right choice

**Better approach:**
```typescript
// lib/api/profiles.ts
export async function fetchUserProfiles() {
  const response = await fetch('/api/profiles');
  if (!response.ok) {
    throw new Error(`Failed to fetch profiles: ${response.status}`);
  }
  return response.json();
}

// In component:
if (currentUser) {
  try {
    const data = await fetchUserProfiles();
    if (data.profiles?.length > 0) {
      setAlreadySubmitted(true);
      setLastMilestone(100);
    }
  } catch (err) {
    // Actually handle the error - show toast, retry button, etc.
    showError('Could not load your previous assessments. Please try again.');
  }
}
```

---

## Summary of Recommended Actions

### Immediate Wins (High Impact, Low Effort)

1. **Delete duplicate Tailwind config** (`tailwnd.config.js`)
   - Effort: 5 seconds
   - Impact: Removes confusion

2. **Delete dead root files** (App.tsx, index.tsx, index.html if unused)
   - Effort: 2 minutes (verify unused first)
   - Impact: ~400 lines removed

3. **Consolidate Supabase clients** into single file
   - Effort: 15 minutes
   - Impact: ~20 lines saved, clearer imports

4. **Extract SECTION_META** to config file
   - Effort: 10 minutes
   - Impact: Makes Wizard.tsx 115 lines shorter

5. **Move sample profiles** to JSON files
   - Effort: 10 minutes
   - Impact: Dashboard.tsx 303 lines shorter

6. **Create STORAGE_KEYS constant**
   - Effort: 10 minutes
   - Impact: Prevents future bugs

### Medium-Term Improvements (High Impact, Medium Effort)

7. **Split Wizard.tsx** into separate component files
   - Effort: 2-3 hours
   - Impact: Massive maintainability improvement

8. **Refactor scoring.ts** into separate assessment scorers
   - Effort: 3-4 hours
   - Impact: ~200-250 lines saved, much clearer logic

9. **Replace console statements** with structured logging
   - Effort: 1-2 hours
   - Impact: Better production debugging

10. **Create useAuth hook** to standardize auth patterns
    - Effort: 1 hour
    - Impact: ~60 lines saved, consistent auth

### Long-Term Refactoring (Lower Priority)

11. **Simplify Markdown components** (keep icon logic, simplify styling)
    - Effort: 1 hour
    - Impact: ~60 lines saved

12. **Extract middleware** into separate utility files
    - Effort: 1-2 hours
    - Impact: Better organization

13. **Consolidate color class generation**
    - Effort: 30 minutes
    - Impact: ~12 lines saved

14. **Simplify validation logic**
    - Effort: 1 hour
    - Impact: ~15-20 lines saved

15. **Improve error handling** with user feedback
    - Effort: 2-3 hours
    - Impact: Better UX

---

## Final Assessment

**Total potential LOC reduction: 600-800 lines (30-40%)**

**Complexity score: HIGH**
- Current state has files that are too long (1,264 lines!)
- Too many responsibilities per file
- Inconsistent patterns
- Over-engineering in some areas
- But solid domain logic and good psychological validity

**Recommended action: PROCEED WITH AGGRESSIVE SIMPLIFICATIONS**

The codebase would benefit enormously from:
1. Splitting large components
2. Extracting configuration
3. Consolidating patterns
4. Removing dead code
5. Simplifying over-engineered areas

**Most critical files to refactor (in priority order):**
1. `/components/Wizard.tsx` (1,264 lines → should be ~200 lines + extracted components)
2. `/components/Dashboard.tsx` (huge, needs sample data extraction)
3. `/services/scoring.ts` (639 lines → should be ~100 lines + separate scorers)
4. `/middleware.ts` (195 lines → should be ~50 lines + extracted utilities)

This codebase is functional but has grown organically without enough refactoring. The good news: the core logic is sound. The bad news: it's getting hard to maintain. Time to pay down that technical debt!
