# Plan: Ultra-Deep Learning System with Insights Dashboard

## Problem
Current system only runs ~5 AI queries sampling 50 emails. Replies are generic - same voice for all recipients, no learning from user choices, no example-based generation.

## Solution
Comprehensive 10-20 minute initial sync with **75-100+ AI queries**, followed by an **Insights Dashboard** showing everything learned with an **interactive preference editor**. User sees exactly what the system learned and can refine it.

---

## User Experience Flow

### 1. Initial Sync Page (10-20 minutes)
- Full-screen sync experience with detailed progress
- Shows each analysis phase as it runs
- Live counter of emails processed, patterns found
- "This comprehensive analysis ensures replies sound exactly like you"

### 2. Insights Dashboard (after sync)
- **Writing DNA** - Your unique voice fingerprint
- **Relationship Map** - Who you email, how you talk to them
- **Response Patterns** - How you handle different email types
- **Example Library** - Your best replies categorized
- **Team & Contacts** - Detected assistants, team, VIPs

### 3. Preference Editor
- Adjust formality per person/domain
- Mark people as VIP/assistant/delegate
- Edit/add example replies
- Set CC rules manually
- Override any AI inference

---

## Critical Rules for Reply Generation

1. **NEVER propose specific dates/times** - Leave scheduling to assistant
2. **NEVER fabricate details** - Keep replies high-level
3. **Auto-suggest CC per reply option** - e.g., meeting request → suggest CC'ing assistant

---

## Ultra-Deep Analysis (75-100+ AI Queries)

### Analysis Dimensions

| Category | Queries | What's Analyzed |
|----------|---------|-----------------|
| **Voice & Style** | 10-12 | |
| - General writing patterns | 3 | 500+ sent emails, sentence structure, vocabulary |
| - Formality spectrum | 2 | Formal→casual range by context |
| - Emotional tone patterns | 2 | Enthusiasm, urgency, warmth signals |
| - Humor/personality | 2 | When/how you use humor, personality quirks |
| - Subject line style | 2 | How you write subjects |
| | | |
| **Per-Recipient Profiles** | 25-30 | |
| - Top 100 contacts | 10 | Voice profile per person (batches of 10) |
| - Relationship classification | 5 | Executive/peer/report/external/personal |
| - Communication frequency | 3 | Daily/weekly/monthly patterns |
| - Tone adaptation | 5 | How voice changes per relationship |
| - Historical context | 5 | What topics discussed with whom |
| | | |
| **Domain & Org Analysis** | 10-12 | |
| - Internal vs external | 2 | Domain classification |
| - Company formality | 3 | Per-company tone settings |
| - Industry patterns | 2 | Tech vs finance vs media, etc. |
| - Org chart inference | 3 | Who reports to whom, team structure |
| | | |
| **Example Extraction** | 15-20 | |
| - Reply categorization | 5 | Scheduling/approval/question/update/etc. |
| - Best reply selection | 5 | Highest quality examples per category |
| - Template parsing | 5 | Greeting/body/closing extraction |
| - Context matching | 3 | What triggers which response type |
| | | |
| **CC & Delegation** | 8-10 | |
| - Assistant detection | 2 | Who handles your scheduling |
| - CC trigger analysis | 3 | When you CC people, why |
| - Delegation patterns | 3 | Who handles what topics |
| - Introduction style | 2 | How you loop people in |
| | | |
| **Temporal Patterns** | 5-8 | |
| - Response time by sender | 2 | Who gets fast replies |
| - Time-of-day tone | 2 | Morning vs evening style |
| - Day-of-week patterns | 2 | Weekday vs weekend |
| - Urgency detection | 2 | How you handle urgent vs normal |
| | | |
| **Advanced Patterns** | 5-8 | |
| - Follow-up style | 2 | How you chase responses |
| - Thread behavior | 2 | Long thread vs short thread tone |
| - Attachment patterns | 2 | When you send files vs links |
| - Signature variations | 2 | Different signatures for contexts |

**Total: 75-100 AI queries** for comprehensive analysis

---

## Implementation Steps

### Step 1: Create Sync Experience
**New File: `/app/sync/page.tsx`**

Full-screen sync page with:
- Progress bar with phases
- Live stats (emails processed, patterns found, contacts analyzed)
- Current phase description
- Estimated time remaining
- "What we're learning" explanations

### Step 2: Create Insights Dashboard
**New File: `/app/insights/page.tsx`**

Sections:
1. **Your Writing DNA**
   - Word cloud of your vocabulary
   - Formality spectrum visualization
   - Tone distribution chart
   - Signature examples

2. **Relationship Map**
   - Visual network of contacts
   - Color-coded by relationship type
   - Click to see voice profile per person

3. **Response Patterns**
   - How you handle different email types
   - Average response time by sender type
   - CC patterns visualization

4. **Example Library**
   - Your best replies categorized
   - "These are replies you can be proud of"
   - Searchable by category/recipient

5. **Your Team**
   - Detected assistants with confidence
   - Team members with topics they handle
   - Delegates with areas of responsibility

### Step 3: Create Preference Editor
**New File: `/app/insights/preferences/page.tsx`**

Interactive controls for:
- **People Settings** - Adjust formality/relationship per person
- **Domain Rules** - Set default tone per domain
- **CC Rules** - When to suggest CC'ing whom
- **Example Management** - Add/edit/delete example replies
- **Assistant Setup** - Confirm who handles scheduling
- **Override Any Inference** - Full manual control

### Step 4: Add New Types
**File: `/lib/types.ts`**

Add comprehensive types for all analysis dimensions (see detailed types below)

### Step 5: Create Ultra-Deep Learner
**New File: `/lib/patterns/ultraDeepLearner.ts`**

Orchestrates all 75-100 queries with:
- Parallel execution where possible
- Progress callbacks for each phase
- Insight extraction for dashboard
- Preference suggestions for editor

### Step 6: Create Analysis API Endpoints

**Voice & Style:**
- `/app/api/ai/analyze-writing-deep/route.ts` - 500+ emails
- `/app/api/ai/analyze-formality-spectrum/route.ts`
- `/app/api/ai/analyze-emotional-tone/route.ts`
- `/app/api/ai/analyze-personality/route.ts`
- `/app/api/ai/analyze-subject-lines/route.ts`

**Recipient Profiles:**
- `/app/api/ai/analyze-recipient-batch/route.ts` - 10 people per call
- `/app/api/ai/classify-relationships/route.ts`
- `/app/api/ai/analyze-tone-adaptation/route.ts`
- `/app/api/ai/extract-historical-context/route.ts`

**Domain & Org:**
- `/app/api/ai/analyze-domains/route.ts`
- `/app/api/ai/infer-org-chart/route.ts`
- `/app/api/ai/analyze-industry-patterns/route.ts`

**Examples:**
- `/app/api/ai/categorize-replies/route.ts`
- `/app/api/ai/select-best-examples/route.ts`
- `/app/api/ai/parse-reply-templates/route.ts`

**CC & Delegation:**
- `/app/api/ai/detect-assistants/route.ts`
- `/app/api/ai/analyze-cc-triggers/route.ts`
- `/app/api/ai/analyze-delegation/route.ts`

**Temporal:**
- `/app/api/ai/analyze-response-times/route.ts`
- `/app/api/ai/analyze-temporal-patterns/route.ts`

### Step 7: Enhance Reply Generation
**File: `/app/api/ai/generate-replies/route.ts`**

Major enhancement to use ALL learned data:
- Per-recipient voice profile
- Actual example replies as templates
- Smart CC suggestions per option
- Temporal context (time of day, day of week)
- Thread position awareness
- Relationship-appropriate tone

Prompt includes:
```
YOUR VOICE PROFILE FOR [SENDER NAME]:
- Relationship: [executive/peer/etc]
- Your typical formality: [formal/casual/etc]
- Greetings you use: [actual examples]
- Closings you use: [actual examples]
- Topics you discuss: [from history]
- Your tone with them: [warm/direct/etc]

EXAMPLE REPLIES TO SIMILAR EMAILS:
[3 actual past replies with context]

CONTEXT:
- Time: [morning/afternoon/evening]
- Thread position: [first reply / deep in thread]
- Urgency: [urgent/normal/low]

CRITICAL RULES:
1. NEVER propose specific dates/times
2. NEVER fabricate details you don't know
3. Match the voice profile EXACTLY
4. Suggest appropriate CC recipients
```

### Step 8: Update Database Schema
**File: `/lib/storage/db.ts`**

New tables for all analysis data + insights + preferences

### Step 9: Update Feedback System
**File: `/lib/patterns/feedback.ts`**

Track everything user does for continuous learning

---

## Files to Create/Modify

### New Pages (3)
| File | Purpose |
|------|---------|
| `/app/sync/page.tsx` | Full-screen sync experience with progress |
| `/app/insights/page.tsx` | Insights dashboard showing everything learned |
| `/app/insights/preferences/page.tsx` | Interactive preference editor |

### New API Endpoints (15+)
| File | Purpose |
|------|---------|
| `/app/api/ai/analyze-writing-deep/route.ts` | Deep writing analysis (500+ emails) |
| `/app/api/ai/analyze-formality-spectrum/route.ts` | Formality range analysis |
| `/app/api/ai/analyze-emotional-tone/route.ts` | Emotional patterns |
| `/app/api/ai/analyze-personality/route.ts` | Humor, quirks, personality |
| `/app/api/ai/analyze-subject-lines/route.ts` | Subject line patterns |
| `/app/api/ai/analyze-recipient-batch/route.ts` | Per-recipient voice (batch of 10) |
| `/app/api/ai/classify-relationships/route.ts` | Relationship types |
| `/app/api/ai/analyze-tone-adaptation/route.ts` | How tone varies by person |
| `/app/api/ai/analyze-domains/route.ts` | Domain formality |
| `/app/api/ai/infer-org-chart/route.ts` | Team structure |
| `/app/api/ai/categorize-replies/route.ts` | Reply categorization |
| `/app/api/ai/select-best-examples/route.ts` | Best example selection |
| `/app/api/ai/detect-assistants/route.ts` | Assistant detection |
| `/app/api/ai/analyze-cc-triggers/route.ts` | CC pattern analysis |
| `/app/api/ai/analyze-temporal-patterns/route.ts` | Time-based patterns |

### New Core Files (2)
| File | Purpose |
|------|---------|
| `/lib/patterns/ultraDeepLearner.ts` | Orchestrates 75-100 AI queries |
| `/lib/insights/generator.ts` | Generates insights for dashboard |

### Modified Files (6)
| File | Changes |
|------|---------|
| `/lib/types.ts` | Add 10+ new types for all analysis dimensions |
| `/lib/storage/db.ts` | Add 8+ new tables for all data |
| `/app/api/ai/generate-replies/route.ts` | Use all learned data + CC suggestions |
| `/lib/patterns/feedback.ts` | Comprehensive feedback tracking |
| `/lib/prefetch/emailPrefetcher.ts` | Pass all context to generation |
| `/components/actions/ActionPanel.tsx` | Show CC suggestions per reply |

---

## Expected Outcome

**Before:**
- 5 AI queries, 50 emails sampled
- Generic voice for all recipients
- No insights, no preference control

**After:**
- 75-100 AI queries, 500+ emails analyzed
- Per-recipient voice profiles for 100 contacts
- Full insights dashboard showing what was learned
- Interactive preference editor
- Example-based reply generation
- Smart CC suggestions per reply option
- Continuous learning from feedback

### User Flow:
1. **Sync** (10-20 min) - Watch detailed progress, understand what's being learned
2. **Review Insights** - See your "Writing DNA", relationship map, best examples
3. **Adjust Preferences** - Correct any AI inferences, set CC rules
4. **Start Triaging** - Replies now sound exactly like YOU to each specific person
