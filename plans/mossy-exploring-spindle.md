# Dealhunter - Enhancement Plan

## Current State
The app is working with:
- Simple 2-step flow: Enter company name/location → Upload docs → Auto-analyze
- PDF, Excel, Word, CSV parsing
- Web research + document extraction
- Claude-powered valuation + LOI recommendations
- PDF export

## Enhancements Needed

### 1. Multi-File Upload UX Improvements
**File:** `app/page.tsx`

Current state: Already accepts multiple files, but UX could be clearer.

Changes:
- Add visual indication that multiple files are supported
- Show drag-and-drop zone more prominently
- Display file count and types clearly

### 2. Add File Type Examples with Importance Ranking
**File:** `app/page.tsx`

Add a section showing recommended document types:

**Most Important (High Impact):**
1. Financial statements (P&L, Balance Sheet, Cash Flow)
2. CIM (Confidential Information Memorandum)
3. Tax returns (last 3 years)

**Very Helpful:**
4. Customer contracts / revenue breakdown
5. Employee roster / org chart
6. Asset list / equipment schedule

**Good to Have:**
7. Marketing materials / pitch decks
8. Legal documents (leases, IP filings)
9. Industry reports / market analysis

### 3. Improved Loading Spinner
**File:** `app/page.tsx`

Current: Simple "Analyzing..." message

Enhance to show:
- Step-by-step progress: "Researching company..." → "Parsing documents..." → "Generating analysis..."
- Animated progress indicator
- Estimated time or fun facts while waiting

### 4. Deep Company & Industry Research
**File:** `app/api/research/route.ts`

Enhance research to gather comprehensive information:
- Company background, history, founding story
- Leadership team and key executives
- Products/services deep dive
- Customer base and target market
- Revenue model and pricing
- Funding history (if applicable)
- Recent news and press releases
- Industry trends and market dynamics
- Competitor analysis
- Regulatory environment
- Growth opportunities and threats

Use multiple targeted searches and Firecrawl for deeper scraping when needed.

### 5. Use Opus 4.5 with High Token Limit
**File:** `app/api/analyze/route.ts`

Changes:
- Switch model from `claude-sonnet-4-20250514` to `claude-opus-4-5-20250514`
- Increase `max_tokens` from 8192 to 32000 (near maximum)

### 5. Create GitHub Repo
**Repo name:** `Dealhunter`
**Steps:**
- Rename project folder to `dealhunter`
- Initialize git if needed
- Create GitHub repo via `gh repo create`
- Push code

## Files to Modify

1. `~/company-analyzer/app/page.tsx` - Upload UI + loading spinner
2. Rename folder `~/company-analyzer` → `~/dealhunter`

## Implementation Order

1. Update upload section with file type examples
2. Enhance loading spinner with progress steps
3. Rename project and create GitHub repo
