# Deep Code Review Command Plan

## Overview
Create `/deepcodereview` - an autonomous, multi-hour code analysis and improvement system that can run for hours or a full day without user intervention. The command performs comprehensive code review across security, performance, architecture, testing, and code quality, then systematically fixes issues while continuously verifying its work.

## User's Requirements
- Multi-hour or full-day execution capability
- Multiple rounds of fixes and tweaks
- Fully autonomous (no user intervention during execution)
- Self-testing and verification
- Comprehensive coverage including security
- **Fix ALL P0/P1/P2/P3 issues autonomously** (not just 80%)
- **Only pause at the end** to ask questions about tasks requiring major decisions
- **Generate user-friendly "vibe coder" summary** (non-technical explanation)
- Use Sonnet[1m] for analysis, Opus for planning, Sonnet for execution

## Recommended Approach

### Model Strategy
**Yes to the dual-model approach, with refinement:**
- **Sonnet 1M**: Initial codebase scanning, static analysis parsing, test execution (needs large context)
- **Opus 4.5**: Strategic planning, prioritization, security analysis, architectural decisions (needs reasoning)
- **Sonnet 4.5**: Code implementation, fixes, documentation updates (fast execution)
- **Sonnet 1M**: Final verification and comprehensive report generation

### Command File Location
`~/.claude/commands/deepcodereview.md` (~500-800 lines based on complexity)

## Comprehensive Review Scope

### 1. Security Analysis (CRITICAL - First Priority)
- SQL injection vulnerabilities
- XSS (Cross-Site Scripting) vulnerabilities
- CSRF (Cross-Site Request Forgery) issues
- Authentication/authorization flaws
- Sensitive data exposure (API keys, passwords in code)
- Insecure dependencies (npm audit, outdated packages)
- Command injection vulnerabilities
- Path traversal vulnerabilities
- Insecure cryptography usage
- OWASP Top 10 coverage

### 2. Code Quality & Maintainability
- Code smells and anti-patterns
- Dead code and unused imports/variables
- Naming conventions consistency
- Code duplication (DRY violations)
- Cyclomatic complexity metrics
- Function/method length
- Parameter count (too many parameters)
- Nested conditionals depth
- Magic numbers and hardcoded values

### 3. Performance Optimization
- N+1 query problems (database)
- Inefficient algorithms (O(n²) where O(n) possible)
- Memory leaks
- Unnecessary re-renders (React)
- Missing database indexes
- Large bundle sizes
- Synchronous operations blocking async flow
- Unnecessary computations in loops

### 4. Architecture & Design Patterns
- SOLID principles violations
- High coupling / low cohesion
- Missing or incorrect abstractions
- Inconsistent patterns across codebase
- Technical debt accumulation
- Separation of concerns
- Dependency injection opportunities

### 5. Type Safety (TypeScript/JavaScript)
- `any` type usage
- Missing return type annotations
- Loose type definitions
- Type assertions (`as`) overuse
- Missing null/undefined checks

### 6. Testing Coverage
- Missing unit tests for critical functions
- Missing integration tests
- Flaky tests
- Inadequate edge case coverage
- Missing error scenario tests
- Test code quality issues

### 7. Documentation
- Missing JSDoc/docstrings for public APIs
- Outdated comments
- Missing or inadequate README sections
- Unclear function/class purposes
- Missing inline comments for complex logic

### 8. Accessibility (Web Projects)
- Missing ARIA labels
- Keyboard navigation issues
- Color contrast problems
- Missing alt text for images
- Form accessibility

### 9. Error Handling
- Missing try-catch blocks
- Swallowed errors (empty catch blocks)
- Poor error messages
- Missing input validation
- Uncaught promise rejections

### 10. Best Practices & Standards
- ESLint rule violations
- Prettier formatting inconsistencies
- Framework-specific best practices (React, Next.js, etc.)
- API design consistency
- Git ignore completeness

## Multi-Pass Execution Strategy

### Phase 1: Discovery & Analysis (Sonnet 1M - 15-30 min)
**Objective**: Comprehensive codebase scanning and issue identification

1. **Environment Setup**
   - Switch to Sonnet 1M for large context analysis
   - Detect project type (React, Next.js, Node.js, Python, etc.)
   - Identify test framework and configuration
   - Locate key directories (src, tests, config)

2. **Static Analysis Execution**
   ```bash
   # Run all available linters
   npm run lint                    # ESLint
   npx tsc --noEmit               # TypeScript check
   npm audit                       # Security vulnerabilities
   npx depcheck                    # Unused dependencies
   ```

3. **Codebase Inventory**
   - Count total files, lines of code
   - Identify file types and their distribution
   - Map project structure
   - Find configuration files

4. **Manual Analysis**
   - Search for security anti-patterns (grep for eval, innerHTML, etc.)
   - Identify complex functions (>50 lines)
   - Find duplicate code patterns
   - Check for hardcoded credentials/secrets

5. **Test Baseline**
   - Run all existing tests to establish baseline
   - Capture current test coverage metrics
   - Identify flaky or slow tests

6. **Issue Collection**
   - Parse all tool outputs into structured issues
   - Manually identify issues from code reading
   - Create comprehensive TodoWrite list with ALL issues found
   - Each todo: severity (critical/high/medium/low), category, file location

### Phase 2: Strategic Planning (Opus 4.5 - 10-20 min)
**Objective**: Prioritize and create fix execution plan

1. **Switch to Opus 4.5** for strategic reasoning

2. **Issue Prioritization**
   - **P0 (Critical)**: Security vulnerabilities, data loss risks
   - **P1 (High)**: Bugs, critical performance issues, broken tests
   - **P2 (Medium)**: Code quality, maintainability, non-critical performance
   - **P3 (Low)**: Documentation, minor refactoring, style issues

3. **Dependency Analysis**
   - Identify issues that must be fixed in order
   - Find issues that can be batched together
   - Detect potential conflicts between fixes

4. **Round Planning** (Fix ALL P0/P1/P2/P3 autonomously)
   - **Round 1**: P0 Security fixes (critical vulnerabilities, data exposure)
   - **Round 2**: P1 Bug fixes (crashes, errors, broken functionality)
   - **Round 3**: P1 Performance critical (N+1 queries, memory leaks, blocking ops)
   - **Round 4**: P2 Code quality (dead code, duplication, complexity, type safety)
   - **Round 5**: P2 Architecture improvements (refactoring, better patterns)
   - **Round 6**: P3 Testing (add missing tests, fix flaky tests, improve coverage)
   - **Round 7**: P3 Documentation (JSDoc, README, inline comments)
   - **Round 8**: P3 Final polish (formatting, style, minor optimizations)
   - **Deferred**: Tasks requiring architectural decisions (asked at end via AskUserQuestion)

5. **Risk Assessment**
   - Identify high-risk changes that need extra care
   - Plan rollback strategy for each round
   - Estimate time for each round (for progress tracking)

### Phase 3: Implementation Rounds (Alternating Sonnet 4.5 and 1M - 3-20 hours)
**Objective**: Systematically fix ALL P0/P1/P2/P3 issues autonomously with continuous verification

**For Each Round:**

1. **Switch to Sonnet 4.5** (fast execution)

2. **Load Round Issues**
   - Get all todos for current priority level
   - Display round overview (X issues to fix)

3. **Fix Loop**
   ```
   For each issue in current round:
     - Mark todo as in_progress
     - Read affected files
     - Analyze root cause
     - Implement fix with best practices
     - Add inline comments explaining complex fixes
     - Mark todo as completed
     - Log change to report buffer
   ```

4. **Round Verification** (Switch to Sonnet 1M for verification)
   - Run relevant test suite
   - For security fixes: manually verify the fix works
   - For performance fixes: measure improvement
   - Re-run static analysis for affected files
   - If any failures: mark todos as failed, add to retry list

5. **Commit Round Changes** (after successful verification)
   ```bash
   git add -A
   git commit -m "Round X: [Category] - Fixed Y issues

   - Issue 1 brief description
   - Issue 2 brief description
   ...

   🤖 Generated by /deepcodereview"
   ```

6. **Progress Report**
   - Update running report with round results
   - Show: issues fixed, issues remaining, time elapsed
   - Display test results for this round

7. **Pause Point** (Every 2-3 rounds)
   - Write intermediate report to disk
   - Re-run full test suite as sanity check
   - If critical failures: stop and report
   - Otherwise: continue to next round

**Special Round Handling:**

- **Security Round**: After fixes, run security-specific tests, check npm audit again
- **Performance Round**: Profile before/after, verify improvements, no regressions
- **Refactoring Round**: More extensive test coverage required, check for behavior changes

### Phase 4: Final Verification (Sonnet 1M - 20-40 min)
**Objective**: Comprehensive validation and report generation

1. **Switch to Sonnet 1M** for full context analysis

2. **Complete Test Suite**
   ```bash
   npm run test              # All tests
   npm run test:e2e          # E2E if exists
   npm run test:integration  # Integration if exists
   ```

3. **Re-run All Static Analysis**
   - ESLint, TypeScript, npm audit
   - Compare before/after metrics
   - Verify all critical issues resolved

4. **Code Coverage Check**
   ```bash
   npm run test:coverage
   ```
   - Compare coverage before/after
   - Identify if coverage improved

5. **Performance Benchmarks** (if applicable)
   - Re-run performance tests
   - Measure bundle size changes
   - Check build time improvements

6. **Final Codebase Scan**
   - Quick grep for remaining security issues
   - Check for any TODO/FIXME comments added
   - Verify no debugging code left behind

### Phase 5: Comprehensive Reporting (Sonnet 1M - 10-15 min)
**Objective**: Generate detailed report and recommendations

**Report Structure** (`DEEPCODEREVIEW_REPORT.md`):

```markdown
# Deep Code Review Report
**Project**: [Name]
**Date**: [Timestamp]
**Duration**: [X hours Y minutes]
**Model**: Sonnet 1M → Opus 4.5 → Sonnet 4.5 (alternating)

## Executive Summary
- Total issues found: X
- Issues fixed: Y
- Issues remaining: Z
- Critical security fixes: N
- Test pass rate: before X% → after Y%
- Code coverage: before X% → after Y%

## Scan Results

### Security Analysis (P0)
[List of security issues found and fixed]

### Code Quality (P1-P2)
[List of quality issues]

### Performance Improvements (P1-P2)
[List of performance issues]

### Architecture & Design (P2)
[List of architectural improvements]

### Documentation (P3)
[Documentation gaps filled]

## Implementation Rounds

### Round 1: Critical Security Fixes
**Duration**: X minutes
**Issues Fixed**: Y
**Commits**: [commit hash]

#### Fix 1: SQL Injection in user.ts:45
- **Severity**: Critical
- **Root Cause**: Direct string interpolation in SQL query
- **Fix**: Implemented parameterized queries
- **Verification**: Tested with injection payloads, now safe
- **Files Modified**: `src/db/user.ts`

[... all fixes in round 1]

### Round 2: Bug Fixes
[Similar structure]

[... all rounds]

## Files Modified
Total files changed: X

### Critical Changes
- `src/auth/middleware.ts` - Fixed authentication bypass vulnerability
- `src/db/query.ts` - Implemented parameterized queries

### Major Changes
- `src/components/UserProfile.tsx` - Refactored for better performance
- `src/utils/validation.ts` - Added comprehensive input validation

### Minor Changes
- `src/types/user.ts` - Improved type definitions
- [... rest of files]

## Test Results

### Before Code Review
- Total tests: X
- Passing: Y (Z%)
- Failing: N
- Coverage: X%

### After Code Review
- Total tests: X+M (M new tests added)
- Passing: Y+N (Z%)
- Failing: 0
- Coverage: X+Y%

## Metrics

### Code Quality Metrics
| Metric | Before | After | Change |
|--------|--------|-------|--------|
| ESLint Errors | X | Y | ↓ Z% |
| TypeScript Errors | X | 0 | ↓ 100% |
| Security Vulnerabilities | X | 0 | ✓ Fixed |
| Code Duplication | X% | Y% | ↓ Z% |
| Average Function Complexity | X | Y | ↓ Z% |
| Test Coverage | X% | Y% | ↑ Z% |

### Performance Metrics (if applicable)
| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Bundle Size | X MB | Y MB | ↓ Z% |
| Build Time | X sec | Y sec | ↓ Z% |
| Lighthouse Score | X | Y | ↑ Z |

## Remaining Issues

### Known Limitations
[Any issues that couldn't be fixed automatically]

### Future Recommendations
1. **Architecture**: Consider implementing [pattern] for [reason]
2. **Testing**: Add integration tests for [feature]
3. **Performance**: Profile [component] under load
4. **Security**: Schedule regular dependency audits
5. **Documentation**: Create architecture decision records (ADRs)

## Statistics
- Total time: X hours Y minutes
- Lines of code analyzed: X
- Lines of code modified: Y
- Commits created: Z
- Issues fixed per hour: X

## Next Steps
1. Review this report thoroughly
2. Test the application end-to-end manually
3. Review all commits: `git log --since="X hours ago"`
4. Consider deploying to staging for further testing
5. Schedule follow-up review in [timeframe]
```

### Phase 6: Cleanup & Model Restoration (1-2 min)

1. **Create Summary Commit**
   ```bash
   git add DEEPCODEREVIEW_REPORT.md
   git commit -m "docs: Add deep code review report

   Comprehensive code review covering security, performance,
   quality, and architecture. Fixed X issues across Y files.

   🤖 Generated by /deepcodereview"
   ```

2. **Switch back to opusplan**
   ```bash
   /model opusplan
   ```

3. **Display Summary**
   - Show key metrics
   - Link to full report
   - Suggest next actions

## Command Structure

### Parameters
```bash
/deepcodereview                    # Review current project
/deepcodereview [project-name]     # Review specific project
/deepcodereview --scope [security|performance|quality|all]  # Focus on specific area
/deepcodereview --max-time 2h      # Limit execution time
```

### Project Name Mapping
- "deep personality" or "dp" → `~/Deep-Personality`
- "claude" → `~/.claude`
- Otherwise: try to find in common locations or use current directory

### Scope Options
- `security`: Only security analysis and fixes
- `performance`: Only performance improvements
- `quality`: Code quality and maintainability
- `all`: Everything (default)

## Safety Features

### Automatic Safeguards
1. **Git Status Check**: Ensure clean working directory before starting
2. **Backup Branch**: Create `backup/deepcodereview-[timestamp]` branch before changes
3. **Incremental Commits**: Commit after each round for easy rollback
4. **Test Gates**: If tests fail after a round, stop and report
5. **Time Limits**: Optional max-time parameter to prevent infinite loops
6. **Change Limits**: Stop if >1000 files would be modified (likely a mistake)

### Error Handling
- If critical tests fail: Stop immediately, report, suggest rollback
- If static analysis can't run: Skip that tool, continue with others
- If a fix introduces new issues: Revert that specific fix, log to report
- If system runs out of time: Generate report with current state, mark incomplete

### Verification Points
- After every round: Run relevant tests
- After every 3 rounds: Run full test suite
- Before final report: Complete verification pass

## Technical Implementation Details

### Tools to Execute
```bash
# JavaScript/TypeScript
npx eslint . --ext .js,.jsx,.ts,.tsx
npx tsc --noEmit
npm audit
npx depcheck
npm run test:coverage

# Python (if detected)
pylint .
mypy .
bandit -r .
safety check

# Git analysis
git log --stat
git diff --stat main
```

### Pattern Detection (Security)
```bash
# Dangerous patterns to grep for
grep -r "eval(" src/
grep -r "innerHTML" src/
grep -r "dangerouslySetInnerHTML" src/
grep -r "process.env" src/
grep -r "password" src/
grep -r "api_key" src/
grep -r "secret" src/
```

### File Reading Strategy
- Read files in batches (10-20 at a time) to stay within context
- Prioritize critical files first (auth, database, API routes)
- Use grep/glob to find problematic patterns before reading
- Focus detailed reading on files flagged by static analysis

## Success Criteria

The command is successful if:
1. All P0 (critical) issues are fixed
2. At least 80% of P1 (high) issues are fixed
3. All tests pass at the end
4. No new security vulnerabilities introduced
5. Code coverage maintained or improved
6. Build succeeds
7. Comprehensive report generated

## Edge Cases to Handle

1. **Project has no tests**: Skip test verification, rely on static analysis and manual validation
2. **Monorepo**: Ask user which package to review, or review all
3. **Multiple languages**: Detect and use appropriate tools for each
4. **Very large codebase (>100k LOC)**: Focus on high-impact areas first, limit deep analysis
5. **No package.json**: Detect language, adapt tool selection
6. **Custom build system**: Try to detect and use, or skip build verification

## Files to Create

1. **`~/.claude/commands/deepcodereview.md`** - Main command file (~600-800 lines)
2. Supporting documentation (optional): `~/.claude/docs/deepcodereview-guide.md`

## Estimated Command File Size
- Based on `/test` command (178 lines) and `/review` command patterns
- Estimated: 600-800 lines for comprehensive coverage
- Structure: 40% workflow phases, 30% examples and documentation, 30% technical implementation details

## Key Differentiators from /test Command

| Aspect | /test | /deepcodereview |
|--------|-------|-----------------|
| Duration | 10-30 minutes | 1-8 hours |
| Scope | E2E tests only | Security, quality, performance, tests, docs |
| Rounds | 1 test → fix → verify | 7+ rounds of focused improvements |
| Model switching | Once (to/from Sonnet 1M) | Multiple (Sonnet 1M ↔ Opus 4.5 ↔ Sonnet 4.5) |
| Commits | 0 (just fixes) | 1 per round + final report |
| Report depth | Summary | Comprehensive with metrics and recommendations |
| Autonomy | Fixes bugs found | Discovers, prioritizes, fixes, verifies, reports |

## User Decisions (Finalized)

1. **Time Limit Default**: ✅ No limit - runs until all issues are fixed
2. **Commit Strategy**: ✅ Per-round commits for easy rollback
3. **Breaking Changes**: ✅ Make changes with clear documentation (bold approach)
4. **Report Location**: ✅ Dedicated folder `.reviews/deepcodereview-[timestamp].md`
5. **Scope Defaults**: All categories (security, performance, quality, testing, docs)
6. **Branch Strategy**: Work on current branch with automatic backup branch created
7. **Integration with /test**: Run tests independently (not as subprocess)
8. **Progress Logging**: Write progress to `.reviews/progress.log` during execution

## Final Execution Flow Summary

1. **Autonomous Phase** (Runs for hours unattended)
   - Discovery → Planning → Fix ALL P0/P1/P2/P3 issues → Verify → Generate Reports
   - No user interaction needed
   - Creates per-round commits for safety

2. **User Interaction Phase** (At the very end)
   - Display user-friendly "vibe check" summary
   - Show what was fixed in plain English
   - Present deferred tasks (if any) via AskUserQuestion
   - Wait for user decisions on architectural choices
   - Implement user's choices
   - Final commit and restore model

3. **Key Difference from Original Plan**
   - ❌ OLD: Fix 80% of issues, stop for success
   - ✅ NEW: Fix 100% of autonomously-solvable issues (all P0/P1/P2/P3)
   - ❌ OLD: Technical report only
   - ✅ NEW: Technical report + user-friendly summary + end-of-run questions

## Final Implementation Plan

### File to Create
**`~/.claude/commands/deepcodereview.md`** (~700-900 lines)

### Command Structure

```markdown
---
name: deepcodereview
description: Autonomous multi-hour code review covering security, performance, quality, testing, and documentation
argument-hint: "[project-name] [--scope security|performance|quality|all]"
---

# Deep Code Review Command

Comprehensive autonomous code analysis and improvement system that runs for hours without intervention.

## Parameters
- `[project-name]` - Optional: "deep personality"/"dp", or path to project
- `--scope [area]` - Optional: Focus on specific area (security, performance, quality, all)
- Default: Current directory, all areas, no time limit

## Phase 1: Discovery & Analysis (15-30 min, Sonnet 1M)
[Detailed steps for codebase scanning, static analysis, manual analysis, test baseline]

## Phase 2: Strategic Planning (10-20 min, Opus 4.5)
[Detailed steps for issue prioritization, dependency analysis, round planning, risk assessment]

## Phase 3: Implementation Rounds (3-20 hours, alternating Sonnet 4.5 and 1M)
[Detailed steps for 7 rounds of fixes with per-round verification and commits]

## Phase 4: Final Verification (20-40 min, Sonnet 1M)
[Detailed steps for complete test suite, re-run static analysis, coverage check]

## Phase 5: Comprehensive Reporting (10-15 min, Sonnet 1M)
[Generate detailed markdown report in .reviews/ folder]

## Phase 6: Cleanup & Model Restoration (1-2 min)
[Create summary commit, switch back to opusplan]

## Safety Features
- Automatic backup branch: `backup/deepcodereview-[timestamp]`
- Per-round commits for easy rollback
- Test gates after each round
- Progress logging to `.reviews/progress.log`
- Automatic stop on critical test failures

## Examples
```bash
# Review current project
/deepcodereview

# Review specific project
/deepcodereview deep personality

# Focus on security only
/deepcodereview --scope security
```
```

### Key Implementation Details

1. **Model Management**
   - Start: Switch to Sonnet 1M for discovery
   - Planning: Switch to Opus 4.5 for strategic thinking
   - Fixing: Switch to Sonnet 4.5 for fast execution
   - Verification: Switch to Sonnet 1M for large context
   - End: Switch back to opusplan

2. **Progress Tracking**
   - Create `.reviews/` directory if not exists
   - Write progress to `.reviews/progress.log` with timestamps
   - Update log after each round completion
   - Include in final report

3. **Commit Messages**
   ```
   Round 1: Security - Fixed 5 critical vulnerabilities

   - SQL injection in user.ts:45
   - XSS vulnerability in profile.tsx:123
   - Hardcoded API key in config.ts:12
   - Authentication bypass in middleware.ts:67
   - CSRF missing on /api/admin routes

   🤖 Generated by /deepcodereview
   ```

4. **Breaking Changes Handling**
   - Make the change with confidence
   - Add detailed JSDoc/comments explaining the change
   - Document in report under "Breaking Changes" section
   - Add to commit message with "BREAKING:" prefix
   - Include migration guide in report

5. **Report Structure**
   ```
   .reviews/
   ├── deepcodereview-2026-01-04-14-30.md   # Main report
   ├── progress.log                          # Real-time progress
   └── backup-info.txt                       # Backup branch info
   ```

6. **Static Analysis Commands**
   ```bash
   # Detection phase
   test -f package.json && echo "node"
   test -f requirements.txt && echo "python"
   test -f go.mod && echo "go"

   # Node.js projects
   npm run lint 2>/dev/null || npx eslint . --ext .js,.jsx,.ts,.tsx
   npx tsc --noEmit 2>/dev/null
   npm audit --json
   npx depcheck --json

   # Python projects
   pylint src/ --output-format=json
   mypy src/ --json-report
   bandit -r src/ -f json
   safety check --json
   ```

7. **Security Pattern Detection**
   ```bash
   # High-risk patterns
   grep -rn "eval(" src/
   grep -rn "innerHTML" src/
   grep -rn "dangerouslySetInnerHTML" src/
   grep -rn "exec(" src/
   grep -rn "system(" src/

   # Secrets detection
   grep -rn "password\s*=" src/
   grep -rn "api_key\s*=" src/
   grep -rn "secret\s*=" src/
   grep -rn "token\s*=" src/

   # Insecure practices
   grep -rn "md5\|sha1" src/
   grep -rn "http://" src/
   grep -rn "disable.*ssl\|verify.*false" src/
   ```

8. **Round Structure Template**
   ```
   Round X: [Category] (Priority PY)
   ========================
   Switch to: [Model]
   Issues to fix: N
   Expected duration: X-Y min

   [For each issue]
     1. Mark in_progress
     2. Read files: [list]
     3. Analyze root cause
     4. Implement fix
     5. Mark completed
     6. Log to progress

   Verification:
     - Run [specific tests]
     - Check [specific metrics]
     - Verify no regressions

   Commit:
     - Add all changes
     - Commit with descriptive message
     - Update progress log
   ```

9. **Error Recovery Strategy**
   - If round fails verification: Revert round commit, analyze failure, retry with different approach
   - If critical tests break: Stop immediately, report state, keep all commits for review
   - If tool crashes: Log error, skip that tool, continue with remaining analysis
   - If out of memory: Switch to smaller model context, reduce batch sizes

10. **Final Report Template** (stored in `.reviews/`)
    - Executive summary with key metrics
    - Per-round detailed breakdown
    - Before/after comparisons (metrics table)
    - All files modified with brief descriptions
    - Breaking changes section (if any)
    - Remaining issues and future recommendations
    - Statistics (time, LOC analyzed, issues fixed/hour)

## Implementation Complexity

**Estimated Complexity**: High
- Multiple model switches with context management
- Complex state tracking across hours
- Robust error handling and recovery
- Integration with multiple external tools
- Comprehensive reporting system

**Development Time**: ~4-6 hours to write and test the command file

**Maintenance**: Medium - will need updates as new tools and best practices emerge

## Testing the Command

After implementation, test with:
1. Small project (~1000 LOC) - should complete in 30-60 min
2. Medium project (~10k LOC) - should complete in 2-4 hours
3. Large project (~50k+ LOC) - should complete in 4-8 hours
4. Project with critical security issues - verify P0 handling
5. Project with no issues - verify graceful completion

## Success Metrics

The command succeeds if:
- ✅ ALL P0/P1/P2/P3 issues that can be autonomously solved are fixed
- ✅ All tests pass at completion
- ✅ No new vulnerabilities introduced
- ✅ Comprehensive technical report generated in `.reviews/`
- ✅ User-friendly summary generated for "vibe coders"
- ✅ Per-round commits created for rollback safety
- ✅ Can run unattended for multiple hours
- ✅ Only pauses at end for user decisions on ambiguous tasks
- ✅ Model automatically restores to opusplan

## Updated Workflow: Fix Everything First, Ask Questions Later

### Autonomous Fix Criteria
**Fix immediately without user input:**
- Security vulnerabilities (P0)
- Bugs and errors (P1)
- Performance issues with clear solutions (P1-P2)
- Code quality improvements (P2)
- Dead code removal (P2)
- Documentation gaps (P3)
- Missing tests (P3)
- Style/formatting issues (P3)
- Type safety improvements (P2)
- Error handling gaps (P2)

**Defer to end-of-run questions:**
- Major architectural changes (e.g., switching state management libraries)
- Breaking API changes that affect external consumers
- Database schema migrations
- Dependency major version upgrades with breaking changes
- Features that require product/design decisions
- Changes that fundamentally alter user-facing behavior

### Phase 5 Updated: User-Friendly Summary + Questions

After all autonomous fixes are complete:

1. **Generate User-Friendly Summary**
   ```markdown
   # What I Did - The Vibe Check ✨

   ## TL;DR
   I spent [X hours] going through your code and fixed [Y] things. Your code is now:
   - ✅ More secure (fixed [N] security issues)
   - ✅ Faster (improved performance in [N] places)
   - ✅ Cleaner (removed [N] code smells)
   - ✅ Better tested (added [N] tests)
   - ✅ Better documented (added docs for [N] things)

   ## The Big Wins 🎯

   ### Security Stuff (The Scary Ones)
   - **SQL Injection**: Your database queries weren't safe. Someone could have stolen all your data. Fixed! 🔒
   - **API Keys**: You had API keys directly in the code. Moved them to environment variables where they belong.
   - [... other security fixes in plain English]

   ### Speed Improvements 🚀
   - **Database Queries**: You were asking the database the same question 100 times. Now you ask once. Page loads 10x faster.
   - **React Re-renders**: Your components were re-rendering way too much. Fixed the dependencies.
   - [... other performance fixes]

   ### Code Quality 🧹
   - **Removed Dead Code**: Found 500 lines of code that weren't being used. Deleted them.
   - **Simplified Complex Functions**: Broke down some gnarly functions into smaller, easier-to-understand pieces.
   - **Fixed TypeScript Issues**: No more "any" types everywhere. Your IDE will actually help you now.

   ### Testing 🧪
   - **Added Missing Tests**: [N] important functions didn't have tests. Now they do.
   - **Fixed Flaky Tests**: [N] tests that randomly failed are now reliable.

   ## What Changed? 📝

   Modified [N] files total:
   - `src/auth/login.ts` - Made authentication more secure
   - `src/components/Dashboard.tsx` - Performance improvements
   - `src/api/users.ts` - Better error handling
   [... all files with layman descriptions]

   ## Tests Still Pass? ✅

   Yep! Ran all [N] tests and they pass. Coverage went from [X]% to [Y]%.

   ## Breaking Changes? 🚨

   [If any breaking changes]
   - Changed the API for [function name] - you'll need to update calls to it
   - Migration guide: [simple steps]

   [If no breaking changes]
   Nope! Everything should work exactly the same, just better.

   ## Commits Made 📦

   I made [N] commits so you can easily review or rollback:
   - Round 1: Fixed critical security issues
   - Round 2: Fixed bugs
   - Round 3: Performance improvements
   - Round 4: Code quality improvements
   - Round 5: Added tests
   - Round 6: Documentation

   You can see each commit: `git log --oneline -[N]`
   Want to undo something? `git revert [commit-hash]`

   ## Time Spent ⏱️

   Total: [X hours Y minutes]
   - Analysis: [X min]
   - Fixing: [X hours]
   - Testing: [X min]
   - Reporting: [X min]

   Average: Fixed [X] issues per hour

   ## What's Next? 🤔

   Your code is in much better shape! Here's what I recommend:

   1. **Review the changes** - Look through the commits
   2. **Test manually** - Click through your app to make sure everything works
   3. **Deploy to staging** - Try it in a safe environment first
   4. **Run it for a while** - Let it bake before going to production

   Want me to explain anything in more detail? Just ask! 💬
   ```

2. **Collect Deferred Tasks**
   - Tasks that need architectural decisions
   - Tasks with multiple valid approaches
   - Tasks that affect user-facing behavior

3. **Use AskUserQuestion for Deferred Tasks**
   ```
   I found [N] tasks that need your input:

   Question 1: State Management Architecture
   I noticed you're using a mix of Redux and Context API. I could:
   - Option A: Consolidate everything to Redux (more consistent, better dev tools)
   - Option B: Consolidate to Context API (simpler, less boilerplate)
   - Option C: Keep the mix but document when to use which
   Which approach do you prefer?

   Question 2: API Breaking Change
   The `/api/users` endpoint has a security issue. To fix it properly, I'd need to change the response format. This would break any external consumers. Should I:
   - Option A: Make the breaking change with migration guide
   - Option B: Create a new endpoint /api/v2/users and deprecate the old one
   - Option C: Apply a less secure but backward-compatible fix
   ```

4. **After User Answers**
   - Implement the user's choices
   - Generate final addendum to report
   - Create final commit
   - Switch back to opusplan
