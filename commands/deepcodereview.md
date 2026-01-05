---
name: deepcodereview
description: Autonomous multi-hour code review covering security, performance, quality, testing, and documentation
argument-hint: "[project-name] [--scope security|performance|quality|all]"
---

# Deep Code Review Command

Comprehensive autonomous code analysis and improvement system that runs for hours or even a full day without user intervention. This command performs deep code review across security, performance, architecture, testing, and code quality, then systematically fixes ALL P0/P1/P2/P3 issues while continuously verifying its work.

**Key Features:**
- Fixes ALL issues autonomously (P0/P1/P2/P3) without interruption
- Only pauses at the end to ask about major architectural decisions
- Creates per-round commits for easy rollback
- Generates both technical and user-friendly "vibe check" reports
- Runs unattended for hours with continuous self-verification

## Parameters

- **`[project-name]`** - Optional project name or path:
  - `deep personality` or `dp` → `~/Deep-Personality`
  - Otherwise: use current directory
- **`--scope [area]`** - Optional focus area:
  - `security` - Only security vulnerabilities
  - `performance` - Only performance improvements
  - `quality` - Only code quality
  - `all` - Everything (default)
- **No time limit** - Runs until all autonomously-solvable issues are fixed

## Comprehensive Review Scope

### 1. Security Analysis (P0 - Critical)
- SQL injection, XSS, CSRF vulnerabilities
- Authentication/authorization flaws
- Sensitive data exposure (API keys, passwords)
- Insecure dependencies (npm audit)
- Command injection, path traversal
- Insecure cryptography
- OWASP Top 10 coverage

### 2. Code Quality (P2)
- Code smells and anti-patterns
- Dead code and unused imports
- Code duplication (DRY violations)
- Cyclomatic complexity
- Naming conventions
- Magic numbers

### 3. Performance (P1-P2)
- N+1 query problems
- Inefficient algorithms
- Memory leaks
- Unnecessary re-renders
- Missing database indexes
- Large bundle sizes

### 4. Architecture (P2)
- SOLID principles violations
- High coupling / low cohesion
- Inconsistent patterns
- Technical debt

### 5. Type Safety (P2)
- `any` type usage
- Missing type annotations
- Loose type definitions

### 6. Testing (P3)
- Missing unit/integration tests
- Flaky tests
- Inadequate coverage
- Missing edge cases

### 7. Documentation (P3)
- Missing JSDoc/docstrings
- Outdated comments
- Missing README sections

### 8. Accessibility (P2)
- Missing ARIA labels
- Keyboard navigation
- Color contrast

### 9. Error Handling (P2)
- Missing try-catch blocks
- Swallowed errors
- Missing validation

### 10. Best Practices (P3)
- ESLint violations
- Framework conventions
- Style inconsistencies

---

## Phase 1: Discovery & Analysis (15-30 min)

**Model: Switch to Sonnet 1M for large context analysis**

### 1.1 Environment Setup

```bash
# Switch model for large context
/model sonnet[1m]

# Detect project location
if [ project-name provided ]; then
  # Map project names
  if [ "deep personality" or "dp" ]; then
    cd ~/Deep-Personality
  else
    # Try to find project
    cd [project-path]
  fi
else
  # Use current directory
  pwd
fi

# Verify this is a valid project
test -f package.json || test -f requirements.txt || test -f go.mod
```

### 1.2 Create Safety Backup

```bash
# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# Create timestamped backup branch
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_BRANCH="backup/deepcodereview-$TIMESTAMP"

# Create backup
git checkout -b $BACKUP_BRANCH
git checkout $CURRENT_BRANCH

# Save backup info
mkdir -p .reviews
echo "Backup branch: $BACKUP_BRANCH" > .reviews/backup-info.txt
echo "Original branch: $CURRENT_BRANCH" >> .reviews/backup-info.txt
echo "Created: $(date)" >> .reviews/backup-info.txt
```

### 1.3 Detect Project Type

```bash
# Detect language and framework
if [ -f package.json ]; then
  PROJECT_TYPE="node"
  # Check for framework
  if grep -q "next" package.json; then FRAMEWORK="nextjs"
  elif grep -q "react" package.json; then FRAMEWORK="react"
  elif grep -q "vue" package.json; then FRAMEWORK="vue"
  fi
elif [ -f requirements.txt ] || [ -f pyproject.toml ]; then
  PROJECT_TYPE="python"
elif [ -f go.mod ]; then
  PROJECT_TYPE="go"
elif [ -f Cargo.toml ]; then
  PROJECT_TYPE="rust"
fi

# Find test framework
if [ -f playwright.config.ts ]; then TEST_FRAMEWORK="playwright"
elif [ -f jest.config.js ]; then TEST_FRAMEWORK="jest"
elif [ -f vitest.config.ts ]; then TEST_FRAMEWORK="vitest"
elif grep -q "pytest" requirements.txt 2>/dev/null; then TEST_FRAMEWORK="pytest"
fi
```

### 1.4 Run Static Analysis

```bash
# Initialize progress log
echo "=== Deep Code Review Started ===" > .reviews/progress.log
echo "Timestamp: $(date)" >> .reviews/progress.log
echo "Project Type: $PROJECT_TYPE" >> .reviews/progress.log
echo "" >> .reviews/progress.log

# Node.js/TypeScript projects
if [ "$PROJECT_TYPE" = "node" ]; then
  echo "Running ESLint..." >> .reviews/progress.log
  npm run lint 2>&1 | tee -a .reviews/progress.log ||
    npx eslint . --ext .js,.jsx,.ts,.tsx --format json > .reviews/eslint-results.json 2>&1

  echo "Running TypeScript check..." >> .reviews/progress.log
  npx tsc --noEmit 2>&1 | tee -a .reviews/progress.log

  echo "Running security audit..." >> .reviews/progress.log
  npm audit --json > .reviews/npm-audit.json 2>&1

  echo "Checking for unused dependencies..." >> .reviews/progress.log
  npx depcheck --json > .reviews/depcheck.json 2>&1
fi

# Python projects
if [ "$PROJECT_TYPE" = "python" ]; then
  echo "Running pylint..." >> .reviews/progress.log
  pylint src/ --output-format=json > .reviews/pylint.json 2>&1 || true

  echo "Running mypy..." >> .reviews/progress.log
  mypy src/ --json-report .reviews/ 2>&1 || true

  echo "Running bandit security scan..." >> .reviews/progress.log
  bandit -r src/ -f json -o .reviews/bandit.json 2>&1 || true

  echo "Checking dependencies with safety..." >> .reviews/progress.log
  safety check --json > .reviews/safety.json 2>&1 || true
fi
```

### 1.5 Manual Security Pattern Detection

```bash
echo "Scanning for security patterns..." >> .reviews/progress.log

# High-risk patterns (save results to files)
grep -rn "eval(" src/ 2>/dev/null > .reviews/patterns-eval.txt || true
grep -rn "innerHTML" src/ 2>/dev/null > .reviews/patterns-innerhtml.txt || true
grep -rn "dangerouslySetInnerHTML" src/ 2>/dev/null > .reviews/patterns-dangerous.txt || true
grep -rn "exec(" src/ 2>/dev/null > .reviews/patterns-exec.txt || true
grep -rn "system(" src/ 2>/dev/null > .reviews/patterns-system.txt || true

# Secrets detection
grep -rn "password\s*=" src/ 2>/dev/null > .reviews/patterns-password.txt || true
grep -rn "api_key\s*=" src/ 2>/dev/null > .reviews/patterns-apikey.txt || true
grep -rn "secret\s*=" src/ 2>/dev/null > .reviews/patterns-secret.txt || true
grep -rn "token\s*=" src/ 2>/dev/null > .reviews/patterns-token.txt || true

# Insecure practices
grep -rn "md5\|sha1" src/ 2>/dev/null > .reviews/patterns-weak-crypto.txt || true
grep -rn "http://" src/ 2>/dev/null > .reviews/patterns-http.txt || true
grep -rn "disable.*ssl\|verify.*false" src/ 2>/dev/null > .reviews/patterns-no-ssl.txt || true
```

### 1.6 Baseline Test Run

```bash
echo "Running baseline tests..." >> .reviews/progress.log

# Run tests based on framework
if [ "$TEST_FRAMEWORK" = "playwright" ]; then
  npm run test:e2e 2>&1 | tee .reviews/baseline-tests.txt
elif [ "$TEST_FRAMEWORK" = "jest" ]; then
  npm test -- --coverage --json > .reviews/baseline-tests.json 2>&1
elif [ "$TEST_FRAMEWORK" = "vitest" ]; then
  npm run test -- --coverage --json > .reviews/baseline-tests.json 2>&1
elif [ "$TEST_FRAMEWORK" = "pytest" ]; then
  pytest --json-report --json-report-file=.reviews/baseline-tests.json 2>&1
else
  # Try common test commands
  npm test 2>&1 | tee .reviews/baseline-tests.txt || true
fi

# Get coverage if available
if [ -f package.json ] && grep -q "test:coverage" package.json; then
  npm run test:coverage 2>&1 | tee .reviews/baseline-coverage.txt || true
fi
```

### 1.7 Codebase Metrics

```bash
echo "Collecting codebase metrics..." >> .reviews/progress.log

# Count files and lines
find src/ -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" \) 2>/dev/null | wc -l > .reviews/file-count.txt
find src/ -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" \) -exec wc -l {} + 2>/dev/null | tail -1 > .reviews/line-count.txt

# Find complex functions (>50 lines)
# This will be done during code reading phase
```

### 1.8 Parse Results & Create TODO List

**Create comprehensive TodoWrite list with ALL issues found:**

Parse all the static analysis results, grep outputs, and test results. For each issue found:
- Categorize by priority (P0/P1/P2/P3)
- Categorize by type (security, performance, quality, testing, docs)
- Extract file location and line number
- Create descriptive todo item

**Todo format:**
- Content: "[P0/P1/P2/P3] [Category] Fix [issue] in [file]:[line] - [brief description]"
- Status: "pending"
- ActiveForm: "Fixing [brief description]"

**Important:** Create separate todos for deferred tasks that need user decisions:
- Mark as "[DEFERRED]" in the content
- These will be asked about at the end via AskUserQuestion
- Examples: "Switch to Redux", "Migrate database schema", "Major version upgrade"

---

## Phase 2: Strategic Planning (10-20 min)

**Model: Switch to Opus 4.5 for strategic reasoning**

```bash
# Switch to Opus for planning
/model opus
```

### 2.1 Analyze All Issues

Review the comprehensive TODO list created in Phase 1. Group issues by:
- Priority level (P0 → P1 → P2 → P3)
- Category (security, bugs, performance, quality, architecture, testing, docs)
- Dependencies (which issues must be fixed first)

### 2.2 Identify Deferred Tasks

Scan through all issues and identify those that need user decisions:

**Defer these types of issues:**
- Major architectural changes (switching state management libraries)
- Breaking API changes affecting external consumers
- Database schema migrations
- Dependency major version upgrades with breaking changes
- Product/design decisions
- Changes fundamentally altering user-facing behavior

**Fix these autonomously:**
- Everything else (security, bugs, performance, quality, testing, docs)

### 2.3 Create Round Plan

Organize autonomous fixes into 8 rounds:

1. **Round 1: P0 Security** - Critical vulnerabilities, data exposure risks
2. **Round 2: P1 Bugs** - Crashes, errors, broken functionality
3. **Round 3: P1 Performance** - N+1 queries, memory leaks, blocking operations
4. **Round 4: P2 Code Quality** - Dead code, duplication, complexity, type safety
5. **Round 5: P2 Architecture** - Refactoring, better patterns, SOLID principles
6. **Round 6: P3 Testing** - Add missing tests, fix flaky tests, improve coverage
7. **Round 7: P3 Documentation** - JSDoc, README, inline comments
8. **Round 8: P3 Final Polish** - Formatting, style, minor optimizations

### 2.4 Risk Assessment

For each round, identify:
- High-risk changes that need extra care
- Rollback strategy (we have per-round commits)
- Expected duration for planning purposes

### 2.5 Log Planning Results

```bash
echo "" >> .reviews/progress.log
echo "=== Planning Complete ===" >> .reviews/progress.log
echo "Total issues found: [N]" >> .reviews/progress.log
echo "Autonomous fixes: [N]" >> .reviews/progress.log
echo "Deferred for user input: [N]" >> .reviews/progress.log
echo "Estimated rounds: 8" >> .reviews/progress.log
echo "" >> .reviews/progress.log
```

---

## Phase 3: Implementation Rounds (3-20 hours)

**Models: Alternate between Sonnet 4.5 (fixing) and Sonnet 1M (verification)**

For each round (1 through 8):

### 3.1 Start Round

```bash
echo "=== Round [X]: [Category] Started ===" >> .reviews/progress.log
echo "Timestamp: $(date)" >> .reviews/progress.log
echo "Issues to fix: [N]" >> .reviews/progress.log

# Switch to Sonnet 4.5 for fast execution
/model sonnet
```

### 3.2 Fix Loop

For each issue in the current round's TODO list:

1. **Mark todo as in_progress**
   - Update TodoWrite with current issue status

2. **Read affected files**
   - Use Read tool to examine the files mentioned in the issue
   - Understand the context and root cause

3. **Analyze root cause**
   - Determine why the issue exists
   - Consider the best fix approach
   - Ensure fix won't introduce new issues

4. **Implement fix**
   - Use Edit or Write tool to apply the fix
   - Follow best practices for the project
   - Add inline comments if the fix is complex
   - For breaking changes: add detailed JSDoc explaining the change

5. **Mark todo as completed**
   - Update TodoWrite to mark issue as done
   - Log the fix to progress buffer

6. **Log to progress**
   ```bash
   echo "  - Fixed: [brief description] in [file]:[line]" >> .reviews/progress.log
   ```

**Important:** Do NOT run tests between individual fixes. Fix all issues in the round first.

### 3.3 Round Verification

```bash
echo "Round [X] fixes complete. Verifying..." >> .reviews/progress.log

# Switch to Sonnet 1M for large context verification
/model sonnet[1m]
```

**Run appropriate tests for the round:**

- **Security Round**: Run full test suite + re-run npm audit/bandit
- **Bug Round**: Run all tests, check for new errors
- **Performance Round**: Run tests + measure improvements (bundle size, build time)
- **Quality Round**: Run tests + re-run linters
- **Architecture Round**: Run full test suite (behavior shouldn't change)
- **Testing Round**: Run new tests to verify they work
- **Documentation Round**: No tests needed (verify docs build if applicable)
- **Polish Round**: Run linters to verify formatting

```bash
# Example verification for most rounds
if [ "$PROJECT_TYPE" = "node" ]; then
  npm test 2>&1 | tee .reviews/round-[X]-tests.txt
fi

# Check if tests passed
if [ $? -eq 0 ]; then
  echo "✅ Round [X] verification PASSED" >> .reviews/progress.log
else
  echo "❌ Round [X] verification FAILED" >> .reviews/progress.log
  echo "Stopping for review..." >> .reviews/progress.log
  # Stop and report to user
  exit 1
fi
```

### 3.4 Commit Round Changes

```bash
# Stage all changes
git add -A

# Create descriptive commit message
git commit -m "Round [X]: [Category] - Fixed [N] issues

$(cat <<'EOF'
[List each issue fixed in this round with brief description]
- Fixed [issue 1] in [file]
- Fixed [issue 2] in [file]
- Fixed [issue 3] in [file]
...

🤖 Generated by /deepcodereview
EOF
)"

echo "Round [X] committed: $(git rev-parse --short HEAD)" >> .reviews/progress.log
echo "" >> .reviews/progress.log
```

### 3.5 Progress Update

After every 2-3 rounds, write an intermediate summary:

```bash
# Every 3 rounds
if [ $(($ROUND_NUM % 3)) -eq 0 ]; then
  echo "=== Progress Check (After Round [X]) ===" >> .reviews/progress.log
  echo "Rounds completed: [X]/8" >> .reviews/progress.log
  echo "Issues fixed so far: [N]" >> .reviews/progress.log
  echo "Issues remaining: [N]" >> .reviews/progress.log
  echo "Time elapsed: [X hours Y minutes]" >> .reviews/progress.log

  # Run full test suite as sanity check
  npm test 2>&1 | tee .reviews/progress-check-round-[X].txt

  if [ $? -ne 0 ]; then
    echo "❌ CRITICAL: Tests failing at progress check" >> .reviews/progress.log
    echo "Stopping for review..." >> .reviews/progress.log
    exit 1
  fi
  echo "" >> .reviews/progress.log
fi
```

### 3.6 Repeat for All Rounds

Continue this process for all 8 rounds, fixing ALL P0/P1/P2/P3 issues autonomously.

---

## Phase 4: Final Verification (20-40 min)

**Model: Switch to Sonnet 1M for comprehensive analysis**

```bash
echo "=== Final Verification Started ===" >> .reviews/progress.log
echo "Timestamp: $(date)" >> .reviews/progress.log

# Switch to Sonnet 1M
/model sonnet[1m]
```

### 4.1 Complete Test Suite

```bash
echo "Running complete test suite..." >> .reviews/progress.log

if [ "$PROJECT_TYPE" = "node" ]; then
  # Run all test types
  npm test 2>&1 | tee .reviews/final-tests.txt

  # E2E tests if they exist
  if grep -q "test:e2e" package.json; then
    npm run test:e2e 2>&1 | tee .reviews/final-e2e.txt
  fi

  # Integration tests if they exist
  if grep -q "test:integration" package.json; then
    npm run test:integration 2>&1 | tee .reviews/final-integration.txt
  fi
fi
```

### 4.2 Re-run All Static Analysis

```bash
echo "Re-running static analysis..." >> .reviews/progress.log

if [ "$PROJECT_TYPE" = "node" ]; then
  npm run lint 2>&1 | tee .reviews/final-lint.txt
  npx tsc --noEmit 2>&1 | tee .reviews/final-tsc.txt
  npm audit --json > .reviews/final-audit.json
  npx depcheck --json > .reviews/final-depcheck.json
fi

# Compare before/after
echo "Comparing metrics:" >> .reviews/progress.log
# Compare .reviews/*-results.json with .reviews/final-*.json
```

### 4.3 Code Coverage Check

```bash
if [ -f package.json ] && grep -q "test:coverage" package.json; then
  npm run test:coverage 2>&1 | tee .reviews/final-coverage.txt

  # Extract coverage percentage
  # Compare with baseline coverage
  echo "Coverage change: [baseline]% → [final]%" >> .reviews/progress.log
fi
```

### 4.4 Performance Benchmarks

```bash
# Bundle size (if applicable)
if [ "$PROJECT_TYPE" = "node" ]; then
  npm run build 2>&1 | tee .reviews/final-build.txt

  # Measure build output size
  if [ -d dist ] || [ -d build ] || [ -d .next ]; then
    du -sh dist build .next 2>/dev/null | tee -a .reviews/progress.log
  fi
fi
```

### 4.5 Final Security Scan

```bash
echo "Final security scan..." >> .reviews/progress.log

# Re-run pattern detection
grep -rn "eval(" src/ 2>/dev/null | wc -l | tee -a .reviews/progress.log
grep -rn "innerHTML" src/ 2>/dev/null | wc -l | tee -a .reviews/progress.log
# ... other patterns

# Should all be 0 or minimal
```

### 4.6 Verify No Debugging Code

```bash
# Check for console.log, debugger, etc.
grep -rn "console.log\|debugger\|TODO\|FIXME" src/ 2>/dev/null > .reviews/final-cleanup-needed.txt || true

# If found, clean them up quickly
```

---

## Phase 5: User-Friendly Summary & Questions (15-30 min)

**Model: Stay on Sonnet 1M for report generation**

### 5.1 Generate Technical Report

Create comprehensive technical report in `.reviews/deepcodereview-[timestamp].md` with:
- Executive summary
- All rounds detailed
- Files modified
- Metrics before/after
- Test results
- Performance improvements
- Breaking changes (if any)
- Statistics

### 5.2 Generate User-Friendly "Vibe Check" Summary

Display this immediately to the user:

```markdown
# What I Did - The Vibe Check ✨

## TL;DR
I spent [X hours Y minutes] going through your code and fixed [Y] things. Your code is now:
- ✅ More secure (fixed [N] security issues)
- ✅ Faster (improved performance in [N] places)
- ✅ Cleaner (removed [N] code smells)
- ✅ Better tested (added [N] tests)
- ✅ Better documented (added docs for [N] things)

## The Big Wins 🎯

### Security Stuff (The Scary Ones)
[Explain each security fix in plain English - what was wrong, what could have happened, how it's fixed]

Example:
- **SQL Injection**: Your database queries weren't safe. Someone could have typed special characters and seen all your user data or deleted everything. Fixed by using parameterized queries! 🔒
- **API Keys in Code**: You had your API key written directly in the code. Anyone who sees your code could use your account. Moved it to environment variables where it's safe. 🔐

### Speed Improvements 🚀
[Explain performance fixes in terms of user experience]

Example:
- **Database Queries**: You were asking the database the same question 100 times in a row. Now you ask once and cache the answer. Page loads 10x faster! ⚡
- **React Re-renders**: Your components were re-rendering every time anything changed, even unrelated stuff. Fixed the dependencies. App feels snappier now. 🎨

### Code Quality 🧹
[Explain quality improvements in terms of future developer experience]

Example:
- **Removed Dead Code**: Found 500 lines of code that wasn't being used anymore. Deleted it. Less code to maintain = less confusion. 🗑️
- **Fixed TypeScript Issues**: Replaced 47 "any" types with proper types. Your IDE will now actually help you instead of saying "🤷 whatever dude". 📝
- **Simplified Complex Functions**: Broke down some giant functions into smaller, easier-to-understand pieces. Future you will thank me. 🙏

### Testing 🧪
[Explain testing improvements in terms of confidence]

Example:
- **Added Missing Tests**: [N] important functions didn't have tests. If you broke them, you wouldn't know until production. Now you'll know immediately. ✅
- **Fixed Flaky Tests**: [N] tests that randomly failed sometimes. Super annoying. They're reliable now. 🎯

## What Changed? 📝

Modified [N] files total:

**Security & Critical:**
- `src/auth/login.ts` - Made authentication super secure (fixed 2 vulnerabilities)
- `src/db/query.ts` - All database queries now use safe parameterized queries
- `config/env.ts` - Moved API keys to environment variables

**Performance:**
- `src/components/Dashboard.tsx` - Optimized re-renders, loads way faster
- `src/api/users.ts` - Fixed N+1 query problem, cut database calls by 95%

**Code Quality:**
- `src/utils/validation.ts` - Added proper error handling everywhere
- `src/types/*.ts` - Replaced loose types with strict types
- Deleted [N] unused files

**Testing:**
- `tests/auth.test.ts` - Added comprehensive auth tests
- `tests/api.test.ts` - Added API endpoint tests

**Documentation:**
- `README.md` - Updated setup instructions
- Added JSDoc comments to [N] public functions

## Tests Still Pass? ✅

Yep! All [N] tests pass. Coverage went from [X]% to [Y]%.

**Before:** [X] tests, [Y] passing ([Z]%)
**After:** [X+A] tests (added [A] new ones), [Y+B] passing (100%)

## Breaking Changes? 🚨

[If breaking changes exist:]
**Yes, there are [N] breaking changes:**

1. **[Function/API name]** - Changed from X to Y
   - **Why**: The old way had a security issue / was confusing / didn't scale
   - **Migration**: Change `oldFunction(a, b)` to `newFunction({a, b})`
   - **Example**: See `examples/migration.md`

[If no breaking changes:]
**Nope!** Everything works exactly the same, just better under the hood. 🎉

## Commits Made 📦

I made [N] commits so you can easily review or rollback any round:

- **Round 1**: Fixed [X] critical security issues
- **Round 2**: Fixed [X] bugs
- **Round 3**: Performance improvements ([X] issues)
- **Round 4**: Code quality improvements ([X] issues)
- **Round 5**: Architecture refactoring ([X] improvements)
- **Round 6**: Added [X] tests
- **Round 7**: Documentation ([X] additions)
- **Round 8**: Final polish

**Review commits:** `git log --oneline -[N]`
**Undo a specific round:** `git revert [commit-hash]`
**Undo everything:** `git reset --hard [backup-branch]` (your backup: `[backup-branch-name]`)

## Time Spent ⏱️

**Total Time:** [X hours Y minutes]
- Discovery & Analysis: [X] min
- Planning: [X] min
- Fixing: [X] hours [Y] min
- Testing & Verification: [X] min
- Report generation: [X] min

**Productivity:** Fixed [X] issues per hour on average

## What's Next? 🤔

Your code is in much better shape! Here's what I recommend:

1. **Quick Review** - Skim through the commits to see what changed
2. **Manual Testing** - Click through your app to make sure everything works as expected
3. **Review the Technical Report** - Detailed analysis at `.reviews/deepcodereview-[timestamp].md`
4. **Deploy to Staging** - Test in a safe environment before production
5. **Monitor** - Keep an eye on it for a day or two before going to production

**Want me to explain anything in more detail?** Just ask! 💬

---

## Technical Report 📊

For the detailed technical breakdown, see: `.reviews/deepcodereview-[timestamp].md`

This includes:
- Exact code references for every fix
- Before/after metrics
- Security vulnerability details
- Performance measurements
- Complete test results
- Breaking changes migration guide
```

### 5.3 Collect Deferred Tasks

Review the TODO list for any `[DEFERRED]` items that need user decisions.

If deferred tasks exist:

```
I found [N] tasks that need your input on major architectural decisions:
```

### 5.4 Ask Questions for Deferred Tasks

Use AskUserQuestion to present each deferred task as a multiple-choice question:

**Question format:**
- Clear explanation of the issue
- 2-4 options with pros/cons for each
- Recommendation if one approach is clearly better

**Example questions:**

```
Question 1: State Management Consistency
I noticed you're using both Redux and Context API for state management. This creates confusion about when to use which. What would you like to do?

Options:
- Consolidate to Redux (Recommended for this project)
  * Pros: Better dev tools, more predictable, scales well
  * Cons: More boilerplate
- Consolidate to Context API
  * Pros: Simpler, less code
  * Cons: Can be harder to debug, doesn't scale as well
- Keep both but add documentation
  * Pros: No code changes needed
  * Cons: Confusion continues
```

```
Question 2: API Breaking Change for Security
The `/api/users` endpoint has a critical security issue where it exposes user emails to non-admin users. To fix it properly, I need to change the response format. What should I do?

Options:
- Make the breaking change with migration guide (Recommended)
  * Pros: Fixes security issue completely
  * Cons: External API consumers need to update
- Create `/api/v2/users` and deprecate old endpoint
  * Pros: Backward compatible
  * Cons: Need to maintain two endpoints
- Apply partial fix (filter sensitive fields)
  * Pros: No breaking change
  * Cons: Doesn't fully solve the architecture issue
```

### 5.5 Implement User Choices

After user responds to questions:

1. Switch back to Sonnet 4.5
2. Implement each user-selected option
3. Test the changes
4. Create a final commit:

```bash
git add -A
git commit -m "feat: Implement user-selected improvements

Based on user decisions:
- [Decision 1]: [What was implemented]
- [Decision 2]: [What was implemented]

🤖 Generated by /deepcodereview"
```

### 5.6 Generate Final Report Addendum

Add a section to the technical report:

```markdown
## User-Directed Improvements

After autonomous fixes were complete, the user made the following decisions:

### [Task 1 Name]
**Decision:** [Option selected]
**Implementation:** [What was done]
**Files Modified:** [List]
**Rationale:** [Why this option was chosen]

### [Task 2 Name]
...
```

---

## Phase 6: Cleanup & Model Restoration (1-2 min)

### 6.1 Final Commit

```bash
# Add the technical report
git add .reviews/

# Create documentation commit
git commit -m "docs: Add deep code review report and logs

Comprehensive deep code review completed.
- Fixed [N] issues across [M] files
- [X] security vulnerabilities resolved
- [Y] performance improvements
- [Z] code quality enhancements
- Test coverage: [A]% → [B]%

Full report: .reviews/deepcodereview-[timestamp].md

🤖 Generated by /deepcodereview"
```

### 6.2 Display Summary

Show the user:
```
✅ Deep Code Review Complete!

**Summary:**
- Time: [X] hours [Y] minutes
- Issues Fixed: [N] ([P0], [P1], [P2], [P3])
- Commits Created: [N]
- Tests: All passing ✅
- Coverage: [X]% → [Y]%

**Reports:**
- User-Friendly: See above ☝️
- Technical Details: .reviews/deepcodereview-[timestamp].md
- Progress Log: .reviews/progress.log

**Backup:**
If you need to rollback: `git reset --hard [backup-branch]`
Backup branch: [backup-branch-name]

**Next Steps:**
1. Review the changes
2. Test manually
3. Deploy to staging
4. Monitor for issues
```

### 6.3 Restore Model

```bash
# Switch back to opusplan
/model opusplan
```

### 6.4 Final Verification Message

```
Model restored to opusplan.

Your code is now significantly improved! All autonomous fixes have been applied,
and any architectural decisions have been implemented based on your input.

The command ran for [X] hours and fixed [N] issues without interruption.
All changes are committed with detailed messages for easy review.

Happy coding! 🚀
```

---

## Safety Features

### Automatic Safeguards

1. **Git Status Check**
   - Verify clean working directory before starting
   - If uncommitted changes exist, ask user to commit or stash first

2. **Backup Branch**
   - Automatic `backup/deepcodereview-[timestamp]` branch creation
   - Saved to `.reviews/backup-info.txt`
   - Easy rollback: `git reset --hard [backup-branch]`

3. **Incremental Commits**
   - One commit per round (8 total)
   - Detailed commit messages listing all fixes
   - Easy to revert specific rounds: `git revert [commit-hash]`

4. **Test Gates**
   - Tests run after EVERY round
   - If tests fail: stop immediately, report state
   - Progress checks every 3 rounds with full test suite

5. **Change Limits**
   - Stop if attempting to modify >1000 files (likely a mistake)
   - Warn if modifying >100 files (verify this is expected)

6. **Progress Logging**
   - Real-time log at `.reviews/progress.log`
   - Timestamped entries for every action
   - Easy to monitor long-running sessions

### Error Handling

**If Round Fails Verification:**
```bash
echo "❌ Round [X] verification FAILED" >> .reviews/progress.log
echo "Reverting round [X] commit..." >> .reviews/progress.log
git revert HEAD --no-edit
echo "Round [X] reverted. Analyzing failure..." >> .reviews/progress.log
# Analyze what went wrong, try different approach
# If can't fix: mark todos as failed, continue to next round
```

**If Critical Tests Break:**
```bash
echo "🚨 CRITICAL: Tests failing" >> .reviews/progress.log
echo "Stopping for user review..." >> .reviews/progress.log
# Display current state
# Show which commit broke tests
# Suggest: git revert [commit] or git reset --hard [backup]
exit 1
```

**If Static Analysis Tool Crashes:**
```bash
echo "⚠️  Tool [name] crashed, skipping..." >> .reviews/progress.log
# Continue with other tools
# Note in report that this tool was skipped
```

**If Out of Memory:**
```bash
# Switch to smaller context model
/model sonnet  # instead of sonnet[1m]
# Reduce batch sizes
# Process files in smaller chunks
```

### Verification Points

- **After every round:** Run relevant test suite
- **Every 3 rounds:** Run complete test suite (sanity check)
- **Before final report:** Complete verification pass
- **After user decisions:** Test the implemented choices

---

## Examples

### Basic Usage

```bash
# Review current project (runs until complete)
/deepcodereview

# This will:
# 1. Analyze the codebase (15-30 min)
# 2. Plan the fixes (10-20 min)
# 3. Fix ALL issues in 8 rounds (3-20 hours)
# 4. Verify everything works (20-40 min)
# 5. Show you a friendly summary
# 6. Ask about any big architectural decisions
```

### Review Specific Project

```bash
# Review Deep Personality project
/deepcodereview deep personality

# or
/deepcodereview dp

# This will:
# - cd ~/Deep-Personality
# - Run the full deep code review
# - Fix all autonomous issues
# - Report back when done
```

### Focus on Security Only

```bash
# Only security issues
/deepcodereview --scope security

# This will:
# - Only analyze and fix security vulnerabilities
# - Skip performance, quality, testing, docs
# - Still runs unattended until complete
```

### Focus on Performance

```bash
# Only performance improvements
/deepcodereview --scope performance

# This will:
# - Only analyze and fix performance issues
# - Skip security, quality, testing, docs (unless they affect performance)
```

### Review Specific Project with Scope

```bash
# Security review of Deep Personality
/deepcodereview deep personality --scope security
```

---

## Notes

### Time Expectations

- **Small project (~1,000 LOC):** 30-60 minutes
- **Medium project (~10,000 LOC):** 2-4 hours
- **Large project (~50,000 LOC):** 4-8 hours
- **Very large project (>100,000 LOC):** 8+ hours

### What Gets Fixed Autonomously

**YES - Fixed automatically:**
- ✅ All security vulnerabilities
- ✅ All bugs and errors
- ✅ All performance issues with clear fixes
- ✅ Code quality improvements
- ✅ Dead code removal
- ✅ Type safety improvements
- ✅ Missing tests
- ✅ Documentation gaps
- ✅ Style/formatting issues
- ✅ Breaking changes (with detailed docs)

**NO - Deferred to end-of-run questions:**
- ❓ Major architectural changes
- ❓ Database schema migrations
- ❓ Switching state management libraries
- ❓ Major dependency upgrades with breaking changes
- ❓ Product/design decisions

### Model Usage

- **Sonnet 1M:** Discovery (large codebase), verification (large test outputs)
- **Opus 4.5:** Strategic planning, prioritization
- **Sonnet 4.5:** Implementation (fast, efficient for code generation)
- **Returns to:** opusplan (automatic Opus/Sonnet selection)

### Rollback Strategy

If something goes wrong:

```bash
# Undo last round only
git revert HEAD

# Undo last N commits
git revert HEAD~[N]..HEAD

# Nuclear option: undo everything
git reset --hard [backup-branch]
```

Backup branch name is in `.reviews/backup-info.txt`

### Progress Monitoring

For long-running sessions, check progress:

```bash
# In another terminal
tail -f .reviews/progress.log

# Or check the latest status
tail -20 .reviews/progress.log
```

### Re-running After Failure

If the command stops due to an error, you can:

1. Fix the issue manually
2. Commit the fix
3. Run `/deepcodereview` again - it will continue from where it left off

### No Tests?

If your project doesn't have tests:
- Security fixes: Manually verified against test payloads
- Other fixes: Verified via static analysis
- Report will note: "No tests found, verification was manual"

### Monorepos

If detected:
- Will ask which package to review
- Or offer to review all packages sequentially

---

## Success Criteria

The command succeeds when:

- ✅ ALL P0/P1/P2/P3 issues autonomously solvable are fixed
- ✅ All tests pass at completion
- ✅ No new security vulnerabilities introduced
- ✅ Code coverage maintained or improved
- ✅ Build succeeds
- ✅ Technical report generated in `.reviews/`
- ✅ User-friendly summary displayed
- ✅ Per-round commits created for safety
- ✅ Ran unattended for hours without user intervention
- ✅ Only paused at end for user decisions on architectural tasks
- ✅ Model restored to opusplan

---

**Ready to transform your codebase? Just run `/deepcodereview` and let it work! 🚀**
