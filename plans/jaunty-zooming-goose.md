# Enhanced Analysis Progress + Auto Background Check

## Two Goals
1. **Auto Background Check** - Run during analysis, not manual button
2. **Cool Progress Screen** - Show detailed step-by-step activity in a fun way

---

## Part 1: Enhanced Progress Screen

### Current State (boring)
- 5 generic phases with static labels
- Just checkmarks and spinner
- No visibility into what's actually happening
- No sub-steps or detail

### Target State (cool)
A **live activity feed** showing real work happening:
- Animated terminal/console aesthetic
- Real-time sub-steps appearing as they happen
- Shows actual searches, API calls, findings
- Typewriter effect for new items
- Color-coded by type (search, API, AI, validation)

### Visual Design Concept

```
┌─────────────────────────────────────────────────────────┐
│  Analyzing: Acme Corp                                   │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  65%       │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ > Researching Company                    [DONE] │   │
│  │   ├─ Searching company background...     ✓      │   │
│  │   ├─ Finding leadership team...          ✓      │   │
│  │   ├─ Checking news & press releases...   ✓      │   │
│  │   └─ Found 4 executives                  ✓      │   │
│  │                                                 │   │
│  │ > Vetting Leadership                  [ACTIVE]  │   │
│  │   ├─ Checking OFAC sanctions list...     ✓      │   │
│  │   ├─ Querying FINRA BrokerCheck...       ✓      │   │
│  │   ├─ Scanning news for John Smith...     ▸      │   │
│  │   │                                             │   │
│  │ > Running Valuation                  [PENDING]  │   │
│  │ > Generating Report                  [PENDING]  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ⏱ Estimated: ~30 seconds remaining                    │
└─────────────────────────────────────────────────────────┘
```

### Sub-Steps by Phase

**Phase 1: Research**
- "Searching company background..."
- "Finding leadership team..."
- "Checking recent news..."
- "Analyzing competitors..."
- "Found {N} executives"

**Phase 2: Vetting Leadership** (NEW)
- "Checking OFAC sanctions list..."
- "Querying FINRA BrokerCheck..."
- "Scanning news for {Name}..."
- "{N} clean, {M} flagged"

**Phase 3: Processing Documents** (if any)
- "Reading {filename}..."
- "Extracting financial data..."
- "Found {N} years of financials"

**Phase 4: Valuation Analysis**
- "Calculating revenue multiples..."
- "Finding comparable transactions..."
- "Running scenario models..."

**Phase 5: Report Generation**
- "Writing executive summary..."
- "Generating LOI structure..."
- "Preparing recommendations..."

### Implementation: New Component

**Create:** `components/AnalysisProgress.tsx`

```typescript
interface ProgressStep {
  id: string;
  label: string;
  status: 'pending' | 'active' | 'done' | 'error';
  subSteps: {
    id: string;
    text: string;
    status: 'pending' | 'active' | 'done' | 'error';
    result?: string; // e.g., "Found 4 executives"
  }[];
}

interface Props {
  companyName: string;
  steps: ProgressStep[];
  overallPercent: number;
  estimatedSecondsRemaining?: number;
}
```

### State Management

In `app/page.tsx`, track detailed progress:

```typescript
const [progressSteps, setProgressSteps] = useState<ProgressStep[]>([...]);

// Helper to update sub-steps
const addSubStep = (phaseId: string, subStep: SubStep) => {...};
const completeSubStep = (phaseId: string, subStepId: string, result?: string) => {...};
```

---

## Part 2: Auto Background Check Integration

### Changes to handleAnalyze Flow

```
Current:
  Research → Industry → Documents → Analysis → Report → [Manual BG Check button]

New:
  Research → Vetting → Documents → Analysis → Report
             ↑
             Auto background check on leadership found in research
```

### Key Integration Point

After research API returns with leadership profiles:

```typescript
// After research completes
if (researchResult.leadershipProfiles?.length > 0) {
  setCurrentPhase('vetting');
  addSubStep('vetting', { text: 'Checking OFAC sanctions...', status: 'active' });

  const bgReport = await fetch('/api/background-check', {
    method: 'POST',
    body: JSON.stringify({
      companyName,
      leaders: researchResult.leadershipProfiles
    })
  });

  // Store results for later
  backgroundReport = await bgReport.json();
}
```

### Type Changes

```typescript
// In lib/types.ts
interface AnalysisResult {
  // existing...
  backgroundReport?: LeadershipBackgroundReport;
}
```

### LeadershipSection Update

- Accept `backgroundReport` prop
- Remove manual button/fetch
- Display pre-computed results
- Keep optional "Refresh" for re-running

---

## Files to Modify

| File | Changes |
|------|---------|
| `components/AnalysisProgress.tsx` | **NEW** - Cool progress component |
| `app/page.tsx` | Replace inline progress UI, add vetting phase, track sub-steps |
| `lib/types.ts` | Add backgroundReport to AnalysisResult |
| `components/LeadershipSection.tsx` | Accept backgroundReport prop, remove manual trigger |
| `components/AnalysisReport.tsx` | Pass backgroundReport prop |

---

## CSS/Styling Notes

- Dark terminal-style background for the activity log
- Monospace font for sub-steps
- Typewriter animation for new items appearing
- Pulse animation on active items
- Green checkmarks, yellow warnings, red errors
- Smooth progress bar with gradient

---

# ARCHIVED: Original Improvement Plan

*(The original comprehensive plan is below for reference)*

---

## 1. PDF Export Improvements
**File:** `components/PDFExport.tsx`

**Current State:** Uses html2pdf.js to capture the DOM element and export. Basic formatting with 0.5" margins.

**Improvements:**
- Create a dedicated print-optimized layout with `@media print` styles
- Add proper page breaks between sections
- Use serif font (Georgia) for body text, increase line height
- Add header/footer with company name and page numbers
- Optimize table layouts for portrait A4/Letter
- Consider using a CSS print stylesheet or generating a cleaner HTML structure specifically for PDF

---

## 2. Remove Top PPTX Export Button
**File:** `components/AnalysisReport.tsx` (lines ~40-60 for header buttons)

**Action:** Remove the "Export PPTX" button from the top header area. Keep it only in the Lender Recommendations section where users select a specific bank.

---

## 3. Remove "Add Tag" Feature
**Files to modify:**
- `components/TagEditor.tsx` - DELETE entire file
- `components/AnalysisReport.tsx` - Remove TagEditor import and usage
- `components/AnalysisCard.tsx` - Remove tag display/editing
- `app/dashboard/page.tsx` - Remove tag filtering functionality
- `lib/analysisStorage.ts` - Remove `getAllTags()` method
- `lib/types.ts` - Remove `tags` field from `SavedAnalysis`

---

## 4. Improve "Improve This Analysis" Section Design
**File:** `components/DocumentUploadPrompt.tsx`

**Current Issues:** Looks cluttered with checklist items + upload area

**Proposed Design:**
- Clean dropzone as the primary focus
- Add collapsible "What documents help?" section below (collapsed by default)
- Remove the 4-item checklist grid from main view
- Lighter, more elegant card style
- Keep uploaded files list but more compact
- Hint text on dropzone: "PDF, Excel, Word, CSV"

---

## 5. Leadership Team Photos
**Files:**
- `app/api/research/route.ts` - Photo fetching logic
- `components/LeadershipSection.tsx` - Photo display

**Current State:** Research API extracts photo URLs from search results, often unreliable

**Approach:** Show only verified photos, initials avatar otherwise

**Implementation:**
- Validate photo URLs against trusted patterns:
  - LinkedIn CDN: `media.licdn.com/*`
  - Company domain: `{companywebsite}/*`
  - Known reliable sources (e.g., Crunchbase, Bloomberg)
- If URL doesn't match trusted patterns → show initials avatar
- Add `isVerifiedPhoto` flag to leadership data
- Fallback to elegant initials avatar (first + last initial)

---

## 6. Fix Financial Summary Section
**File:** `components/FinancialSummary.tsx`

**Issue:** Screenshot shows `** - 2025E Gross Margin: 73.` - malformed markdown rendering

**Root Cause:** The component parses AI-generated text with regex. If format doesn't match expected patterns, it shows raw/broken text.

**Fix:**
- Improve regex patterns for edge cases
- Add better fallback rendering when parsing fails
- Sanitize markdown output before display
- Consider structured JSON response from AI instead of parsing markdown

---

## 7. Improve 5-Year Projections Table Clarity
**File:** `components/FiveYearProjections.tsx`

**Current Issues:**
- Column names are jargon-y ("Shit The Bed", "Bird In Hand - 1/2", "+ Two In Bush")
- Too many scenarios side-by-side
- Hard to understand what each scenario represents

**Proposed Improvements:**
- Rename scenarios to clearer labels:
  - "Shit The Bed" → "Downside"
  - "Bird In Hand - 1" → "Base Case"
  - "Bird In Hand - 2" → "Upside"
  - "+ Two In Bush" → "Bull Case"
- Add a brief legend explaining each scenario (1 line each)
- Improve visual hierarchy with clearer section dividers
- Keep all 4 scenarios visible but with better spacing

---

## 8. Fix Lender Recommendations Grid Layout
**File:** `components/LenderRecommendations.tsx`

**Current Issues:**
- Cards have varying heights due to content differences
- "Generate Deck" buttons not aligned horizontally
- Fit badges sometimes wrap awkwardly

**Fixes:**
- Use CSS Grid with `grid-template-rows: subgrid` or fixed minimum heights
- Move "Generate Deck" button to consistent position (bottom of card, full width)
- Ensure badges have `whitespace-nowrap` and consistent sizing
- Set `min-height` on cards to accommodate largest content
- Use flexbox with `flex-grow` for content area, fixed footer for button

---

## 9. Play Up Custom Deck Feature
**File:** `components/LenderRecommendations.tsx` or `components/LenderSelector.tsx`

**Current State:** "Generate Deck" button exists but feature isn't explained

**Improvements:**
- Add a callout/banner explaining the custom deck feature:
  - "Generate a tailored pitch deck customized for each lender's preferences"
  - Highlight: Lender-specific messaging, deal structure, founder emphasis
- Consider a "Preview" option to see deck structure before generating
- Add deck generation progress indicator

---

## 10. Additional Export Formats
**File:** `lib/pptxGenerator.ts`, `components/PowerPointExportModal.tsx`

**Current State:** Only PowerPoint (.pptx) export via pptxgenjs

**Options to Consider:**
- **Google Slides:** No direct JS library; would need to export PPTX and note "Import to Google Slides"
- **Keynote:** Can import PPTX; add note for Mac users
- **Pitch:** No public API; not feasible
- **PDF of deck:** Generate deck as PDF using pptxgenjs + pdf export

**Recommendation:** Add format selector with:
- PowerPoint (.pptx) - default
- PDF version of deck
- Note that .pptx works with Google Slides and Keynote

---

## 11. Bold Titles in Key Risks/Opportunities
**File:** `components/AnalysisReport.tsx` (lines 444-472)

**Current:** Plain text like "Client concentration - Top 10 clients represent 57.8%..."

**Fix:** Parse the text to bold the part before the dash/hyphen:
```
**Client concentration** - Top 10 clients represent 57.8%...
```

**Implementation:**
- Split each item on first ` - ` or `: `
- Render first part in `<strong>` or `font-semibold`
- Render rest in normal weight

---

## 12. Remove Snapshots Feature
**Files to modify:**
- `components/SnapshotManager.tsx` - DELETE entire file
- `components/AnalysisReport.tsx` - Remove SnapshotManager import and usage
- `lib/types.ts` - Remove `AnalysisSnapshot` interface and `snapshots` field from `SavedAnalysis`

---

## 13. Analysis Persistence & Dashboard
**Files:** `lib/analysisStorage.ts`, `app/dashboard/page.tsx`, `app/page.tsx`

**Current State:**
- Analyses ARE saved to localStorage automatically
- Dashboard DOES list saved analyses
- Can click to load previous analyses

**Verify/Improve:**
- Confirm re-analysis with new documents preserves existing assumptions
- Add "Last analyzed" timestamp on dashboard cards
- Show document count and key metrics on dashboard cards
- Ensure smooth flow: Dashboard → Click company → Full report loads
- Add "Re-analyze" action that preserves assumptions but refreshes AI analysis

---

## 14. Public Company / Stock Analysis Mode
**New Feature - Major Addition**

### Why This Matters
Public companies have vastly more data available. The tool should adapt its analysis approach when analyzing a publicly traded company vs. a private acquisition target.

### Detection
- Add optional "Ticker Symbol" field on input screen
- Auto-detect: If company name matches a public company, prompt user to confirm
- Toggle: "This is a public company" checkbox

### Data Sources to Integrate

**US Public Companies (SEC):**
1. **SEC EDGAR** (free, official)
   - 10-K (annual reports) - last 5 years
   - 10-Q (quarterly) - last 8 quarters
   - 8-K (material events) - last 2 years
   - DEF 14A (proxy/executive comp)

**Canadian Public Companies (SEDAR+):**
2. **SEDAR+** (sedarplus.ca - free, official)
   - Annual Information Form (AIF) - equivalent to 10-K
   - Annual Financial Statements
   - Interim Financial Statements (quarterly)
   - Management's Discussion & Analysis (MD&A)
   - Material Change Reports - equivalent to 8-K
   - Management Information Circular (proxy)
   - Note: SEDAR+ API available, or scrape filings list

3. **Market Data**
   - Current stock price, market cap, enterprise value
   - 52-week high/low, average volume
   - Historical price chart (5 year)
   - Support both NYSE/NASDAQ (US) and TSX/TSXV (Canada)

4. **Financial APIs**
   - **Financial Modeling Prep** (selected) - Good free tier, clean API
   - Provides: Stock price, market cap, EV, ratios, historical prices
   - Supports both US and Canadian exchanges (TSX tickers)
   - API Key required (free tier: 250 requests/day)

### Detection: US vs Canadian
- If ticker ends in `.TO` or `.V` → Canadian (TSX/TSXV)
- If ticker on NYSE/NASDAQ → US (SEC)
- Auto-detect from company location if no ticker provided
- User can override with exchange selector

### Adapted Analysis for Public Companies

**What Changes:**
| Private Company | Public Company |
|-----------------|----------------|
| LOI recommendations | Entry price analysis |
| Transaction multiples | Trading multiples + premium analysis |
| Debt capacity for acquisition | Balance sheet analysis |
| Lender recommendations | Not applicable (remove section) |
| Bank deck export | Not applicable (remove section) |

**New Sections for Public:**
- **Valuation vs. Market**: Is it cheap/fair/expensive? Margin of safety
- **Institutional Ownership**: Who owns it? Recent changes
- **Insider Activity**: Are insiders buying/selling?
- **Catalyst Analysis**: What could move the stock?
- **Historical Performance**: Stock chart + key events overlay
- **Earnings History**: Beat/miss track record
- **Analyst Estimates**: If available, consensus targets

**What Stays the Same:**
- Company overview and business description
- Leadership team analysis (pull from proxy filings)
- Key risks and opportunities
- Financial summary (but from 10-K, much more detailed)
- Competitive positioning

### UI Adaptations
- Show ticker symbol prominently in header
- Live stock price badge (or last close)
- Replace "Purchase Price" with "Market Cap" and "Current Price"
- Remove lender/bank sections entirely for public companies
- Add "Investment Thesis" section (ties into Deal Memo)

### Implementation Approach
1. Create `/api/sec-filings` route to fetch EDGAR data
2. Create `PublicCompanyReport.tsx` component (variant of AnalysisReport)
3. Modify analysis prompt to handle public company context
4. Add public company fields to `AnalysisResult` type
5. Store `isPublic: boolean` and `ticker: string` in saved analysis

---

## 15. Deal Memo Feature
**New Feature - Major Addition**

### Purpose
Enable users to document their investment thesis in a structured way. This is the "why" behind pursuing or passing on a deal - critical for internal records, LP reporting, and learning from past decisions.

### Deal Memo Structure

**Section 1: Executive Summary**
- One-paragraph thesis statement
- Decision: Pass / Watch / Pursue / Invested
- Date and author

**Section 2: The Opportunity**
- Why is this interesting?
- What's the angle/edge?
- Why now?

**Section 3: Business Quality**
- What do they do well?
- Moat/competitive advantage
- Management assessment

**Section 4: Key Assumptions**
- What has to be true for this to work?
- Growth assumptions
- Margin assumptions
- Multiple assumptions

**Section 5: Risks & Mitigants**
- Top 3-5 risks
- How each could be mitigated
- What would make us walk away?

**Section 6: Valuation**
- Why the price makes sense (or doesn't)
- Upside/downside scenarios
- Margin of safety

**Section 7: Path to Exit** (for private) / **Catalyst** (for public)
- How do we make money?
- Timeline expectations
- Potential buyers / price targets

**Section 8: Decision & Next Steps**
- Final recommendation
- Key diligence items remaining
- Action items with owners

### UX: Step-by-Step Wizard

**Flow:**
1. User clicks "Write Deal Memo" button on analysis page
2. Wizard opens as modal or slide-over panel
3. Walk through each section with guiding questions
4. Each section has:
   - Prompt/question to answer
   - Pre-populated suggestions from analysis (AI-generated)
   - Text area for user's own thoughts
   - **Voice recording button** → transcribed to text via Web Speech API
     - Record → Stop → Auto-transcribe → Edit if needed
     - Great for capturing quick thoughts without typing
5. Progress indicator shows completion
6. Can save draft and return later
7. Final review screen before saving
8. Export options: PDF, copy to clipboard, save to analysis

### AI Assistance
- Pre-fill suggestions based on analysis data
- "Help me write this" button generates draft for each section
- User can edit/override any AI suggestions
- Tone: Professional but not stuffy, clear reasoning

### Data Model
```typescript
interface DealMemo {
  id: string;
  analysisId: string;  // Links to SavedAnalysis
  createdAt: number;
  updatedAt: number;
  author?: string;
  decision: 'pass' | 'watch' | 'pursue' | 'invested';
  sections: {
    executiveSummary: string;
    opportunity: string;
    businessQuality: string;
    keyAssumptions: string;
    risksAndMitigants: string;
    valuation: string;
    exitPath: string;
    decisionAndNextSteps: string;
  };
  isDraft: boolean;
}
```

### Storage
- Store in localStorage alongside analysis: `dealhunter:memo:{analysisId}`
- One memo per analysis (can overwrite/update)
- Include in export/backup functionality

### UI Components
- `DealMemoWizard.tsx` - Step-by-step wizard modal
- `DealMemoView.tsx` - Read-only view of saved memo
- `DealMemoExport.tsx` - PDF/print formatting
- Button in AnalysisReport header: "Deal Memo" (shows status: Draft / Complete / Not Started)

### Integration Points
- Link from analysis page header
- Show memo status on dashboard cards
- Filter dashboard by decision (Pass/Watch/Pursue/Invested)
- Include memo in PDF export option

---

## 16. Leadership Background Investigation (Kroll-Style Deep Dive)
**New Feature - Major Addition**

### Purpose
Perform automated due diligence on each member of the leadership team similar to what professional investigation firms (Kroll, Business Intelligence Advisors, Nardello) would do - but using publicly available data sources.

### What Professional Investigators Check

**Employment & Corporate History**
- Verify all stated positions and dates
- Identify gaps or inconsistencies in career timeline
- Find ALL companies where person served as officer/director
- Check status of those companies (active, dissolved, bankrupt, acquired)
- Flag departures that coincided with company troubles
- Look for patterns (multiple failed companies, short tenures)

**Legal & Court Records**
- Civil litigation (as plaintiff AND defendant)
- Criminal records (where publicly available)
- Personal bankruptcies
- Tax liens and judgments
- SEC enforcement actions
- FINRA disciplinary actions (financial industry)
- State regulatory sanctions
- Professional license revocations

**Corporate Red Flags**
- Companies they led that went bankrupt
- Fraud or scandal at companies during their tenure
- Regulatory actions against companies they were at
- Shareholder lawsuits naming them
- Whistleblower allegations

**Adverse Media**
- News articles mentioning scandals, fraud, misconduct
- Industry controversy or criticism
- Negative coverage timing relative to company departures

### Data Sources to Integrate

**Free/Public APIs:**
| Source | What It Provides |
|--------|------------------|
| SEC EDGAR | Officer/director positions at public companies, any enforcement actions |
| FINRA BrokerCheck | Disciplinary history for anyone in financial services |
| OpenCorporates | Global company officer/director records |
| OFAC Sanctions List | SDN list check (sanctions/watchlists) |
| State Corp Registries | Company filings, officer records |
| Google News API | Adverse media search |
| PACER | Federal court records (has per-document fees) |

**Web Research (via Firecrawl):**
- Deep search: `"{Person Name}" AND (lawsuit OR fraud OR scandal OR investigation OR charged OR sued)`
- Company-specific: `"{Person Name}" "{Company Name}" (resigned OR terminated OR departed)`
- LinkedIn profile scraping for employment history verification

### Execution Timing
**Automatic with analysis** - Background checks run automatically as part of the analysis flow:
1. Research phase identifies leadership team
2. Background investigation runs in parallel with financial analysis
3. Results appear in Leadership section when analysis completes
4. Progress indicator: "Checking backgrounds..." during analysis

### Investigation Flow

```
For each leadership team member:
1. Extract full name, current title, stated work history
2. Run parallel searches:
   ├── SEC EDGAR: Find all filings mentioning them
   ├── FINRA BrokerCheck: Check registration/disciplinary history
   ├── OpenCorporates: Find all companies they're linked to
   ├── OFAC: Sanctions list check
   ├── News Search: Adverse media with name + variations
   └── Web Deep Dive: Scandal/lawsuit searches
3. Cross-reference company list with:
   ├── Bankruptcy filings
   ├── SEC enforcement actions against those companies
   └── News about those companies during their tenure
4. Compile findings into risk report
5. Assign risk score: Clean / Minor Flags / Concerns / Red Flags
```

### Risk Scoring Model

**Green (Clean):** No adverse findings, consistent employment history, companies in good standing

**Yellow (Minor Flags):**
- Named in civil litigation as co-defendant (routine business disputes)
- Company they worked at had issues, but after they left
- Minor inconsistencies in stated history

**Orange (Concerns):**
- Multiple companies they led had problems
- Named personally in regulatory inquiry
- Significant unexplained gaps in employment
- Pattern of short tenures with abrupt departures

**Red (Serious Red Flags):**
- SEC or regulatory enforcement action against them personally
- Criminal charges or convictions
- Personal bankruptcy while in executive role
- Fraud allegations at company during their tenure
- OFAC sanctions list match
- Pattern of companies failing under their leadership

### UI Design

**Per-Leader Section:**
```
┌─────────────────────────────────────────────────────────┐
│ John Smith, CEO                           [🟡 Minor Flags] │
│ ─────────────────────────────────────────────────────── │
│ ▸ Background Check Results (click to expand)            │
│                                                         │
│   Employment Verified: 4/5 positions confirmed          │
│   Companies Associated: 7 total                         │
│   Legal/Court Records: 2 civil cases (defendant)        │
│   Regulatory: Clean                                     │
│   Adverse Media: 3 articles flagged                     │
│                                                         │
│   ⚠️ Findings:                                          │
│   • Civil lawsuit: Smith v. XYZ Corp (2019) - contract  │
│     dispute, settled. [View source]                     │
│   • Previous company TechCo filed Ch.11 in 2018,        │
│     6 months after his departure. [View details]        │
│                                                         │
│   [View Full Report]  [Export PDF]                      │
└─────────────────────────────────────────────────────────┘
```

**Summary Section in Analysis:**
```
Leadership Risk Summary
━━━━━━━━━━━━━━━━━━━━━━
🟢 Jane Doe, CFO - Clean
🟡 John Smith, CEO - Minor Flags (2 items)
🟢 Bob Johnson, CTO - Clean
🔴 Sarah Williams, COO - Red Flags (requires attention)

[View Detailed Background Reports]
```

### Implementation Approach

**New Files:**
| File | Purpose |
|------|---------|
| `lib/backgroundCheck.ts` | Core investigation logic |
| `lib/secEdgarPerson.ts` | SEC person search utilities |
| `lib/finraBrokerCheck.ts` | FINRA API integration |
| `lib/openCorporates.ts` | Company officer search |
| `lib/adverseMedia.ts` | News/media risk search |
| `lib/ofacCheck.ts` | Sanctions list checking |
| `components/BackgroundCheckResults.tsx` | Results display UI |
| `components/LeadershipRiskSummary.tsx` | Summary badges |
| `app/api/background-check/route.ts` | API endpoint |

**API Integration:**
```typescript
interface BackgroundCheckResult {
  personName: string;
  riskScore: 'clean' | 'minor' | 'concerns' | 'red_flags';
  employmentVerification: {
    stated: EmploymentRecord[];
    found: EmploymentRecord[];
    discrepancies: string[];
  };
  corporateAssociations: {
    company: string;
    role: string;
    dates: string;
    companyStatus: 'active' | 'dissolved' | 'bankrupt' | 'acquired';
    issuesDuringTenure: string[];
  }[];
  legalRecords: {
    type: 'civil' | 'criminal' | 'bankruptcy' | 'regulatory';
    description: string;
    date: string;
    status: string;
    sourceUrl: string;
  }[];
  adverseMedia: {
    headline: string;
    source: string;
    date: string;
    summary: string;
    url: string;
    relevance: 'high' | 'medium' | 'low';
  }[];
  sanctionsCheck: {
    checked: boolean;
    match: boolean;
    details?: string;
  };
}
```

### Cost Considerations
- Most sources are free (SEC, FINRA, OFAC, news search)
- OpenCorporates: Free tier available, paid for bulk
- PACER: $0.10 per page for court documents
- Consider: Make detailed court record lookup optional/on-demand

### Disclaimer
Display prominently:
> "This automated background check uses publicly available sources and is not a substitute for professional due diligence. For high-stakes transactions, we recommend engaging a professional investigation firm."

---

## Implementation Priority

### Phase 1 - Quick Wins (UI Polish)
1. Bold titles in Risks/Opportunities (#11)
2. Remove top PPTX button (#2)
3. Fix lender grid layout (#8)
4. Improve scenario names in projections table (#7 - naming only)

### Phase 2 - Feature Cleanup
5. Remove Tags feature (#3)
6. Remove Snapshots feature (#12)

### Phase 3 - Design Improvements
7. Improve document upload section (#4)
8. Fix Financial Summary parsing (#6)
9. Play up custom deck feature (#9)

### Phase 4 - Complex Improvements
10. PDF export improvements (#1)
11. Leadership photos reliability (#5)
12. Projections table UX improvements (#7 - full)
13. Additional export formats (#10)
14. Dashboard/persistence review (#13)

### Phase 5 - Major New Features
15. **Deal Memo Feature (#15)** - Step-by-step thesis documentation wizard
16. **Public Company Analysis (#14)** - SEC filings integration, adapted analysis
17. **Leadership Background Investigation (#16)** - Kroll-style deep dive with legal/regulatory checks

---

## Key Files Summary

### Existing Files to Modify
| File | Changes |
|------|---------|
| `components/AnalysisReport.tsx` | Remove PPTX button, Tags, Snapshots; Bold risk/opp titles; Add Deal Memo button |
| `components/FiveYearProjections.tsx` | Rename scenarios, add clarity |
| `components/LenderRecommendations.tsx` | Fix grid layout, add deck callout |
| `components/DocumentUploadPrompt.tsx` | Simplify design |
| `components/FinancialSummary.tsx` | Fix parsing issues |
| `components/PDFExport.tsx` | Improve print styling |
| `components/LeadershipSection.tsx` | Verified photos only |
| `app/page.tsx` | Add ticker symbol input, public/private toggle |
| `app/dashboard/page.tsx` | Add decision filter, memo status |
| `lib/types.ts` | Remove tags/snapshots; Add public company + deal memo types |
| `lib/analysisStorage.ts` | Add memo storage methods |

### Files to Delete
| File | Reason |
|------|--------|
| `components/TagEditor.tsx` | Feature removed |
| `components/SnapshotManager.tsx` | Feature removed |

### New Files to Create
| File | Purpose |
|------|---------|
| **Deal Memo** | |
| `components/DealMemoWizard.tsx` | Step-by-step memo creation wizard |
| `components/DealMemoView.tsx` | Read-only memo display |
| `lib/dealMemoStorage.ts` | Deal memo persistence |
| **Public Company** | |
| `components/PublicCompanyReport.tsx` | Adapted report for public companies |
| `components/StockChart.tsx` | Historical price chart |
| `components/InstitutionalOwnership.tsx` | Ownership breakdown display |
| `app/api/sec-filings/route.ts` | Fetch SEC EDGAR data |
| `app/api/market-data/route.ts` | Fetch stock price/market data |
| `lib/secEdgar.ts` | SEC EDGAR parsing utilities |
| **Background Investigation** | |
| `lib/backgroundCheck.ts` | Core investigation orchestration |
| `lib/secEdgarPerson.ts` | SEC person/officer search |
| `lib/finraBrokerCheck.ts` | FINRA disciplinary check |
| `lib/openCorporates.ts` | Global company officer search |
| `lib/adverseMedia.ts` | News/scandal search |
| `lib/ofacCheck.ts` | Sanctions list verification |
| `components/BackgroundCheckResults.tsx` | Per-person results display |
| `components/LeadershipRiskSummary.tsx` | Risk score badges |
| `app/api/background-check/route.ts` | Background check API endpoint |
