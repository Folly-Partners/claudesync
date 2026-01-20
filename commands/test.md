---
name: test
description: Run all e2e tests, identify and fix bugs automatically, then generate a bug report
argument-hint: "[project-name]"
---

# Test Command

Switch to Sonnet 1M context model, run all e2e tests, identify and fix bugs automatically, then generate a comprehensive bug report.

## Parameters

- If a project name is provided (e.g., `/test deep personality`), navigate to that project directory
- Otherwise, use the current working directory

## Workflow

### 1. Model Switch
Switch to Sonnet 1M for better test analysis:
```
/model sonnet[1m]
```

### 2. Project Detection
- If project name provided, map it to the correct path:
  - "deep personality" or "dp" → `~/Deep-Personality`
  - Otherwise try to find the project in common locations
- If no project specified, use current directory
- Verify the directory exists and contains a project

### 3. Test Discovery
Look for test configuration and scripts:
- Check `package.json` for test scripts (test:e2e, test, e2e, playwright)
- Look for `playwright.config.ts`, `jest.config.js`, `vitest.config.ts`
- Find test directories: `e2e/`, `tests/`, `__tests__/`, `spec/`
- Check for `TESTING.md` or similar documentation

### 4. Run Tests
- Run the appropriate e2e test command (usually `npm run test:e2e` or `npm test`)
- Capture full output including:
  - Test names and results
  - Error messages and stack traces
  - Screenshots or artifacts if available
  - Timing information

### 5. Bug Analysis
Create a TodoWrite list with all bugs found:
- Parse test failures and extract:
  - Test name and file location
  - Error message
  - Expected vs actual behavior
  - Stack trace showing the failing code
- For each bug, create a todo item with: "Fix: [test name] - [error summary]"

### 6. Bug Fixing (Automated)
For each bug in the todo list:
- Mark todo as in_progress
- Read the relevant source files
- Understand the root cause
- Implement the fix
- Mark todo as completed
- Continue to next bug

**Important**: Do NOT re-run tests between fixes. Fix all bugs first, then run tests once at the end.

### 7. Verification Run
After all fixes are complete:
- Run the test suite again
- Compare results with initial run
- Identify any remaining failures

### 8. Bug Report
Generate a comprehensive markdown report with:

```markdown
# Test Run Report - [Project Name]
**Date**: [timestamp]
**Model**: Sonnet 1M (claude-sonnet-4-5-20250929[1m])

## Summary
- Total tests run: X
- Initial failures: Y
- Bugs fixed: Z
- Final failures: W

## Initial Test Results
[Summary of first test run with failure count and key errors]

## Bugs Fixed
### Bug 1: [Test Name]
- **Location**: `file.ts:line`
- **Error**: [Error message]
- **Root Cause**: [Explanation]
- **Fix Applied**: [What was changed]

### Bug 2: [Test Name]
...

## Final Test Results
[Summary of verification run]

## Remaining Issues
[Any tests still failing, with analysis]

## Files Modified
- `path/to/file1.ts` - [Brief description]
- `path/to/file2.ts` - [Brief description]

## Recommendations
[Suggestions for preventing similar bugs, improving tests, etc.]
```

### 9. Model Restoration
Switch back to opusplan:
```
/model opusplan
```

## Example Usage

```bash
# Test current project
/test

# Test specific project
/test deep personality

# Test with project shorthand
/test dp
```

## Notes

- This command works autonomously - no user intervention required during bug fixing
- All bugs are documented before any fixes are applied
- Fixes are applied systematically, one at a time
- Final verification ensures fixes actually worked
- Report is comprehensive and suitable for documentation
