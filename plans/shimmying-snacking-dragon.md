# Dealhunter Enhancement Plan - Phase 2

## Summary
Add advanced financial modeling features: debt capacity analysis, cash-on-cash returns, 5-year projections, PowerPoint export, editable assumptions, and typography improvements.

---

## New Features Overview

### User Requests:
1. **Debt Capacity Analysis** - Estimate how much debt can be added, recommend structures
2. **Cash-on-Cash Return Analysis** - Show returns with/without debt in different scenarios
3. **PowerPoint Generation** - Create bank presentation slide decks
4. **5-Year Projection Table** - Revenue/Expenses/EBITDA/FCF/Dividends in 4 scenarios (Good, Mediocre, Bad, Worst Case)
5. **Editable Assumptions** - Make key assumptions adjustable by user
6. **Typography** - Change body text to serif font (like Claude uses)

---

## Phase 1: Typography Update (Quick Win)

### Changes
- **File**: `app/globals.css`
- Change body font from `var(--font-sans)` to `var(--font-serif)`
- Source Serif 4 is already loaded in `layout.tsx`
- Keep headings as serif (already set)

```css
body {
  font-family: var(--font-serif), Georgia, serif;
}
```

---

## Phase 2: Editable Assumptions System

### Overview
Allow users to override key assumptions that drive calculations.

### New Types (`lib/types.ts`)
```typescript
export interface EditableAssumptions {
  revenueGrowthRate: number;      // % annual growth
  ebitdaMargin: number;           // % margin
  taxRate: number;                // % tax rate
  capexAsPercentOfRevenue: number;// % of revenue
  workingCapitalAsPercentOfRevenue: number;
  terminalGrowthRate: number;     // % perpetual growth
  discountRate: number;           // WACC %
  debtInterestRate: number;       // % interest on debt
  targetDebtToEbitda: number;     // x multiple
}

export interface ProjectionYear {
  year: number;
  revenue: number;
  expenses: number;
  ebitda: number;
  interestExpense: number;
  taxes: number;
  netIncome: number;
  capex: number;
  workingCapitalChange: number;
  freeCashFlow: number;
  debtPaydown: number;
  dividends: number;
}
```

### New Component (`components/AssumptionsEditor.tsx`)
- Collapsible panel with input sliders/fields
- Categories: Growth, Margins, Capital Structure, Rates
- Real-time recalculation on change
- Reset to AI defaults button
- Shows which assumptions are modified

---

## Phase 3: 5-Year Projection Table

### Overview
Show projected financials in 4 scenarios over 5 years.

### New Types (`lib/types.ts`)
```typescript
export interface ScenarioProjection {
  name: 'good' | 'mediocre' | 'bad' | 'worst';
  label: string;  // "Good", "Mediocre", "Bad", "Shit The Bed"
  description: string;
  assumptions: Partial<EditableAssumptions>;
  years: ProjectionYear[];
}

export interface FiveYearProjections {
  baseYear: number;
  scenarios: ScenarioProjection[];
}
```

### Prompt Update (`lib/prompts.ts`)
Add to JSON schema:
```typescript
fiveYearProjections: {
  baseYear: number,
  scenarios: [
    { name: "good", label: "Good", revenueGrowth: 15, marginExpansion: 2, ... },
    { name: "mediocre", label: "Mediocre", ... },
    { name: "bad", label: "Bad", ... },
    { name: "worst", label: "Worst Case", ... }
  ]
}
```

### New Component (`components/FiveYearProjections.tsx`)
- Tab selector for scenarios (Good | Mediocre | Bad | Worst)
- Clean table showing per-year metrics:
  - Revenue
  - Expenses
  - EBITDA
  - Free Cash Flow
  - Dividends
- Color coding: Good (green), Mediocre (amber), Bad (orange), Worst (red)
- Mini sparkline charts for each metric trend
- Assumptions summary below each scenario

---

## Phase 4: Debt Capacity Analysis

### Overview
Analyze how much debt the business can support and recommend structures.

### New Types (`lib/types.ts`)
```typescript
export interface DebtStructure {
  type: 'senior' | 'mezzanine' | 'seller_note' | 'sba' | 'revolver';
  name: string;
  amount: number;
  interestRate: number;
  term: number;  // years
  amortization: string;  // "Interest only", "10-year amortization", etc.
  covenants?: string[];
}

export interface DebtCapacityAnalysis {
  maxSeniorDebt: number;
  maxTotalDebt: number;
  recommendedDebtAmount: number;
  debtToEbitdaMultiple: number;
  interestCoverageRatio: number;
  debtServiceCoverageRatio: number;
  recommendedStructures: DebtStructure[];
  analysis: string;
  risks: string[];
  bankabilityScore: 'high' | 'medium' | 'low';
}
```

### Prompt Update (`lib/prompts.ts`)
Request Claude to analyze:
- Typical debt multiples for this industry
- Maximum sustainable debt based on cash flows
- Recommended mix of senior/mezz/seller note
- Key covenants and terms to expect

### New Component (`components/DebtCapacitySection.tsx`)
- **Header**: Max Debt Capacity, Recommended Amount
- **Visual**: Stacked bar showing debt stack (senior/mezz/seller)
- **Debt Structure Cards**: For each recommended structure showing terms
- **Metrics Table**: Coverage ratios, debt multiples
- **Bankability Assessment**: Visual indicator of likelihood of bank approval
- **Risk Factors**: What could impact debt capacity

---

## Phase 5: Cash-on-Cash Return Analysis

### Overview
Show investor returns under different leverage scenarios.

### New Types (`lib/types.ts`)
```typescript
export interface CashOnCashScenario {
  name: string;
  equityInvested: number;
  debtUsed: number;
  totalPurchasePrice: number;
  yearlyReturns: {
    year: number;
    cashFlow: number;
    cumulativeCash: number;
    cashOnCash: number;  // % return that year
  }[];
  exitValue: number;
  totalCashReturned: number;
  irr: number;
  moic: number;  // multiple on invested capital
}

export interface CashOnCashAnalysis {
  scenarios: CashOnCashScenario[];  // All cash, 50/50, Max leverage
  comparisonTable: {
    metric: string;
    allCash: number | string;
    moderate: number | string;
    maxLeverage: number | string;
  }[];
  recommendation: string;
}
```

### New Component (`components/CashOnCashAnalysis.tsx`)
- **Scenario Toggle**: All Cash | 50/50 Debt/Equity | Max Leverage
- **Waterfall Chart**: Shows cash flows and returns visually
- **Comparison Table**:
  | Metric | All Cash | 50/50 | Max Leverage |
  |--------|----------|-------|--------------|
  | Equity Required | $X | $Y | $Z |
  | Year 1 CoC | X% | Y% | Z% |
  | 5-Year IRR | X% | Y% | Z% |
  | MOIC | X.Xx | X.Xx | X.Xx |
- **IRR Chart**: Line chart comparing scenarios over time
- **Recommendation**: AI-generated advice on optimal structure

---

## Phase 6: Bank-Specific PowerPoint Export

### Overview
Generate customized presentation decks tailored to specific lender types. Each lender category has different priorities, metrics, and language preferences.

### Lender Selection UI (`components/PowerPointExport.tsx`)
- Modal with lender type selector
- Shows recommended lenders for THIS deal based on analysis
- Preview of what content will be emphasized

---

### Lender Categories & Preferences

#### 🇨🇦 **CANADIAN BANKS - INDIVIDUAL PROFILES**

---

**1. BDC (Business Development Bank of Canada)**
- **What they like**: Entrepreneurs, growth stories, job creation, Canadian impact, business transitions
- **Key metrics**: Revenue growth, profitability trend, Canadian presence, management experience
- **Tone**: Mission-driven, nation-building, complementary financing
- **Unique**: Takes more risk than Big 5, flexible terms, supports transitions, will subordinate to other lenders
- **EBITDA range**: Any size, but sweet spot $500K-$5M
- **Industries favored**: Tech, clean tech, manufacturing, agribusiness, tourism
- **Emphasize**: Business continuity, management experience, market position, growth potential
- **Slide additions**: Canadian economic impact, jobs supported, regional presence, export potential
- **Typical terms**: 15-20 year amortization, flexible structures, patient capital

---

**2. RBC Royal Bank - Commercial Banking**
- **What they like**: Established businesses, strong management, diversified revenue, clean financials
- **Key metrics**: DSCR >1.25x, working capital ratio, debt/equity, revenue stability
- **Tone**: Professional, conservative, relationship-focused
- **EBITDA range**: $1M+ for acquisition financing
- **Industries with dedicated teams**: Technology, Healthcare, Real Estate, Agriculture, Franchise, Manufacturing
- **Unique angle**: Canada's largest bank - best for larger mid-market deals, cross-border US/Canada
- **What differentiates**: Strong wealth management integration for seller financing/rollover
- **Emphasize**: Historical profitability, management depth, clean books, growth strategy
- **Slide additions**: 3-year historical financials, management org chart, customer concentration, collateral schedule
- **Red flags they hate**: Declining revenue, customer concentration >25%, thin margins, limited collateral

---

**3. TD Bank - Commercial Banking**
- **What they like**: Healthcare professionals, stable industries, strong cash flow, established businesses
- **Key metrics**: DSCR >1.2x, owner equity contribution, industry experience
- **Tone**: Relationship-driven, solutions-focused
- **EBITDA range**: $500K-$25M
- **Industries with dedicated teams**:
  - **Healthcare Practice Solutions** (MAJOR FOCUS) - dental, medical, veterinary, optometry, pharmacy acquisitions
  - Professional services, franchises, manufacturing
- **Unique angle**: Best Canadian bank for healthcare practice acquisitions - dedicated Healthcare Practice team
- **What differentiates**: TD Healthcare Practice Solutions offers specialized underwriting for practice goodwill
- **Emphasize for Healthcare**: Practice EBITDA, patient count, staff retention, location quality, equipment condition
- **Emphasize general**: Cash flow stability, owner involvement, industry expertise
- **Slide additions**: Healthcare-specific metrics (patients/day, avg revenue/patient, insurance mix), equipment list
- **Special programs**: TD Practice Valuations, Practice Transition Planning

---

**4. BMO (Bank of Montreal) - Commercial Banking**
- **What they like**: Industry expertise, sponsor-backed deals, established mid-market companies
- **Key metrics**: EBITDA quality, leverage ratios, cash flow conversion
- **Tone**: Institutional, sophisticated, sector-focused
- **EBITDA range**: $2M-$50M+ (has dedicated mid-market and large corporate groups)
- **Industries with dedicated teams** (17 verticals):
  - Agriculture & Agribusiness
  - Business Properties & Commercial Real Estate
  - Dealer Finance (auto, equipment, RV)
  - Emerging Industries
  - Engineering & Construction
  - Franchise Finance
  - Healthcare
  - Manufacturing
  - Media & Entertainment
  - Oil & Gas Services
  - **Private Equity Sponsors** (sponsor coverage team)
  - Professional Services
  - Public Sector
  - Retail & Wholesale Distribution
  - **Technology Banking** (dedicated tech team)
  - Transportation & Logistics
  - Trucking
- **Unique angle**: Most sophisticated industry coverage of Big 5 - pitch to sector team
- **What differentiates**: Strong cross-border US capability, PE sponsor relationships, sector expertise
- **Emphasize**: Industry positioning, competitive moat, sponsor backing (if applicable)
- **Slide additions**: Industry benchmarking, competitive analysis, sector-specific KPIs
- **Best for**: Sponsor-backed deals, sector specialists, larger mid-market

---

**5. CIBC - Commercial Banking**
- **What they like**: Growth companies, innovation, specialized sectors, relationship banking
- **Key metrics**: Revenue growth, EBITDA trend, market position, management quality
- **Tone**: Entrepreneurial for a big bank, sector-focused, partnership approach
- **EBITDA range**: $1M-$25M
- **Industries with dedicated teams** (Areas of Specialization):
  - **Agriculture Services** - farm operations, agribusiness, food processing
  - **Healthcare Services** - dental, medical, long-term care, clinics
  - **Indigenous Markets** - First Nations businesses, Indigenous economic development
  - **Innovation Banking** - tech startups, venture-backed, IP-rich companies
  - **Franchise Services** - multi-unit operators, franchise acquisitions
  - **Entertainment Banking** - film, TV production, media
  - **Professional Service Firms** - accounting, law, engineering practices
  - **Business Service Firms** - staffing, facilities management
  - **Public Sector & Not-for-Profit** - government contractors, NGOs
  - **Mid-Market Investment Banking** - M&A advisory, capital markets
- **Unique angle**: Strong Innovation Banking for tech - more risk appetite than other Big 5
- **What differentiates**: Indigenous Markets expertise, Entertainment Banking, Innovation/tech focus
- **Emphasize**: Growth story, sector fit, innovation/IP value, management vision
- **Slide additions**: Growth trajectory chart, sector-specific metrics, innovation pipeline
- **Best for**: Tech companies, entertainment, Indigenous-owned, healthcare, franchises

---

**6. Scotiabank - Commercial Banking**
- **What they like**: International exposure, Latin America ties, trade finance, established businesses
- **Key metrics**: DSCR, export revenue, international diversification, currency exposure
- **Tone**: Global perspective, trade-focused, conservative on domestic-only deals
- **EBITDA range**: $1M-$50M
- **Industries with dedicated teams**:
  - Mining & Metals
  - Energy & Infrastructure
  - Automotive
  - Food & Agriculture
  - Real Estate
- **Unique angle**: Best for companies with Latin America/Caribbean exposure - strong LatAm network
- **What differentiates**: Pacific Alliance countries (Mexico, Chile, Peru, Colombia) presence, trade finance
- **Geographic strength**: Latin America, Caribbean, Pacific Alliance, Asia
- **Emphasize**: International customers, export revenue, cross-border operations, trade relationships
- **Slide additions**: Geographic revenue breakdown, international customer list, FX exposure, trade finance needs
- **Best for**: Exporters, LatAm-focused companies, mining/resources, international trade

---

**7. National Bank of Canada**
- **What they like**: Quebec businesses, business transitions/successions, mid-market M&A
- **Key metrics**: Cash flow, management succession plan, business continuity
- **Tone**: Relationship-driven, long-term partner, succession-focused
- **EBITDA range**: $500K-$20M
- **Geographic focus**: Primarily Quebec, but growing in Ontario and Western Canada
- **Unique angle**: **SPECIALIZED BUSINESS TRANSFER TEAM** - 1,500+ business transfers since 2010
- **What differentiates**:
  - Dedicated M&A/business transfer advisory team
  - Cash flow financing expertise (less collateral-dependent than Big 5)
  - Strong succession planning support
  - More flexible on deal structures
- **Industries favored**: Manufacturing, distribution, professional services, healthcare, retail
- **Emphasize**: Business continuity, management transition plan, employee retention, customer relationships
- **Slide additions**: Succession plan, key employee retention strategy, customer diversification, Quebec economic impact
- **Special programs**: National Bank Business Transfer Team, succession financing packages
- **Best for**: Quebec-based companies, business successions, owner transitions, family business sales

---

**8. ATB Financial (Alberta Treasury Branches)**
- **What they like**: Alberta businesses, agriculture, energy services, community impact
- **Key metrics**: Alberta presence, community ties, industry expertise, cash flow
- **Tone**: Community-focused, Alberta pride, relationship-driven
- **EBITDA range**: Any size, sweet spot $250K-$5M
- **Geographic focus**: Alberta only (crown corporation)
- **Industries with expertise**:
  - **Agriculture** (major focus) - farms, ranches, agribusiness, food processing
  - Energy services
  - Construction
  - Hospitality & tourism
  - Manufacturing
  - Technology (growing)
- **Unique angle**: Alberta-only focus means deep local relationships and understanding
- **What differentiates**:
  - More flexible than Big 5 on Alberta deals
  - Strong agriculture expertise
  - Community economic development mandate
  - Patient capital approach
- **Emphasize**: Alberta roots, community impact, local employment, industry expertise
- **Slide additions**: Alberta economic impact, local supplier relationships, community involvement
- **Best for**: Alberta-based businesses, agriculture, energy services, community-focused companies

---

**9. Desjardins (Caisse Desjardins)**
- **What they like**: Quebec businesses, cooperatives, community impact, member relationships
- **Key metrics**: Member relationship, community ties, cash flow, regional presence
- **Tone**: Cooperative values, community-first, long-term partnership
- **EBITDA range**: Any size, sweet spot $250K-$10M
- **Geographic focus**: Quebec primarily, some Ontario presence
- **Structure**: Credit union cooperative (largest in North America)
- **Industries favored**:
  - Agriculture
  - Manufacturing
  - Retail
  - Professional services
  - Healthcare
  - Real estate
- **Unique angle**: Cooperative values - will consider deals Big 5 won't if community benefit is strong
- **What differentiates**:
  - Member-owned structure means different risk appetite
  - Strong in rural Quebec
  - Community economic development focus
  - Flexible structures
- **Emphasize**: Community impact, employee retention, local economic benefit, cooperative values
- **Slide additions**: Community impact metrics, local employment, Quebec economic contribution
- **Best for**: Quebec-based businesses, community-focused deals, rural businesses, cooperatives

---

**10. Farm Credit Canada (FCC)**
- **What they like**: Agriculture and agribusiness ONLY, farm operations, food processing
- **Key metrics**: Agricultural revenue %, farm assets, food industry focus, land value
- **Tone**: Agriculture-first, patient capital, industry expertise
- **EBITDA range**: Any size agricultural operation
- **Geographic focus**: All of Canada
- **Eligible businesses** (strict criteria):
  - Primary agriculture (farms, ranches)
  - Agribusiness (equipment dealers, input suppliers)
  - Food processing and manufacturing
  - Aquaculture
  - Value-added agriculture
- **Unique angle**: 100% agriculture focused - deepest expertise, longest terms, most patient capital
- **What differentiates**:
  - 25+ year loan terms available
  - Understands agricultural cycles
  - Will lend on farmland at favorable rates
  - Industry-specific expertise
- **Emphasize**: Agricultural operations, food chain position, land assets, industry expertise
- **Slide additions**: Agricultural revenue breakdown, land/equipment assets, crop/livestock details
- **Restrictions**: Must have >50% agricultural revenue to be eligible
- **Best for**: Farm acquisitions, agribusiness, food processing, agricultural land purchases

---

**11. Laurentian Bank**
- **What they like**: Commercial real estate, inventory financing, equipment-heavy businesses
- **Key metrics**: Collateral coverage, asset quality, advance rates, borrowing base
- **Tone**: Asset-focused, specialty finance, niche expertise
- **EBITDA range**: $500K-$10M
- **Geographic focus**: National, headquartered in Montreal
- **Specialty areas** (pivoting to specialty commercial bank):
  - **Commercial Real Estate** - acquisition, construction, term financing
  - **Inventory Financing** - dealer floor plans, wholesale inventory
  - **Equipment Financing** - heavy equipment, vehicles, machinery
  - **Point-of-Sale Financing** - consumer and commercial
- **Unique angle**: Shifting from traditional banking to specialty commercial - more flexible on asset-backed deals
- **What differentiates**:
  - Less cash flow focused than Big 5
  - Strong inventory finance capability
  - Equipment finance expertise
  - Willing to take asset risk
- **Emphasize**: Asset quality, collateral value, inventory turnover, equipment condition
- **Slide additions**: Asset appraisals, inventory aging, equipment list with values, borrowing base
- **Best for**: Asset-heavy businesses, real estate, dealer finance, equipment-intensive operations

---

**12. EDC (Export Development Canada)**
- **What they like**: Export potential, international expansion, trade finance, Canadian companies going global
- **Key metrics**: Export revenue %, international growth potential, foreign buyer credit
- **Tone**: Trade-focused, growth-oriented, Canada Inc. advocate
- **EBITDA range**: Any size with export focus
- **Geographic focus**: Canadian companies with international revenue/potential
- **Products**:
  - Export financing
  - Foreign buyer financing
  - Export credit insurance
  - Working capital for exporters
  - International expansion loans
- **Unique angle**: Crown corporation focused on helping Canadian companies export
- **What differentiates**:
  - Will insure foreign receivables
  - Provides working capital against export contracts
  - Finances foreign buyers to purchase from Canadian sellers
  - Takes risks banks won't on international deals
- **Emphasize**: Export strategy, international customers, growth markets, trade relationships
- **Slide additions**: Export market analysis, international customer breakdown, trade finance needs
- **Best for**: Exporters, international expansion, foreign buyer situations, working capital for export growth

---

#### 🇺🇸 **US BANKS**

**5. SBA Lenders (Live Oak, Huntington, US Bank, Chase)**
- **What they like**: Small business growth, job creation, owner-operators
- **Key metrics**: DSCR (>1.15x), owner liquidity, industry experience
- **Tone**: Entrepreneurial, American dream, small business support
- **Requirements**: 10-20% equity injection, good personal credit (650+)
- **Emphasize**: Owner's industry experience, personal liquidity, stable cash flow
- **Slide additions**: Owner background, personal financial statement, SBA eligibility checklist
- **Max loan**: $5M, 10-25 year terms

**6. US Regional Banks**
- **What they like**: Local market presence, relationship banking
- **Key metrics**: Traditional underwriting, collateral coverage
- **Tone**: Relationship-focused, community banking
- **Emphasize**: Local market position, deposit relationship potential

---

#### 🏦 **PRIVATE CREDIT / DIRECT LENDERS - INDIVIDUAL PROFILES**

---

##### 🇺🇸 **US MEGA-CAP DIRECT LENDERS ($75M+ EBITDA)**

---

**7. Ares Capital Corporation (ARCC)**
- **AUM**: $21.5B+ portfolio, largest publicly traded BDC
- **EBITDA range**: $10M-$250M, sweet spot $50M-$150M
- **What they like**: Sponsor-backed, diversified businesses, proven management, recurring revenue
- **Key metrics**: Leverage 3-5x, DSCR >1.5x, interest coverage >2x
- **Tone**: Institutional, sophisticated, relationship-driven
- **Structure preferences**: First lien, unitranche, second lien
- **Typical deal size**: $50M-$500M+
- **Industries favored**: Software, healthcare, business services, industrials
- **What differentiates**: Scale allows large hold sizes, full capital structure solutions
- **Custom prompt emphasis**:
  > "Emphasize sponsor relationship, recurring revenue streams, EBITDA quality adjustments, and add-on acquisition pipeline. Ares values businesses with multiple value creation levers and defensible market positions. Highlight any Ares portfolio company synergies."
- **Slide additions**: Sponsor credentials, EBITDA bridge, add-on pipeline, quality of earnings summary

---

**8. Blue Owl Capital (Direct Lending)**
- **AUM**: $295B+ platform-wide
- **EBITDA range**: $25M-$500M, focus on **upper middle market ($100M+ EBITDA)**
- **What they like**: Large, stable, sponsor-backed businesses with predictable cash flows
- **Key metrics**: LTV ~40%, leverage 4-5x, strong equity cushion (>50%)
- **Tone**: Premium lender, selective, long-term partnership
- **Structure preferences**: First lien senior secured, unitranche
- **Typical deal size**: $100M-$1B+
- **Industries favored**: Software, healthcare services, business services, financial services
- **What differentiates**: Upper middle market focus = lower default rates, larger companies = more stability
- **Custom prompt emphasis**:
  > "Blue Owl focuses on the upper middle market - businesses with $100M+ EBITDA and strong equity cushions. Emphasize company scale, cash flow predictability, low cyclicality, and sponsor quality. They value businesses that are 'too big to fail' in their sectors."
- **Slide additions**: Company scale metrics, peer comparison, sponsor track record, cash flow consistency analysis

---

**9. Blue Owl Technology Finance (OTIC)**
- **AUM**: Part of Blue Owl Credit platform
- **EBITDA range**: $10M-$150M+ tech companies
- **What they like**: **SOFTWARE AND TECHNOLOGY FOCUS** - recurring revenue, SaaS, tech-enabled services
- **Key metrics**: ARR, net revenue retention, Rule of 40, gross margin >70%
- **Tone**: Tech-specialist, growth-oriented, understands software metrics
- **Structure preferences**: First lien, unitranche with warrant kickers
- **Typical deal size**: $25M-$250M
- **Industries**: Software/SaaS, tech-enabled services, healthcare IT, fintech
- **What differentiates**: Specialized in technology underwriting - understands software valuations
- **Custom prompt emphasis**:
  > "Blue Owl Tech Finance specializes in software and technology. Lead with ARR metrics, net revenue retention (>100% ideal), Rule of 40 performance, and gross margins. Emphasize recurring revenue, low churn, and expansion revenue. They understand tech multiples."
- **Slide additions**: ARR waterfall, NRR trends, cohort analysis, customer concentration, tech stack overview

---

**10. Golub Capital**
- **AUM**: $70B+
- **EBITDA range**: $10M-$100M, core middle market
- **What they like**: Sponsor-backed, stable businesses, one-stop financing
- **Key metrics**: Leverage 3-5x, EBITDA quality, sponsor equity contribution
- **Tone**: Reliable partner, solutions-oriented, fast execution
- **Structure preferences**: **GOLD (Golub One-Loan Debt)** - unitranche specialty
- **Typical deal size**: $25M-$500M
- **Industries favored**: Software, healthcare, business services, consumer
- **What differentiates**: One-stop shop - can do entire debt stack in single facility
- **Custom prompt emphasis**:
  > "Golub is known for their GOLD (one-stop) facilities providing certainty of close. Emphasize execution certainty needs, sponsor relationship, and business stability. They value repeat sponsor relationships and clean deals."
- **Slide additions**: Sponsor relationship history, execution timeline, EBITDA quality, management continuity

---

**11. HPS Investment Partners**
- **AUM**: $200B+ in private credit transactions
- **EBITDA range**: $50M-$500M+, **upper middle market and large-cap**
- **What they like**: Complex situations, large-scale financing, sponsor-backed and corporate
- **Key metrics**: Enterprise value $500M+, leverage 4-6x, strong cash flow
- **Tone**: Institutional, sophisticated, flexible capital provider
- **Structure preferences**: Senior secured, unitranche, mezzanine, structured equity
- **Typical deal size**: $100M-$2B+
- **Industries favored**: Diversified - healthcare, software, industrials, consumer
- **What differentiates**: Can do very large deals, comfortable with complexity
- **Custom prompt emphasis**:
  > "HPS is for large-scale, sophisticated financings. Emphasize deal size, complexity, and need for a partner who can hold large positions. They value businesses with scale that need creative capital solutions."
- **Slide additions**: Capital structure complexity, scale metrics, comparable large transactions

---

**12. Blackstone Credit (BCRED)**
- **AUM**: $300B+ in credit
- **EBITDA range**: **$200M+ EBITDA focus** - large-cap
- **What they like**: Large, performing companies, senior secured, conservative structures
- **Key metrics**: LTV ~40%, leverage 4x or less, strong equity cushion (>50%)
- **Tone**: Premier lender, conservative, institutional quality
- **Structure preferences**: Senior secured first lien only
- **Typical deal size**: $200M-$2B+
- **Industries favored**: Software, healthcare, insurance, financial services
- **What differentiates**: Focus on largest companies = lowest risk, AAA-rated approach
- **Custom prompt emphasis**:
  > "Blackstone Credit focuses on the largest, most stable companies with $200M+ EBITDA. Emphasize company scale, low LTV, strong equity cushion, and predictable cash flows. They are the 'blue chip' lender for blue chip companies."
- **Slide additions**: Scale comparison to peers, LTV analysis, equity cushion waterfall, credit rating equivalent

---

**13. KKR Credit**
- **AUM**: $250B+ platform
- **EBITDA range**: $50M-$150M, **upper middle market**
- **What they like**: Sponsor-backed, value creation stories, operational improvement potential
- **Key metrics**: Leverage 4-5x, EBITDA quality, sponsor equity >50%
- **Tone**: Sophisticated, operationally-focused, PE perspective
- **Structure preferences**: First lien, unitranche
- **Typical deal size**: $75M-$500M
- **Industries favored**: Healthcare, software, industrials, business services
- **What differentiates**: PE DNA - understands value creation and operational improvement
- **Custom prompt emphasis**:
  > "KKR Credit thinks like a PE firm. Emphasize value creation plan, operational improvement opportunities, and margin expansion potential. They want to see the PE playbook and believe in the upside story."
- **Slide additions**: Value creation roadmap, operational benchmarking, margin expansion bridge, PE sponsor track record

---

**14. Apollo Global Management (Credit)**
- **AUM**: $700B+ platform, $500B+ in credit
- **What they like**: Asset-based finance, large-scale, complex situations
- **Key metrics**: Asset quality, collateral coverage, cash flow
- **Tone**: Creative, flexible, solutions-oriented
- **Structure preferences**: Senior secured, asset-based, structured credit
- **Typical deal size**: $100M-$5B+
- **Industries favored**: Financial services, real estate, infrastructure, insurance
- **What differentiates**: Asset-based finance specialty, can do massive deals
- **Custom prompt emphasis**:
  > "Apollo excels at asset-based and structured credit solutions. If you have hard assets, receivables, or need creative financing, lead with collateral quality. They think beyond traditional cash flow lending."
- **Slide additions**: Asset/collateral analysis, borrowing base structure, asset quality metrics

---

##### 🇺🇸 **US CORE MIDDLE MARKET ($10M-$75M EBITDA)**

---

**15. Antares Capital**
- **AUM**: $55B+
- **EBITDA range**: $10M-$75M, **core middle market**
- **What they like**: Sponsor-backed, proven business models, growth potential
- **Key metrics**: Leverage 4-5x, DSCR >1.25x, sponsor equity >40%
- **Tone**: Execution-focused, reliable, relationship-driven
- **Structure preferences**: First lien, second lien, unitranche
- **Typical deal size**: $20M-$300M
- **Industries favored**: Healthcare, software, business services, industrials
- **What differentiates**: Pure-play sponsor-backed lender, deep sponsor relationships
- **Custom prompt emphasis**:
  > "Antares is a sponsor-backed specialist. Lead with sponsor credentials, transaction structure, and certainty of close requirements. They value repeat sponsor relationships above all."
- **Slide additions**: Sponsor track record, deal timeline, comparable Antares transactions

---

**16. Churchill Asset Management (Nuveen)**
- **AUM**: $56B+ committed capital
- **EBITDA range**: $10M-$75M, core middle market
- **What they like**: PE-backed, stable industries, first lien focus
- **Key metrics**: Leverage 4-5x, conservative structures, strong sponsors
- **Tone**: Institutional, consistent, relationship-focused
- **Structure preferences**: First lien, unitranche, second lien, mezzanine
- **Typical deal size**: $25M-$200M
- **Industries favored**: Healthcare, software, business services, consumer
- **What differentiates**: Part of TIAA/Nuveen - institutional backing, consistent capital
- **Custom prompt emphasis**:
  > "Churchill is backed by TIAA/Nuveen - institutional capital with long-term view. Emphasize business stability, sponsor quality, and conservative structures. They value consistency over aggressive growth stories."
- **Slide additions**: Sponsor credentials, historical performance, conservative structure proposal

---

**17. Varagon Capital Partners (Man Group)**
- **AUM**: $10B+
- **EBITDA range**: $15M-$75M, core middle market
- **What they like**: Sponsor-backed, covenant packages, cash generative businesses
- **Key metrics**: Multiple covenants, leverage 3-4.5x, strong cash flow
- **Tone**: Traditional, covenant-focused, disciplined
- **Structure preferences**: Senior secured with **full covenant packages**
- **Typical deal size**: $25M-$200M
- **Industries favored**: Business services, healthcare, software, industrials
- **What differentiates**: Covenant discipline - they maintain traditional covenant packages
- **Custom prompt emphasis**:
  > "Varagon maintains traditional covenant disciplines. Be prepared to accept leverage, coverage, and capex covenants. Emphasize business predictability and cash flow visibility that supports tight covenants."
- **Slide additions**: Covenant compliance history, cash flow forecast, covenant headroom analysis

---

**18. Prospect Capital Corporation**
- **AUM**: $12B+
- **EBITDA range**: Up to $150M EBITDA
- **What they like**: Diversified approaches - middle market lending, real estate, structured credit
- **Key metrics**: 85% first lien/senior secured focus
- **Tone**: Flexible, diversified, solutions-oriented
- **Structure preferences**: First lien, second lien, mezzanine
- **Typical deal size**: $10M-$200M
- **Industries favored**: Diversified across sectors
- **What differentiates**: Multi-strategy approach, can do various deal types
- **Custom prompt emphasis**:
  > "Prospect Capital is diversified across strategies. Lead with deal structure flexibility needs and highlight any real estate or structured credit components."
- **Slide additions**: Deal structure options, collateral analysis, multi-tranche proposal

---

**19. FS KKR Capital Corp**
- **AUM**: $15B+ portfolio
- **EBITDA range**: $25M-$150M, upper middle market focus
- **What they like**: Upper middle market, senior secured, sponsor-backed
- **Key metrics**: Senior secured focus, leverage 4-5x
- **Tone**: Institutional, conservative, KKR DNA
- **Structure preferences**: Senior secured first lien
- **Typical deal size**: $50M-$300M
- **Industries favored**: Software, healthcare, business services
- **What differentiates**: KKR expertise with BDC flexibility
- **Custom prompt emphasis**:
  > "FS KKR combines KKR's expertise with BDC capital. Emphasize upper middle market positioning, conservative structure, and business quality."
- **Slide additions**: Business quality metrics, senior secured structure, KKR comparable deals

---

##### 🇺🇸 **US LOWER MIDDLE MARKET ($3M-$50M EBITDA)**

---

**20. TPG Twin Brook Capital Partners**
- **AUM**: $17B+
- **EBITDA range**: **$3M-$50M**, emphasis on companies with **$25M EBITDA or below**
- **What they like**: Lower middle market specialists, sponsor-backed, lower leverage
- **Key metrics**: Leverage 3-4x (lower than upper market), strong equity cushion
- **Tone**: Specialist, disciplined, lower middle market experts
- **Structure preferences**: First lien, unitranche
- **Typical deal size**: $10M-$150M
- **Industries favored**: Business services, healthcare, software, industrials
- **What differentiates**: Pure lower middle market focus = less competition, better terms
- **Custom prompt emphasis**:
  > "Twin Brook is THE lower middle market specialist. For companies with $3-50M EBITDA, they offer better terms than upper-market lenders reaching down. Emphasize operational stability and sponsor commitment despite smaller size."
- **Slide additions**: Lower middle market positioning, leverage comparison to peers, sponsor track record in LMM

---

**21. Monroe Capital**
- **AUM**: $19B+
- **EBITDA range**: **$3M-$35M**, lower middle market focus
- **What they like**: Sponsored AND non-sponsored, lower middle market, diverse deal types
- **Key metrics**: Leverage 3-4x, cash flow coverage, collateral support
- **Tone**: Flexible, entrepreneur-friendly, solutions-oriented
- **Structure preferences**: First lien, unitranche, second lien, mezzanine
- **Typical deal size**: $5M-$75M
- **Industries favored**: Healthcare, business services, software, manufacturing
- **What differentiates**: Will do non-sponsored deals, more flexible than larger competitors
- **Custom prompt emphasis**:
  > "Monroe Capital does both sponsored AND non-sponsored deals in the lower middle market. If you lack a PE sponsor, lead with management quality and business defensibility. They are entrepreneur-friendly."
- **Slide additions**: Management bios (especially if non-sponsored), business defensibility, customer diversification

---

**22. Audax Private Debt**
- **AUM**: $15B+
- **EBITDA range**: $5M-$75M, **full capital structure provider**
- **What they like**: Flexible capital, full structure solutions, sponsor-backed
- **Key metrics**: Varies by tranche - leverage 3-6x depending on structure
- **Tone**: Flexible, solutions-oriented, full capital stack
- **Structure preferences**: First lien, second lien, mezzanine, unitranche, preferred equity
- **Typical deal size**: $15M-$200M
- **Industries favored**: Healthcare, business services, software, manufacturing
- **What differentiates**: Will do ENTIRE capital structure - senior through mezzanine
- **Custom prompt emphasis**:
  > "Audax does the full capital structure. If you need senior + mezz + preferred, they can do it all. Lead with total capital need and structure flexibility requirements."
- **Slide additions**: Full capital structure proposal, tranche breakdown, flexibility benefits

---

**23. Main Street Capital**
- **AUM**: $7B+
- **EBITDA range**: **$3M-$20M**, true lower middle market
- **What they like**: Lower middle market, long-term partnerships, equity co-investment
- **Key metrics**: Lower leverage tolerance, strong management, growth potential
- **Tone**: Partnership-oriented, long-term view, patient capital
- **Structure preferences**: First lien PLUS equity co-investment
- **Typical deal size**: $5M-$75M debt, plus equity
- **Industries favored**: Diversified - manufacturing, services, distribution
- **What differentiates**: Will co-invest equity alongside debt - aligned incentives
- **Custom prompt emphasis**:
  > "Main Street wants to be a partner, not just a lender. They co-invest equity alongside debt. Emphasize long-term growth story, management quality, and partnership potential."
- **Slide additions**: Equity co-investment opportunity, long-term growth plan, partnership structure

---

##### 🖥️ **TECHNOLOGY & VENTURE LENDERS**

---

**24. Hercules Capital**
- **AUM**: $4B+ portfolio
- **EBITDA range**: Pre-profit to $30M+ EBITDA tech companies
- **What they like**: **VENTURE AND GROWTH-STAGE TECHNOLOGY**, VC-backed companies
- **Key metrics**: Revenue growth, runway, VC backing quality, path to profitability
- **Tone**: Venture-oriented, growth-focused, tech specialists
- **Structure preferences**: Structured debt with **WARRANTS**, revenue-based
- **Typical deal size**: $10M-$150M
- **Industries**: Technology, life sciences, healthcare IT, SaaS
- **What differentiates**: Will lend to pre-profit companies with strong VC backing
- **Custom prompt emphasis**:
  > "Hercules is for VC-backed, growth-stage technology companies. Lead with VC syndicate quality, revenue growth rate, and path to profitability. They understand that tech companies may not be profitable yet."
- **Slide additions**: VC backing details, growth trajectory, runway analysis, path to profitability

---

**25. Trinity Capital**
- **AUM**: $1.5B+
- **EBITDA range**: Growth-stage technology companies, often pre-profit
- **What they like**: Venture-backed technology, equipment financing, growth capital
- **Key metrics**: Revenue growth, VC quality, equipment/asset base
- **Tone**: Growth-oriented, tech-focused, flexible structures
- **Structure preferences**: Term loans, equipment financing, growth capital
- **Typical deal size**: $5M-$75M
- **Industries**: Technology, life sciences, healthcare technology
- **What differentiates**: Equipment finance expertise for tech companies
- **Custom prompt emphasis**:
  > "Trinity specializes in growth-stage tech with equipment needs. If you have capital equipment or infrastructure needs alongside growth capital, they can structure around assets."
- **Slide additions**: Equipment/asset list, growth capital uses, VC backing, revenue trajectory

---

**26. Horizon Technology Finance**
- **AUM**: $800M+ portfolio
- **EBITDA range**: Pre-profit to early-profit technology and life sciences
- **What they like**: Venture-backed technology and life sciences companies
- **Key metrics**: VC quality, clinical stage (for life sciences), revenue growth
- **Tone**: Specialized, venture-aligned, milestone-focused
- **Structure preferences**: Secured debt with warrants, milestone-based
- **Typical deal size**: $5M-$50M
- **Industries**: Technology, life sciences, healthcare IT
- **What differentiates**: Life sciences expertise - understands clinical milestones
- **Custom prompt emphasis**:
  > "Horizon excels in life sciences alongside tech. For healthcare/biotech companies, lead with clinical stage, regulatory milestones, and VC syndicate. They understand FDA pathways."
- **Slide additions**: Clinical/regulatory milestones, VC syndicate, technology readiness, growth trajectory

---

##### 🇨🇦 **CANADIAN PRIVATE CREDIT**

---

**27. Sagard Private Credit Fund (SPCF)**
- **AUM**: $3B+
- **EBITDA range**: $5M-$50M, **North American mid-market**
- **What they like**: **NON-SPONSOR FOCUS** - lend directly to companies, not through PE
- **Key metrics**: Cash flow, management quality, business defensibility
- **Tone**: Partnership-oriented, management-focused, Canadian values
- **Structure preferences**: First lien senior secured, unitranche
- **Typical deal size**: $10M-$100M
- **Geographic focus**: Canada and US
- **What differentiates**: Non-sponsor focus means they partner with management teams directly
- **Custom prompt emphasis**:
  > "Sagard SPCF is for companies WITHOUT PE sponsors who want debt capital. Lead with management quality, business defensibility, and growth plan. They become your partner, not your sponsor's lender."
- **Slide additions**: Management depth, business moat, customer diversification, growth strategy

---

**28. Onex Credit**
- **AUM**: $12B+
- **EBITDA range**: $15M-$75M, **North American middle market**
- **What they like**: First lien senior secured, sponsor-backed, predictable cash flow
- **Key metrics**: Leverage 3-5x, strong cash flow, conservative structures
- **Tone**: Institutional, Canadian blue-chip, conservative
- **Structure preferences**: First lien senior secured only
- **Typical deal size**: $25M-$200M
- **Geographic focus**: North America (Canada + US)
- **What differentiates**: Onex (Canadian PE giant) DNA - institutional quality
- **Custom prompt emphasis**:
  > "Onex Credit brings institutional Onex quality to middle market lending. Emphasize business stability, sponsor quality, and conservative structure. Canadian companies get 'home country' advantage."
- **Slide additions**: North American market position, conservative structure, sponsor credentials

---

**29. Northleaf Capital Partners (Credit)**
- **AUM**: $28B+ platform
- **EBITDA range**: $10M-$75M, **Canadian mid-market focus**
- **What they like**: Canadian mid-market, cross-capital structure, infrastructure
- **Key metrics**: Cash flow, Canadian market position, growth potential
- **Tone**: Canadian institutional, long-term view, partnership-oriented
- **Structure preferences**: Senior, mezzanine, infrastructure credit
- **Typical deal size**: $15M-$150M
- **Geographic focus**: Canadian mid-market primarily
- **What differentiates**: Deep Canadian mid-market expertise, backed by CPP Investments
- **Custom prompt emphasis**:
  > "Northleaf is THE Canadian mid-market specialist, backed by CPP Investments. For Canadian companies, lead with domestic market position and Canadian growth story."
- **Slide additions**: Canadian market analysis, domestic competitive position, growth strategy

---

**30. Brookfield Credit**
- **AUM**: $300B+ in credit across Brookfield platform
- **EBITDA range**: $50M+ EBITDA, large-scale
- **What they like**: Real estate credit, infrastructure, large corporate
- **Key metrics**: Asset quality, cash flow, scale
- **Tone**: Institutional, global scale, asset-focused
- **Structure preferences**: Senior secured, real estate credit, infrastructure debt
- **Typical deal size**: $100M-$1B+
- **Geographic focus**: Global, North American headquarters
- **What differentiates**: Real estate and infrastructure credit specialty
- **Custom prompt emphasis**:
  > "Brookfield Credit excels in real estate and infrastructure financing. If your business has significant real estate or infrastructure assets, lead with asset quality and long-term cash flows."
- **Slide additions**: Real estate/infrastructure asset analysis, long-term cash flow projections

---

#### 📊 **MEZZANINE / JUNIOR CAPITAL - INDIVIDUAL PROFILES**

---

**31. Audax Mezzanine**
- **AUM**: Part of $15B+ Audax Private Debt platform
- **EBITDA range**: $10M-$75M
- **What they like**: Growth stories, subordinated positions, sponsor-backed
- **Returns expected**: 14-18% blended (cash pay + PIK)
- **Key metrics**: Total leverage 4.5-6x, cash flow coverage, growth rate
- **Tone**: Flexible, growth-oriented, partnership approach
- **Structure preferences**: Subordinated debt, PIK toggle, warrant kickers
- **Typical deal size**: $10M-$75M
- **What differentiates**: Part of full capital structure provider - can pair with Audax senior
- **Custom prompt emphasis**:
  > "Audax Mezzanine wants to see the growth story. Lead with margin expansion, revenue growth, and value creation plan. They expect equity-like returns so tell the equity story."
- **Slide additions**: Growth projections, margin expansion bridge, value creation roadmap, warrant/equity terms

---

**32. Maranon Capital**
- **AUM**: $5B+
- **EBITDA range**: $10M-$50M, core middle market
- **What they like**: Sponsor-backed, growth opportunities, subordinated positions
- **Returns expected**: 13-17% blended
- **Key metrics**: Total leverage 4-5.5x, sponsor equity cushion, growth potential
- **Tone**: Middle market specialist, relationship-driven
- **Structure preferences**: Second lien, mezzanine, subordinated debt
- **Typical deal size**: $10M-$50M
- **Industries favored**: Business services, healthcare, software
- **What differentiates**: Pure middle market mezzanine specialist
- **Custom prompt emphasis**:
  > "Maranon focuses on middle market mezzanine. Emphasize sponsor quality, growth trajectory, and clear path to refinancing or exit. They need to see how they get repaid."
- **Slide additions**: Sponsor credentials, growth plan, refinancing/exit scenarios, total leverage analysis

---

**33. H.I.G. WhiteHorse**
- **AUM**: $5.9B+ in latest fund
- **EBITDA range**: $10M-$75M
- **What they like**: Middle market, both senior and mezzanine, flexible structures
- **Returns expected**: Senior: market rates, Mezz: 13-16%
- **Key metrics**: Leverage 3-5x, cash flow quality, sponsor backing
- **Tone**: Flexible, solutions-oriented, H.I.G. ecosystem
- **Structure preferences**: First lien, second lien, unitranche, mezzanine
- **Typical deal size**: $15M-$150M
- **What differentiates**: Part of H.I.G. Capital ecosystem - potential PE relationship
- **Custom prompt emphasis**:
  > "WhiteHorse is connected to H.I.G. Capital PE. If you're seeking both debt and potential PE partnership, emphasize the full relationship opportunity."
- **Slide additions**: Capital structure flexibility, H.I.G. ecosystem fit, growth story

---

**34. Crescent Capital Mezzanine**
- **AUM**: Part of $40B+ platform
- **EBITDA range**: $5M-$50M, lower middle market focus
- **What they like**: Lower middle market, growth capital, sponsor-backed
- **Returns expected**: 14-18%
- **Key metrics**: Total leverage 4-5.5x, sponsor commitment, growth trajectory
- **Tone**: Lower middle market specialist, European and US
- **Structure preferences**: Second lien, mezzanine, preferred equity
- **Typical deal size**: $5M-$50M
- **Geographic focus**: US and European lower middle market
- **What differentiates**: Lower middle market mezzanine specialist
- **Custom prompt emphasis**:
  > "Crescent specializes in lower middle market mezzanine. For smaller companies ($5-50M EBITDA) seeking subordinated capital, lead with management quality and growth plan."
- **Slide additions**: Lower middle market positioning, growth capital uses, refinancing plan

---

**35. Goldman Sachs Mezzanine Partners**
- **AUM**: $10B+ dedicated mezzanine
- **EBITDA range**: $25M-$150M+
- **What they like**: Larger middle market, institutional quality, complex structures
- **Returns expected**: 15-20%
- **Key metrics**: Total leverage 5-6x, sponsor quality, enterprise value $200M+
- **Tone**: Institutional, sophisticated, Goldman quality
- **Structure preferences**: Mezzanine, preferred equity, structured equity
- **Typical deal size**: $25M-$250M
- **What differentiates**: Goldman brand, can do very large mezzanine tranches
- **Custom prompt emphasis**:
  > "Goldman Sachs Mezz is for larger, institutional-quality mezzanine needs. Emphasize deal quality, sponsor credentials, and the institutional nature of the opportunity."
- **Slide additions**: Institutional quality metrics, sponsor track record, comparable Goldman transactions

---

**36. Madison Capital Funding (Mezzanine)**
- **AUM**: $10B+ platform
- **EBITDA range**: $5M-$50M
- **What they like**: Lower middle market, growth capital, sponsor relationships
- **Returns expected**: 13-17%
- **Key metrics**: Total leverage 4-5.5x, sponsor commitment, EBITDA quality
- **Tone**: Lower middle market specialist, relationship-focused
- **Structure preferences**: Second lien, mezzanine, equity co-invest
- **Typical deal size**: $5M-$75M
- **What differentiates**: Strong lower middle market presence, equity co-invest capability
- **Custom prompt emphasis**:
  > "Madison does mezzanine with equity co-investment in the lower middle market. If you want an aligned capital partner with skin in the game, emphasize the partnership opportunity."
- **Slide additions**: Equity co-investment structure, growth plan, management alignment

---

#### 🏭 **ASSET-BASED LENDERS - INDIVIDUAL PROFILES**

---

**37. Wells Fargo Capital Finance (ABL)**
- **AUM**: Largest bank ABL platform
- **What they like**: Large-scale ABL, strong collateral, diversified receivables
- **Key metrics**: Borrowing base, advance rates (AR: 80-85%, Inventory: 50-70%)
- **Tone**: Institutional, conservative, bank-grade
- **Structure preferences**: ABL revolver, term loan with asset coverage
- **Typical deal size**: $25M-$500M+
- **Industries favored**: Manufacturing, distribution, retail, consumer products
- **What differentiates**: Scale, can do massive ABL facilities
- **Custom prompt emphasis**:
  > "Wells Fargo ABL is for large-scale asset-based needs. Lead with borrowing base analysis, AR quality, and inventory composition. They want to see institutional-quality collateral."
- **Slide additions**: Borrowing base certificate, AR aging, inventory analysis, dilution history

---

**38. Bank of America Business Capital (ABL)**
- **AUM**: Top 3 bank ABL platform
- **What they like**: Middle market and large-cap ABL, quality collateral
- **Key metrics**: Borrowing base availability, AR concentration, inventory turns
- **Tone**: Institutional, relationship-focused
- **Structure preferences**: ABL revolver, term loan
- **Typical deal size**: $15M-$300M+
- **Industries favored**: Manufacturing, wholesale, distribution
- **What differentiates**: Strong bank relationship integration
- **Custom prompt emphasis**:
  > "BofA ABL values the full banking relationship. If you'll bring deposits and treasury management, emphasize the total relationship opportunity alongside collateral quality."
- **Slide additions**: Total banking relationship, borrowing base, treasury management needs

---

**39. PNC Business Credit (ABL)**
- **AUM**: Major bank ABL platform
- **What they like**: Middle market ABL, regional relationships, diverse collateral
- **Key metrics**: Borrowing base, advance rates, collateral monitoring
- **Tone**: Middle market focused, relationship-driven
- **Structure preferences**: ABL revolver, equipment term loans
- **Typical deal size**: $10M-$150M
- **What differentiates**: Strong middle market ABL focus
- **Custom prompt emphasis**:
  > "PNC ABL is strong in the middle market. Lead with asset quality and the regional business relationship opportunity."
- **Slide additions**: Borrowing base analysis, regional presence, equipment collateral

---

**40. Pathlight Capital (ABL)**
- **AUM**: $1.9B+ recent fund
- **What they like**: Private credit ABL, working capital, complex situations
- **Key metrics**: Asset quality, borrowing base, advance rates
- **Tone**: Flexible, private credit approach to ABL
- **Structure preferences**: First/second lien ABL, working capital facilities
- **Typical deal size**: $15M-$150M
- **Industries favored**: Retail, consumer, manufacturing, distribution
- **What differentiates**: Private credit flexibility with ABL focus - more creative than bank ABL
- **Custom prompt emphasis**:
  > "Pathlight brings private credit flexibility to ABL. If your situation is too complex for bank ABL but asset-heavy, they can structure creatively around collateral."
- **Slide additions**: Asset analysis, complex situation explanation, borrowing base

---

#### 👨‍👩‍👧‍👦 **FAMILY OFFICES - DETAILED PROFILES**

Family offices represent a unique capital source with different motivations than institutional investors. Here are the key types and how to approach them:

---

**41. Single Family Offices (SFOs) - General Profile**
- **Capital range**: $100M-$10B+
- **What they like**: Principal protection, steady income, long-term relationships, direct access
- **Key metrics**: Collateral coverage (>1.5x), cash-pay interest, covenant protection
- **Tone**: Conservative, relationship-driven, trust-focused, patient
- **Structure preferences**: Senior secured with personal attention, simple structures
- **Decision speed**: Can be faster than institutional (single decision-maker)
- **What differentiates**: No fund life constraints, patient capital, relationship over returns
- **Custom prompt emphasis**:
  > "Family offices prioritize capital preservation and relationships over maximum returns. Lead with downside protection, management integrity, and the opportunity for a long-term partnership. They invest in people as much as businesses."
- **Key slides to include**:
  - Management team backgrounds and integrity
  - Collateral/asset coverage analysis
  - Downside scenarios and protection
  - Long-term partnership vision
  - Simple, clear deal structure

---

**42. Multi-Family Offices (MFOs) - General Profile**
- **Capital range**: $500M-$50B+ combined
- **What they like**: Diversified exposure, professional management, co-investment opportunities
- **Key metrics**: Risk-adjusted returns, diversification benefit, manager quality
- **Tone**: More institutional than SFO, but still relationship-focused
- **Structure preferences**: Fund investments plus co-invests, club deals
- **What differentiates**: Multiple families = more capital, more institutional process
- **Custom prompt emphasis**:
  > "MFOs balance family office values with institutional process. Lead with risk-adjusted returns, manager track record, and co-investment opportunity."
- **Slide additions**: Risk analysis, manager credentials, portfolio fit

---

##### **Notable Family Offices Active in Direct Lending:**

---

**43. Pritzker Family (Various Vehicles)**
- **Family wealth**: $30B+
- **Investment focus**: Direct investments, growth equity, lending
- **What they like**: Large, stable businesses, Midwest connections, long-term holds
- **Industries**: Manufacturing, services, healthcare
- **Custom prompt emphasis**:
  > "Pritzker entities value operational excellence and long-term partnership. Emphasize business quality, management depth, and multi-generational holding potential."

---

**44. Stephens Inc. (Stephens Family)**
- **Capital**: $3B+ investment banking and principal investing
- **Geographic focus**: Middle America, South, Southwest
- **What they like**: Regional businesses, relationship-driven, growth capital
- **Industries**: Transportation, energy, healthcare, financial services
- **Custom prompt emphasis**:
  > "Stephens values regional relationships and Middle America businesses. Lead with regional presence, community ties, and long-term growth story."
- **Slide additions**: Regional market analysis, community impact, relationship potential

---

**45. Tillery Capital (Family Office)**
- **Focus**: Lower middle market direct lending
- **EBITDA range**: $3M-$20M
- **What they like**: Smaller deals, direct relationships, entrepreneur partnerships
- **Tone**: Entrepreneur-friendly, patient, relationship-focused
- **Custom prompt emphasis**:
  > "Tillery focuses on smaller lower middle market deals. For companies too small for institutional capital, lead with management quality and growth potential."

---

**46. Patona Partners (Family Office)**
- **Focus**: Lower middle market investments
- **Geographic focus**: Northeast US
- **What they like**: Direct deals, operational value-add, long-term holds
- **Custom prompt emphasis**:
  > "Patona is active in lower middle market direct deals. Emphasize operational improvement opportunities and long-term partnership potential."

---

**47. Station Partners (Family Office)**
- **Focus**: Private credit and equity
- **Geographic focus**: Mid-Atlantic
- **What they like**: Relationship-driven deals, quality management
- **Custom prompt emphasis**:
  > "Station Partners values relationships and management quality. Lead with the people story and long-term vision."

---

##### **How to Approach Family Offices - General Guidelines:**

**Finding Family Offices:**
- Axial network (25+ active family offices)
- Family office networks and conferences
- Private wealth advisors and banks
- Direct referrals from management teams

**What Family Offices Uniquely Offer:**
- No fund timeline constraints (can hold forever)
- Flexible structures (not bound by fund documents)
- Relationship-focused (value trust over basis points)
- Co-investment alongside institutional capital
- Patient capital during difficult periods
- Simpler decision-making (fewer committees)

**What Family Offices Want to See:**
1. **Management integrity** - They invest in people first
2. **Capital preservation** - Downside protection is paramount
3. **Simple structures** - No complex waterfalls or promotes
4. **Long-term vision** - Multi-generational thinking
5. **Direct access** - Personal relationships with management
6. **Co-investment opportunity** - Alongside other smart money

**Universal Family Office Prompt Template:**
> "When presenting to family offices, lead with:
> 1. Management team integrity and track record
> 2. Downside protection and collateral coverage
> 3. Long-term partnership opportunity
> 4. Simple, clear deal structure
> 5. Personal access and relationship potential
> Family offices invest in people as much as businesses. The trust relationship matters more than the extra 50 basis points."

---

#### 🇬🇧 **UK/EUROPEAN BANKS**

**13. UK Banks (NatWest, Lloyds, Barclays, HSBC)**
- **What they like**: UK presence, SME focus, invoice finance eligible
- **Key metrics**: Turnover limits vary, DSCR, personal guarantees
- **Tone**: Relationship banking, regulatory compliant
- **Emphasize**: UK market position, turnover, asset backing
- **Slide additions**: UK-specific financials, VAT compliance, Companies House data

---

### Deal Matching & Recommendations

The system will analyze the company and recommend which lenders are best suited:

```typescript
interface LenderRecommendation {
  lenderType: string;
  fitScore: 'excellent' | 'good' | 'fair' | 'poor';
  reasons: string[];
  concerns: string[];
  suggestedApproach: string;
}
```

**Matching Criteria:**
- **EBITDA size** → Determines lender tier (SBA <$2M, Mid-market $2-25M, Large >$25M)
- **Industry** → Some lenders have sector preferences
- **Geography** → Canadian vs US vs UK content
- **Asset base** → ABL eligibility
- **Growth profile** → Mezz vs senior debt suitability
- **Sponsor backing** → Sponsored vs non-sponsored options

### New Component (`components/LenderSelector.tsx`)
- Visual grid of lender categories
- Fit score badges for each based on analysis
- Click to see why fit is good/poor
- Multi-select for generating multiple deck versions

### Slide Content Variations by Lender

| Section | SBA | Private Credit | Mezzanine | ABL |
|---------|-----|----------------|-----------|-----|
| Title | "Acquisition Opportunity" | "Investment Memorandum" | "Growth Capital Opportunity" | "Credit Facility Request" |
| Key Metric | Owner Experience | Sponsor Track Record | Growth Rate | Asset Coverage |
| Risk Section | Personal Guarantees | Covenant Package | Downside Protection | Borrowing Base |
| Ask | Loan Amount + Use | Leverage + Structure | Total Capital + Returns | Facility Size + Advance Rates |

### New File (`lib/lenderProfiles.ts`)
- Detailed profile for each lender type
- Content templates per lender
- Metric emphasis configuration
- Tone/language guidelines

### New File (`lib/pptxGenerator.ts`)
- Function to build each slide
- Lender-specific content injection
- Dynamic chart generation
- Consistent styling with lender-appropriate colors

---

## Phase 7: Lender Recommendation Engine

### Overview
AI-powered recommendations for which lenders would be interested in this specific deal.

### Prompt Enhancement (`lib/prompts.ts`)
Add to analysis output:
```typescript
lenderRecommendations: {
  topRecommendations: LenderRecommendation[];  // Top 3-5 best fits
  byCategory: {
    canadian: LenderRecommendation[];
    us: LenderRecommendation[];
    privateCredit: LenderRecommendation[];
    mezzanine: LenderRecommendation[];
    abl: LenderRecommendation[];
  };
  dealCharacteristics: {
    ebitdaTier: 'small' | 'lower-mid' | 'mid' | 'upper-mid' | 'large';
    assetIntensity: 'high' | 'medium' | 'low';
    growthProfile: 'high-growth' | 'stable' | 'turnaround';
    industryAppeal: string[];  // Industries this fits well
  };
}
```

### New Component (`components/LenderRecommendations.tsx`)
- Visual cards for top recommended lenders
- Fit score visualization (gauge or bar)
- Expandable "Why this lender" section
- Quick action: "Generate Deck for This Lender"

---

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `app/globals.css` | Modify | Change body to serif font |
| `lib/types.ts` | Modify | Add all new interfaces (assumptions, projections, debt, CoC, lenders) |
| `lib/prompts.ts` | Modify | Add debt/projections/CoC/lender recommendations to prompt |
| `lib/calculations.ts` | **NEW** | Financial calculation engine for projections |
| `lib/lenderProfiles.ts` | **NEW** | Lender preferences and templates database |
| `lib/pptxGenerator.ts` | **NEW** | PowerPoint generation with lender-specific content |
| `components/AssumptionsEditor.tsx` | **NEW** | Editable assumptions panel |
| `components/FiveYearProjections.tsx` | **NEW** | 4-scenario projections table |
| `components/DebtCapacitySection.tsx` | **NEW** | Debt analysis section |
| `components/CashOnCashAnalysis.tsx` | **NEW** | Returns analysis with leverage scenarios |
| `components/LenderSelector.tsx` | **NEW** | Lender type selection for PPT export |
| `components/LenderRecommendations.tsx` | **NEW** | AI-recommended lenders display |
| `components/PowerPointExport.tsx` | **NEW** | Bank-specific PPT export modal |
| `components/AnalysisReport.tsx` | Modify | Integrate all new sections |
| `app/page.tsx` | Modify | Add assumptions state management |
| `package.json` | Modify | Add pptxgenjs dependency |

---

## Implementation Order

1. **Typography** - Quick CSS change (5 min)
2. **Types & Prompts** - Foundation for all new data structures
3. **Lender Profiles Database** - Static data for all 13 lender categories
4. **Editable Assumptions** - Interactive assumption panel
5. **Financial Calculations Engine** - Powers projections and debt analysis
6. **5-Year Projections** - 4-scenario table with visual design
7. **Debt Capacity Section** - Leverage analysis and structure recommendations
8. **Cash-on-Cash Analysis** - IRR/MOIC with leverage scenarios
9. **Lender Recommendations** - AI-powered lender matching
10. **PowerPoint Export** - Bank-specific deck generation

---

## Design Principles

- **Visual & Friendly**: Use charts, colors, and clean layouts
- **Bank-Ready**: Professional enough for institutional presentation
- **Interactive**: Assumptions drive real-time recalculations
- **PE Analyst Focus**: Show the metrics that matter for deal evaluation
- **Scenario Thinking**: Always show range of outcomes, not single point
- **Lender-Aware**: Content adapts to what each lender cares about

---

## Lender Research Summary

### Canadian Banks - Individual Profiles
| Bank | EBITDA Range | Key Focus | Best For |
|------|--------------|-----------|----------|
| **BDC** | $500K-$5M | Growth, transitions | Flexible deals, growth stories |
| **RBC** | $1M+ | Conservative, stable | Larger mid-market, cross-border |
| **TD** | $500K-$25M | **Healthcare Practice** | Dental/medical/vet practice acquisitions |
| **BMO** | $2M-$50M+ | 17 industry verticals | Sponsor-backed, sector specialists |
| **CIBC** | $1M-$25M | Innovation, sectors | Tech, entertainment, Indigenous, franchises |
| **Scotiabank** | $1M-$50M | International, LatAm | Exporters, mining, cross-border |
| **National Bank** | $500K-$20M | Business transfers | Quebec, successions, transitions |
| **ATB** | $250K-$5M | Alberta, agriculture | Alberta-only, community-focused |
| **Desjardins** | $250K-$10M | Quebec, cooperatives | Quebec, community impact |
| **FCC** | Any (ag only) | Agriculture ONLY | Farm, agribusiness, food processing |
| **Laurentian** | $500K-$10M | Assets, inventory | Equipment-heavy, real estate |
| **EDC** | Any (export) | Export, trade | International expansion, trade finance |

### US Focus
| Lender | EBITDA Range | Key Focus | Unique Angle |
|--------|--------------|-----------|--------------|
| SBA Lenders | <$2M | Owner-operators | Government guarantee |
| Regional Banks | $1-10M | Local presence | Relationship banking |
| Direct Lenders | $10M+ | Sponsor-backed | Institutional, covenants |

### Private Credit / Direct Lenders - Complete Reference (47 Lenders)

#### US Mega-Cap ($75M+ EBITDA)
| Lender | EBITDA Range | Key Focus | Custom Prompt Key |
|--------|--------------|-----------|-------------------|
| **Ares Capital** | $50M-$250M | Sponsor-backed, recurring revenue | Sponsor relationship, add-on pipeline |
| **Blue Owl** | $100M+ | Upper middle market, stability | Scale, cash flow predictability |
| **Blue Owl Tech** | $10M-$150M tech | Software/SaaS | ARR, NRR, Rule of 40 |
| **Golub Capital** | $10M-$100M | One-stop (GOLD) | Execution certainty, sponsor repeat |
| **HPS Partners** | $50M-$500M+ | Large-scale, complex | Deal size, creative solutions |
| **Blackstone Credit** | $200M+ | Large-cap, conservative | Scale, equity cushion, LTV |
| **KKR Credit** | $50M-$150M | Value creation | PE playbook, operational upside |
| **Apollo Credit** | Large-scale | Asset-based, structured | Collateral, asset quality |

#### US Core Middle Market ($10M-$75M EBITDA)
| Lender | EBITDA Range | Key Focus | Custom Prompt Key |
|--------|--------------|-----------|-------------------|
| **Antares Capital** | $10M-$75M | Pure sponsor-backed | Sponsor credentials, certainty |
| **Churchill (Nuveen)** | $10M-$75M | Institutional, conservative | Stability, TIAA backing |
| **Varagon (Man)** | $15M-$75M | Covenant discipline | Cash flow visibility, covenants |
| **Prospect Capital** | Up to $150M | Multi-strategy | Structure flexibility |
| **FS KKR** | $25M-$150M | Upper MM, KKR DNA | Business quality, conservative |

#### US Lower Middle Market ($3M-$50M EBITDA)
| Lender | EBITDA Range | Key Focus | Custom Prompt Key |
|--------|--------------|-----------|-------------------|
| **Twin Brook (TPG)** | $3M-$50M | LMM specialist | Operational stability, lower leverage |
| **Monroe Capital** | $3M-$35M | Sponsor AND non-sponsor | Management quality, entrepreneur-friendly |
| **Audax Private Debt** | $5M-$75M | Full capital structure | Total capital need, flexibility |
| **Main Street Capital** | $3M-$20M | Equity co-invest | Partnership, long-term growth |

#### Technology / Venture Lenders
| Lender | Focus | Key Focus | Custom Prompt Key |
|--------|-------|-----------|-------------------|
| **Hercules Capital** | VC-backed tech | Pre-profit OK | VC syndicate, growth rate, path to profit |
| **Trinity Capital** | Growth-stage | Equipment + growth | Equipment assets, VC backing |
| **Horizon Tech Finance** | Tech + life sciences | Clinical milestones | FDA pathway, regulatory milestones |

#### Canadian Private Credit
| Lender | EBITDA Range | Key Focus | Custom Prompt Key |
|--------|--------------|-----------|-------------------|
| **Sagard SPCF** | $5M-$50M | Non-sponsor focus | Management quality, no PE needed |
| **Onex Credit** | $15M-$75M | Institutional, conservative | Business stability, Canadian advantage |
| **Northleaf Capital** | $10M-$75M | Canadian mid-market | Canadian market position, CPP backing |
| **Brookfield Credit** | $50M+ | Real estate, infrastructure | Asset quality, long-term cash flows |

#### Mezzanine / Junior Capital
| Lender | EBITDA Range | Returns | Custom Prompt Key |
|--------|--------------|---------|-------------------|
| **Audax Mezzanine** | $10M-$75M | 14-18% | Growth story, equity upside |
| **Maranon Capital** | $10M-$50M | 13-17% | Refinancing path, sponsor quality |
| **H.I.G. WhiteHorse** | $10M-$75M | 13-16% | H.I.G. ecosystem, flexibility |
| **Crescent Mezz** | $5M-$50M | 14-18% | Lower MM, growth capital |
| **Goldman Sachs Mezz** | $25M-$150M+ | 15-20% | Institutional quality |
| **Madison Capital** | $5M-$50M | 13-17% | Equity co-invest, partnership |

#### Asset-Based Lenders
| Lender | Deal Size | Key Focus | Custom Prompt Key |
|--------|-----------|-----------|-------------------|
| **Wells Fargo ABL** | $25M-$500M+ | Large-scale ABL | Borrowing base, institutional collateral |
| **BofA Business Capital** | $15M-$300M+ | Bank relationship | Total relationship, treasury |
| **PNC Business Credit** | $10M-$150M | Middle market ABL | Regional relationship |
| **Pathlight Capital** | $15M-$150M | Private credit ABL | Complex situations, creative |

#### Family Offices
| Type | Capital Range | Key Focus | Custom Prompt Key |
|------|---------------|-----------|-------------------|
| **Single Family Offices** | $100M-$10B+ | Principal protection | Management integrity, downside protection |
| **Multi-Family Offices** | $500M-$50B+ | Risk-adjusted returns | Manager quality, co-invest |
| **Notable SFOs** | Varies | Long-term partnership | People, trust, simplicity |

### Global/Specialty
| Lender | EBITDA Range | Key Focus | Unique Angle |
|--------|--------------|-----------|--------------|
| Mezzanine | $5M+ | Growth stories | Equity kickers, high returns |
| ABL | Asset-heavy | Collateral | Less cash flow focused |
| Family Offices | Varies | Principal protection | Conservative, long-term |
| UK Banks | UK-based | SME, turnover | Regulatory, VAT compliant |

### Quick Reference: Which Canadian Bank for Which Industry?
| Industry | Best Fit Banks | Why |
|----------|----------------|-----|
| Healthcare/Dental | **TD**, CIBC | TD Healthcare Practice Solutions team |
| Technology | **CIBC**, BMO | CIBC Innovation Banking, BMO Tech team |
| Agriculture | **FCC**, ATB, BDC | FCC = agriculture specialists |
| Entertainment/Film | **CIBC** | CIBC Entertainment Banking team |
| Mining/Resources | **Scotiabank** | Strong mining/metals expertise |
| Quebec businesses | **National Bank**, Desjardins | Local expertise, business transfer team |
| Alberta businesses | **ATB** | Alberta-only, deep local knowledge |
| Franchises | **BMO**, CIBC, TD | Dedicated franchise finance teams |
| Manufacturing | **BMO**, National Bank | Sector expertise |
| Professional Services | **CIBC**, BMO | Dedicated teams |
| Real Estate | **Laurentian**, BMO | Specialty focus |
| Export/International | **EDC**, Scotiabank | Trade finance expertise |
| Indigenous-owned | **CIBC** | Indigenous Markets team |
| PE-backed deals | **BMO** | Sponsor coverage team |

---

## Pending from Previous Plan

- `app/page.tsx` still needs reanalysis flow state management (in progress)
- This should be completed first before adding new features
