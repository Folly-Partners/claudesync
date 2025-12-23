# Deep Personality: Corporate Screening Product Design

## Executive Summary

Create **"Deep Insight for Employers"** - a B2B pre-employment screening product positioned around **toxic hire prevention**. Lead with: *"Don't let your 10th hire be a psychopath."*

**The Secret Sauce**: The hidden Dark Triad detection (18 SD3 items) already in the codebase is the key differentiator. Most hiring tools don't explicitly catch psychopaths, narcissists, or Machiavellians - this one will.

---

## Key Decisions (Confirmed)

| Decision | Choice |
|----------|--------|
| **Positioning** | Toxic hire prevention (provocative, differentiating) |
| **Candidate View** | Sanitized strengths only (positive spin, no risk data) |
| **Architecture** | Shared codebase (same repo, separate DB schema) |
| **Target Market** | Startups/SMBs (self-serve, fast sales cycle) |
| **Branding** | Dual-brand: boring/generic for candidates, bold for employers |

---

## Dual-Brand Strategy (Critical)

### The Problem
If candidates see "Deep Personality" branding, they might:
- Google it and discover it detects Dark Triad traits
- Research how to game the assessment
- Feel uncomfortable and withdraw from the process
- Tell other candidates what to expect

### The Solution: Two Separate Brands

**Employer-Facing Brand** (what you market):
- Domain: `deepinsight.io` or `hiredeep.com`
- Bold positioning: "Catch narcissists before you hire them"
- Dashboard lives here
- All marketing, pricing, sales material

**Candidate-Facing Brand** (what candidates see):
- Domain: `workstyleprofile.com` or `talentprofile.io`
- Ultra-generic, boring corporate branding
- Looks like any standard HR assessment tool
- No connection to Deep Personality visible
- Assessment instructions: "Complete your Work Style Profile"

### Candidate Experience (Intentionally Boring)
```
┌─────────────────────────────────────────────────────────────┐
│  [GENERIC LOGO]  Work Style Profile                         │
│  ─────────────────────────────────────────────────────────  │
│                                                              │
│  Hi Jane,                                                    │
│                                                              │
│  Acme Corp has requested you complete a standard work        │
│  style assessment as part of their hiring process.           │
│                                                              │
│  This assessment helps match candidates to roles where       │
│  they'll be most successful.                                 │
│                                                              │
│  • Time: 25-30 minutes                                       │
│  • No preparation needed                                     │
│  • No right or wrong answers                                 │
│                                                              │
│                    [Begin Assessment]                        │
└─────────────────────────────────────────────────────────────┘
```

### Domain & Infrastructure Setup
```
deepinsight.io (employer-facing)
├── Marketing site
├── Employer signup/login
├── Dashboard
├── Billing
└── Links to candidate assessments via...

workstyleprofile.com (candidate-facing)
├── Assessment taking interface
├── Generic branding, no external links
├── Consent flow
├── Results page (strengths only)
└── No mention of Deep Personality anywhere
```

### Technical Implementation
- Same Next.js app deployed to two domains
- Environment variable controls branding: `BRAND_MODE=employer|candidate`
- Different layouts, logos, colors per mode
- Candidate domain has minimal chrome, no footer links
- Employer domain has full nav, marketing content

### Candidate Email Example
```
From: noreply@workstyleprofile.com
Subject: Complete your Work Style Assessment - Acme Corp

Hi Jane,

As part of your application to Acme Corp, please complete
a brief work style assessment.

[Begin Assessment]

This helps ensure a great fit between candidates and roles.
Takes about 25 minutes.

---
Work Style Profile
Standard candidate assessments
```

**Key detail**: Even the email doesn't mention employer psychology, screening, personality testing, or anything that would trigger research. Just "work style."

### What Makes It "Boring Corporate" (Design Details)

**Candidate Brand (workstyleprofile.com)**:
- Colors: Safe blues and grays (think LinkedIn, Workday)
- Logo: Generic abstract shape (like a checkmark or person icon)
- Typography: Safe sans-serif (Inter, Open Sans)
- Language: "Work style," "profile," "assessment" - never "personality" or "psychological"
- Footer: Minimal - just copyright, privacy policy, no social links
- No testimonials, no case studies, no marketing copy
- Feels like: HireRight, Checkr, Sterling - boring compliance tools

**Employer Brand (deepinsight.io)**:
- Colors: Bold, dark (could go edgy with black/red)
- Logo: Sharp, distinctive
- Copy: Provocative ("The assessment that catches what interviews miss")
- Case studies: "How Company X avoided hiring a narcissist VP"
- Testimonials: Founders talking about bad hires they almost made
- Feels like: Clearbit, RevenueCat, modern B2B SaaS

**The Firewall Between Brands**:
- No shared cookies or local storage
- Different Vercel projects (or same project, different deployments)
- Candidate domain has no links to employer domain
- If candidate inspects page source: generic company name only
- robots.txt blocks Google from indexing candidate domain (optional)

---

## Part 1: Legal Framework (Critical)

### What's Legal Pre-Offer
- Personality assessments (Big Five) ✓
- Behavioral/situational judgment tests ✓
- Integrity tests ✓
- Values assessments ✓
- Work motivation assessments ✓

### What's ILLEGAL Pre-Offer (ADA Violations)
- Mental health screening (GAD-7, PHQ-9, PCL-5) ✗
- Disability-related inquiries ✗
- Medical history (ACE, ADHD screening) ✗

### Key Reframing Strategy
Never call it "mental health screening" or "Dark Triad" - instead:

| Original | Corporate Reframe |
|----------|-------------------|
| Dark Triad | "Interpersonal Risk Index" |
| Machiavellianism | "Strategic Self-Interest" |
| Narcissism | "Self-Promotion Tendency" |
| Psychopathy | "Empathy Responsiveness" |
| Neuroticism | "Stress Response Style" |
| Mental health flags | "Behavioral risk indicators" |

---

## Part 2: Assessment Battery

### KEEP (Pre-Offer Legal)
| Assessment | Reframe As | Employer Value |
|------------|-----------|----------------|
| IPIP-50 (Big Five) | "Work Style Inventory" | Job performance prediction |
| Dark Triad (SD3) - Hidden | "Interpersonal Risk Index" | Toxic employee detection |
| Personality Styles (A/B/C) | "Behavioral Patterns" | Flag concerning patterns |
| O*NET Mini-IP | "Career Interest Profile" | Role fit |
| PVQ-21 | "Work Values Assessment" | Culture fit |
| WEIMS | "Motivation Profile" | Engagement prediction |
| DERS-16 | "Emotional Self-Management" | Self-regulation |
| DTS | "Stress Management Style" | Resilience |
| RSQ | "Feedback Reception Style" | Handles criticism |

### REMOVE (Pre-Offer Illegal)
- GAD-7 (anxiety diagnosis)
- PHQ-9 (depression diagnosis)
- PCL-5 (PTSD diagnosis)
- ACE (trauma history)
- ASRS-18 (ADHD diagnosis)
- CSI-16 (relationship satisfaction - irrelevant)
- ECR-S (attachment - risky)

### ADD (New for Corporate)
| Assessment | Purpose | Items |
|------------|---------|-------|
| Situational Judgment Test | Workplace behavior prediction | 15 |
| Integrity Scale | Counterproductive work behavior | 15 |
| Accountability Index | Ownership vs blame-shifting | 8 |
| Collaboration Style | Team player assessment | 10 |

**Total Time**: ~25-30 minutes (vs 45-50 for B2C)

---

## Part 3: The Employer Report

### Output Structure
```
┌─────────────────────────────────────────────────────────────┐
│  CANDIDATE ASSESSMENT REPORT                                │
│  [Name] | [Role] | [Company]                                │
├─────────────────────────────────────────────────────────────┤
│  OVERALL FIT: 78/100        RISK LEVEL: LOW                │
│  Recommendation: ● Advance to Interview                     │
└─────────────────────────────────────────────────────────────┘

1. JOB FIT ANALYSIS
   - Work Style Match (Big Five alignment)
   - Values Alignment Score
   - Career Interest Match

2. BEHAVIORAL INSIGHTS
   - Key Strengths (3-5 bullets)
   - Development Areas (2-3 bullets)

3. RISK INDICATORS (Traffic Light)
   - Interpersonal Risk Index: ● LOW/MODERATE/ELEVATED/HIGH
   - Integrity Indicators: ●
   - Anti-Gaming Flags: ●

4. INTERVIEW FOCUS AREAS
   - 3-5 specific questions to probe concerns

5. AI SUMMARY (Claude-generated)
   - Narrative synthesis
   - Clear recommendation
```

### Risk Thresholds
```
Interpersonal Risk Index (Dark Triad composite):
  LOW:      All traits <60th percentile
  MODERATE: Any trait 60-75th percentile
  ELEVATED: Any trait 75-90th percentile
  HIGH:     Any trait >90th percentile → DO NOT HIRE flag
```

---

## Part 4: Architecture (Shared Codebase, Dual Domain)

### Same Repo, Two Deployments
```
~/Deep-Personality/
├── app/                     # Existing B2C app (deepersonality.com)
├── app/employers/           # NEW: Employer dashboard (deepinsight.io)
├── app/assess/[token]/      # NEW: Candidate assessment (workstyleprofile.com)
├── api/                     # Existing B2C API
├── api/corporate/           # NEW: Corporate API routes
├── services/                # SHARED: Assessment logic, scoring
├── services/corporate/      # NEW: Corporate-specific services
├── components/branding/     # NEW: Brand-aware components
├── supabase/migrations/     # Includes new corporate.* schema
└── types/corporate.ts       # NEW: Corporate-specific types
```

### Three-Domain Strategy
| Domain | Purpose | Branding |
|--------|---------|----------|
| `deeppersonality.com` | B2C self-assessment | Current Deep Personality brand |
| `deepinsight.io` | Employer dashboard, marketing | Bold, edgy (sells the toxic-detection angle) |
| `workstyleprofile.com` | Candidate assessments | Ultra-boring, generic corporate |

### Separation Strategy
| Layer | Approach |
|-------|----------|
| **Database** | Separate `corporate.*` schema with RLS isolation |
| **Domains** | Vercel multi-domain deployment, env-based branding |
| **Auth** | Same Supabase auth, organization-based access control |
| **Billing** | Separate Stripe products (corporate vs consumer) |
| **Data firewall** | B2C profiles NEVER visible to corporate clients |
| **Brand isolation** | Zero cross-linking between candidate + employer domains |

### Key Database Tables
```sql
corporate.organizations (employers - Stripe customer link)
corporate.requisitions (job openings)
corporate.candidates (applicants - invited via token)
corporate.candidate_assessments (raw + derived scores)
corporate.employer_reports (what HR sees)
corporate.audit_log (compliance)
```

### Shared Code (Reuse)
- Assessment definitions (`services/data.ts`) - create `CORPORATE_ASSESSMENTS` subset
- Scoring algorithms (`services/scoring.ts`) - add `calculateInterpersonalRiskIndex()`
- Anti-gaming detection (`_internal` fields)
- UI components (Wizard, progress bars) - with corporate theming

---

## Part 5: User Flows

### Employer Flow
1. HR creates requisition
2. Adds candidates (email or ATS sync)
3. Candidates receive invite
4. Complete assessment (25 min)
5. Report generated automatically
6. HR reviews in dashboard
7. Advances/rejects with interview guide

### Candidate Flow
1. Receive email invite
2. Click → Consent screen (legally required)
3. Complete assessment (~25 min)
4. **See sanitized summary**: "Your Top 5 Strengths" + "Environments Where You Thrive"
5. **Never see**: Risk indicators, employer report, fit scores
6. Optional: CTA to take full Deep Personality assessment for themselves (B2C upsell)

### ATS Integration
- Greenhouse, Lever, Workday webhooks
- Auto-create candidates when added in ATS
- Push scores back as structured scorecard
- Attach PDF report to candidate profile

---

## Part 6: Pricing Model

| Plan | Price | Volume | Features |
|------|-------|--------|----------|
| Starter | $99/mo | 25/mo | Core battery, dashboard |
| Professional | $299/mo | 100/mo | + Benchmarks, ATS integration |
| Enterprise | Custom | Unlimited | + SSO, API, custom SJTs |

**Per-assessment overage**: $10-15

---

## Part 7: Ethical Considerations

### What This Product Does Well
- Catches genuinely toxic hires (Dark Triad detection)
- Uses validated psychological instruments
- Provides actionable interview guidance
- Reduces hiring bias (standardized assessment)

### Potential Concerns
1. **False positives**: Some high-scorers on Dark Triad are fine
   - Mitigation: Use as "flag for interview follow-up" not auto-reject

2. **Gaming**: Candidates could fake good
   - Mitigation: Anti-gaming detection already built in

3. **Privacy**: Sensitive data being shared with employers
   - Mitigation: Candidates see consent, employers see summary not raw scores

4. **Discrimination risk**: Could be misused
   - Mitigation: No protected class data collected, adverse impact monitoring

---

## Part 8: Implementation Phases

### Phase 1: Foundation (4 weeks)
- Create `corporate` database schema
- Build core API routes
- Adapt assessment for corporate flow
- Remove clinical assessments from battery

### Phase 2: Employer Dashboard (4 weeks)
- Build employer UI
- Create report generation pipeline
- Implement corporate AI prompts
- Build risk flagging system

### Phase 3: Candidate Experience (2 weeks)
- Corporate-branded assessment UI
- Consent flow
- Candidate results summary

### Phase 4: Integrations (4 weeks)
- ATS webhook handlers (Greenhouse first)
- Scorecard API
- PDF report generation

### Phase 5: Launch (2 weeks)
- Security audit
- Legal review
- Beta customers
- Documentation

**Total**: ~16 weeks

---

## Part 9: Critical Files to Modify

| File | Change Needed |
|------|---------------|
| `services/scoring.ts` | Add `extractInterpersonalRiskIndex()` (rebranded Dark Triad) |
| `services/data.ts` | Create `CORPORATE_ASSESSMENTS` subset |
| `services/analyze/prompts.ts` | Create `CORPORATE_SYSTEM_PROMPT` |
| `types.ts` | Add `EmployerReport`, `CorporateCandidate` interfaces |
| `supabase/migrations/` | New corporate schema migration |

---

---

## Part 10: Deep Research Agents (Background Investigation)

### The Vision

Beyond personality assessment, use AI research agents to automatically investigate:
- **Court records** (civil & criminal, federal & state, international)
- **Legal disputes** (lawsuits as plaintiff/defendant)
- **Regulatory actions** (SEC, FTC, professional board sanctions)
- **News coverage** (fraud allegations, misconduct, scandals)
- **Corporate records** (hidden company affiliations, conflicts of interest)
- **Sanctions lists** (OFAC, PEP lists, watchlists)
- **Bankruptcy filings**
- **Professional license status** (revocations, suspensions)

### Why This Matters

A candidate can score perfectly on personality assessment but still be:
- Currently facing fraud charges
- Named in multiple lawsuits for harassment
- Banned from their industry by a regulator
- Running a competing business on the side
- On a government sanctions list

The Dark Triad catches the *tendency* to be problematic. Background research catches *evidence* they already have been.

### Legal Framework (Critical: FCRA Compliance)

**If we provide reports that affect employment decisions, we may be a Consumer Reporting Agency (CRA).**

**FCRA Requirements:**
| Requirement | What It Means |
|-------------|---------------|
| Written consent | Candidate must sign separate disclosure |
| Permissible purpose | Employer must have legitimate reason |
| Adverse action notice | Must notify candidate before rejecting based on report |
| Copy of report | Candidate entitled to see what was found |
| Dispute rights | Must investigate if candidate disputes accuracy |
| Accuracy obligation | Must use reasonable procedures to ensure accuracy |

**Options:**
1. **Become a CRA** - Full compliance, can market as official background check
2. **Partner with existing CRA** - Use Checkr/Sterling API, less liability
3. **Position as "research assistance"** - Employer makes final determination, we're just aggregating public info (gray area)

**Recommendation**: Start with option 3 for MVP, then evaluate CRA registration based on demand.

### Multi-Agent Research Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    ORCHESTRATOR AGENT                           │
│  Coordinates research, manages confidence scoring, synthesizes  │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ IDENTITY      │    │ COURT RECORDS │    │ NEWS & MEDIA  │
│ VERIFICATION  │    │ AGENT         │    │ AGENT         │
│               │    │               │    │               │
│ - LinkedIn    │    │ - PACER (fed) │    │ - Tavily      │
│ - Employment  │    │ - State courts│    │ - News APIs   │
│ - Education   │    │ - Intl courts │    │ - Press search│
└───────────────┘    └───────────────┘    └───────────────┘
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ CORPORATE     │    │ REGULATORY    │    │ SANCTIONS &   │
│ RECORDS       │    │ ACTIONS       │    │ WATCHLISTS    │
│               │    │               │    │               │
│ - SEC EDGAR   │    │ - SEC enforce │    │ - OFAC        │
│ - State corps │    │ - FTC actions │    │ - World-Check │
│ - Companies   │    │ - License bds │    │ - PEP lists   │
│   House (UK)  │    │ - Bar assoc   │    │ - FBI wanted  │
└───────────────┘    └───────────────┘    └───────────────┘
                              │
                              ▼
               ┌───────────────────────────┐
               │    SYNTHESIS AGENT        │
               │                           │
               │ - Aggregate findings      │
               │ - Calculate confidence    │
               │ - Generate narrative      │
               │ - Flag for human review   │
               └───────────────────────────┘
```

### The False Positive Problem

**"John Smith" returns 10,000 court records. Which one is your candidate?**

**Identity Matching Strategy:**
1. **Required inputs**: Full name, approximate age, locations lived
2. **Helpful inputs**: Middle name, employers, schools, LinkedIn URL
3. **Cross-reference**: Match findings against known employment/education
4. **Confidence scoring**: Each finding gets 0-100% confidence it's the right person
5. **Human review threshold**: <70% confidence → flag for manual verification

```typescript
interface IdentityMatch {
  finding: string;
  confidence: number;        // 0-100
  matchingFactors: string[]; // ["Same employer", "Same city", "Age matches"]
  conflictingFactors: string[]; // ["Different middle initial"]
  requiresReview: boolean;   // true if confidence < 70%
}
```

### Data Sources by Category

**Court Records:**
| Source | Coverage | Access Method | Cost |
|--------|----------|---------------|------|
| PACER | US Federal courts | API | $0.10/page |
| CourtListener | US Federal (free mirror) | API | Free |
| State courts | Varies by state | Scraping/API | Varies |
| UK Courts | England & Wales | Gov.uk API | Free |
| EU Courts | EU-level cases | EUR-Lex | Free |

**Corporate Records:**
| Source | Coverage | Access Method |
|--------|----------|---------------|
| SEC EDGAR | US public companies | API (free) |
| OpenCorporates | 200M+ companies globally | API |
| Companies House | UK companies | API (free) |
| State SOS databases | US state corps | Scraping |

**News & Media:**
| Source | Method |
|--------|--------|
| Tavily Search | MCP integration (already have) |
| Google News API | Standard API |
| LexisNexis | Enterprise API |
| Media monitoring | Browserbase scraping |

**Sanctions & Watchlists:**
| Source | Coverage |
|--------|----------|
| OFAC SDN List | US sanctions (free, official) |
| FBI Most Wanted | Criminal fugitives (free) |
| Interpol Notices | International (limited access) |
| World-Check | Comprehensive PEP/sanctions (paid) |

### Research Process Flow

```
1. EMPLOYER INITIATES RESEARCH
   └─ Selects candidate, chooses research depth
   └─ System verifies consent is on file

2. IDENTITY ENRICHMENT
   └─ Pull candidate info from assessment
   └─ Optionally scrape LinkedIn for employment history
   └─ Build identity profile for matching

3. PARALLEL AGENT DISPATCH
   └─ All 6 agents run simultaneously
   └─ Each searches their domain
   └─ Each returns findings with confidence scores

4. IDENTITY MATCHING
   └─ Each finding checked against identity profile
   └─ Confidence score assigned
   └─ Low-confidence findings flagged

5. SYNTHESIS
   └─ AI aggregates all findings
   └─ Generates narrative summary
   └─ Assigns overall risk level
   └─ Creates interview questions based on findings

6. HUMAN REVIEW (if needed)
   └─ Low-confidence matches reviewed
   └─ Ambiguous findings clarified
   └─ Final report approved

7. REPORT DELIVERY
   └─ Employer sees findings in dashboard
   └─ Can drill into each finding
   └─ Download PDF for records

8. ADVERSE ACTION FLOW (if reject based on findings)
   └─ System generates pre-adverse action notice
   └─ Candidate gets copy of report
   └─ Waiting period before final decision
   └─ Candidate can dispute findings
```

### Risk Scoring from Research

```typescript
interface ResearchRiskScore {
  overall: 'clear' | 'low' | 'moderate' | 'elevated' | 'high';

  categories: {
    criminal: { level: string; findings: number; };
    civil: { level: string; findings: number; };
    regulatory: { level: string; findings: number; };
    financial: { level: string; findings: number; };
    reputational: { level: string; findings: number; };
  };

  criticalFindings: Finding[];  // Immediate attention
  notableFindings: Finding[];   // Worth discussing
  informationalFindings: Finding[]; // FYI only
}
```

**Scoring Logic:**
| Finding Type | Severity | Score Impact |
|--------------|----------|--------------|
| Felony conviction (recent) | Critical | → HIGH risk |
| Active lawsuit as defendant | Significant | → ELEVATED risk |
| Bankruptcy (recent) | Notable | → MODERATE risk |
| Sanctions list match | Critical | → HIGH risk |
| Regulatory censure | Significant | → ELEVATED risk |
| Negative news coverage | Variable | Depends on content |
| Civil judgment against | Significant | → ELEVATED risk |
| Professional license revoked | Critical | → HIGH risk |

### Employer Report Format (Research Section)

```
┌─────────────────────────────────────────────────────────────────┐
│  BACKGROUND RESEARCH REPORT                                     │
│  Jane Smith | Completed Dec 23, 2025                            │
├─────────────────────────────────────────────────────────────────┤
│  IDENTITY CONFIDENCE: 94%                                       │
│  OVERALL FINDING: ● ELEVATED - Review Recommended               │
└─────────────────────────────────────────────────────────────────┘

CRITICAL FINDINGS (1)
─────────────────────
⚠️  CIVIL LAWSUIT - Defendant
    Source: Superior Court of California, Los Angeles County
    Case: Smith v. TechCorp Inc. et al. (2023)
    Summary: Named as co-defendant in wrongful termination suit
             alleging discrimination. Case ongoing.
    Confidence: 91% (same employer, matching dates)
    [View Details]

NOTABLE FINDINGS (2)
────────────────────
△  CORPORATE AFFILIATION
   Source: Delaware Division of Corporations
   Finding: Listed as Director of "Stealth Ventures LLC"
            (incorporated 2024)
   Relevance: May indicate side business/potential conflict
   Confidence: 88%

△  NEWS MENTION
   Source: TechCrunch (March 2023)
   Summary: Quoted in article about startup layoffs
   Severity: Informational only
   Confidence: 95%

CLEAR CATEGORIES
────────────────
✓ Criminal Records: No findings
✓ Bankruptcy: No findings
✓ Sanctions Lists: Not found on OFAC, PEP lists
✓ Professional Licenses: Active, no disciplinary actions
✓ Regulatory Actions: No SEC/FTC enforcement

SUGGESTED INTERVIEW QUESTIONS
─────────────────────────────
Based on findings, consider asking:

1. "I see you're listed as a director of Stealth Ventures LLC.
   Can you tell me about that company and how it relates to
   your current career plans?"

2. "Can you walk me through your departure from TechCorp?
   What did you learn from that experience?"

DISCLAIMERS
───────────
• This report contains publicly available information only
• Findings should be verified before making employment decisions
• Candidate has the right to review and dispute any findings
• This is not a consumer report under FCRA [or: This IS a consumer
  report - adverse action procedures apply]
```

### Technical Implementation

**Database Schema Additions:**
```sql
-- Research requests
CREATE TABLE corporate.research_requests (
  id UUID PRIMARY KEY,
  candidate_id UUID REFERENCES corporate.candidates(id),
  org_id UUID REFERENCES corporate.organizations(id),
  scope TEXT NOT NULL, -- 'standard', 'comprehensive', 'executive'
  status TEXT DEFAULT 'pending', -- pending, in_progress, completed, failed
  identity_confidence NUMERIC(5,2),
  overall_risk TEXT,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Individual findings
CREATE TABLE corporate.research_findings (
  id UUID PRIMARY KEY,
  research_id UUID REFERENCES corporate.research_requests(id),
  agent_type TEXT NOT NULL, -- court_records, news_media, etc.
  source_name TEXT NOT NULL,
  source_url TEXT,
  source_date DATE,
  category TEXT NOT NULL, -- criminal, civil, regulatory, etc.
  severity TEXT NOT NULL, -- critical, significant, notable, informational
  confidence NUMERIC(5,2) NOT NULL,
  summary TEXT NOT NULL,
  raw_data JSONB,
  requires_review BOOLEAN DEFAULT false,
  reviewed_by UUID,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Audit trail for compliance
CREATE TABLE corporate.research_audit (
  id UUID PRIMARY KEY,
  research_id UUID,
  action TEXT NOT NULL, -- initiated, completed, viewed, disputed, etc.
  actor_id UUID,
  actor_type TEXT, -- employer, candidate, system, admin
  details JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Agent Implementation Pattern:**
```typescript
// Base agent interface
interface ResearchAgent {
  type: ResearchAgentType;
  search(request: ResearchRequest): Promise<Finding[]>;
  verifyMatch(finding: Finding, identity: IdentityProfile): Promise<number>;
}

// Example: News Agent using Tavily MCP
class NewsMediaAgent implements ResearchAgent {
  type = 'news_media' as const;

  async search(request: ResearchRequest): Promise<Finding[]> {
    const queries = this.buildQueries(request);

    // Use Tavily MCP for each query
    const results = await Promise.all(
      queries.map(q => mcp_tavily_search({ query: q, search_depth: 'advanced' }))
    );

    // AI extracts relevant findings from results
    return this.extractFindings(results, request);
  }

  private buildQueries(request: ResearchRequest): string[] {
    const { fullName, employers } = request;
    return [
      `"${fullName}" lawsuit OR sued OR charged`,
      `"${fullName}" fraud OR investigation OR misconduct`,
      `"${fullName}" ${employers[0]} fired OR terminated OR resigned`,
      // Add more targeted queries
    ];
  }
}

// Court Records Agent using Browserbase for scraping
class CourtRecordsAgent implements ResearchAgent {
  type = 'court_records' as const;

  async search(request: ResearchRequest): Promise<Finding[]> {
    const findings: Finding[] = [];

    // Federal courts via PACER/CourtListener API
    findings.push(...await this.searchFederalCourts(request));

    // State courts via Browserbase scraping
    for (const state of request.locations) {
      findings.push(...await this.searchStateCourt(state, request));
    }

    return findings;
  }

  private async searchStateCourt(state: string, request: ResearchRequest) {
    // Use Browserbase MCP to navigate state court site
    await mcp_browserbase_navigate({ url: STATE_COURT_URLS[state] });
    await mcp_browserbase_act({ action: `Type "${request.fullName}" into search` });
    await mcp_browserbase_act({ action: 'Click search button' });

    // Extract results
    const results = await mcp_browserbase_extract({
      instruction: 'Extract all case names, numbers, dates, and party names'
    });

    return this.parseCourtResults(results);
  }
}
```

### Pricing Model (Updated)

| Tier | Assessment | + Background Research | Bundle Price |
|------|------------|----------------------|--------------|
| Basic | $49 | N/A | $49 |
| Standard | $49 | + $79 | $99 |
| Comprehensive | $49 | + $149 (deep research) | $179 |
| Executive | $49 | + $299 (intl + manual review) | $329 |

**Research Depth Levels:**
- **Standard**: US courts, news, basic corporate records
- **Comprehensive**: + International courts, full corporate network, sanctions
- **Executive**: + Manual analyst review, additional verification, comprehensive narrative

### MVP vs Full Implementation

**MVP (Phase 1):**
- News & media search (Tavily - already integrated)
- OFAC sanctions check (free API)
- Basic corporate records (OpenCorporates)
- AI synthesis of findings
- Simple confidence scoring

**Phase 2:**
- Federal court records (PACER integration)
- State court scraping (top 10 states)
- Professional license checks
- Enhanced identity matching

**Phase 3:**
- International court records
- Full sanctions screening (World-Check or similar)
- Human review workflow
- FCRA compliance module (if pursuing CRA route)

---

## Part 11: Remaining Decisions (For Later)

1. **First ATS integration**: Greenhouse? Lever? Or generic webhook MVP?
2. **Launch approach**: Private beta with 2-3 design partners? Or PLG launch?
3. **Pricing**: Start with per-assessment ($49?) or monthly flat rate?
4. **Legal review timing**: Build MVP first, then legal review before launch?
5. **FCRA strategy**: Become CRA, partner with CRA, or stay informal?
6. **Court record depth**: API-only or add scraping for state courts?

---

## Recommendation

**Build this in the same repo** as a distinct product surface. The Dark Triad detection is genuinely unique and not available in competitors.

### Go-to-Market Strategy (Startups/SMBs)

**Positioning**: *"Don't let your 10th hire be the one who destroys your culture."*

**Key Messages**:
- "We catch the manipulators, narcissists, and psychopaths that charm their way through interviews"
- "30 minutes. Zero toxic hires."
- "The assessment that looks for what interviews miss"

**PLG Motion**:
1. Founder signs up, invites first candidate free
2. See the "Interpersonal Risk Index" in action
3. Convert to paid ($49/assessment or $99/mo for 25)
4. Word of mouth in founder communities

### Success Factors

1. **Provocative positioning** - Lean into "catch psychopaths" angle
2. **Self-serve onboarding** - No sales call needed for startups
3. **Fast assessment** - 25 min max (founders won't wait)
4. **Candidate-friendly** - They get strengths, everyone wins
5. **Legal compliance** - No clinical instruments = no ADA issues
6. **Clear ROI** - One bad hire at a startup costs 6-12 months

### MVP Scope (Phase 1)
Build the minimum to validate:
- Domain setup: `deepinsight.io` (employer) + `workstyleprofile.com` (candidate)
- Brand-aware components (boring candidate UI, bold employer UI)
- Employer signup + dashboard on deepinsight.io
- Candidate invite → assessment on workstyleprofile.com → report
- Dark Triad → Interpersonal Risk Index scoring
- AI report generation (corporate prompt)
- Stripe billing (per-assessment)
- Candidate results page (generic strengths only, no Deep Personality branding)
- **Basic research agents**: News search (Tavily), OFAC sanctions check, corporate records
- Research findings with confidence scoring
- Combined personality + research report

Skip for MVP:
- ATS integrations (manual invites first)
- SSO (email + Google auth is fine)
- Custom benchmarks (standard norms)
- Post-offer clinical module
- Court record scraping (Phase 2)
- International databases (Phase 2)
- Human review workflow (Phase 2)
- FCRA compliance module (evaluate after launch)
- deeppersonality.com changes (leave B2C untouched)
