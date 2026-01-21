#!/bin/bash
# Stop hook: Don't let Claude finish while things are broken
# Checks: tests pass, typecheck passes, no TODO markers in changed files

set -e

# Get the current working directory from environment or use PWD
WORK_DIR="${CLAUDE_WORKING_DIRECTORY:-$PWD}"
cd "$WORK_DIR" 2>/dev/null || {
    echo '{"decision": "approve", "reason": "Not in a valid directory"}'
    exit 0
}

# Track failures
FAILURES=()
WARNINGS=()

# ============================================================================
# Helper: Check if we're in a git repo
# ============================================================================
is_git_repo() {
    git rev-parse --git-dir > /dev/null 2>&1
}

# ============================================================================
# Helper: Get changed files (staged + unstaged + untracked)
# ============================================================================
get_changed_files() {
    if is_git_repo; then
        # Get staged, modified, and untracked files
        git diff --name-only HEAD 2>/dev/null || true
        git diff --name-only --cached 2>/dev/null || true
        git ls-files --others --exclude-standard 2>/dev/null || true
    fi
}

# ============================================================================
# Check 1: TODO markers in changed files
# ============================================================================
check_todos() {
    if ! is_git_repo; then
        return 0
    fi

    local changed_files=$(get_changed_files | sort -u)
    if [ -z "$changed_files" ]; then
        return 0
    fi

    local todo_files=""
    while IFS= read -r file; do
        if [ -f "$file" ] && grep -l -E '(TODO|FIXME|XXX|HACK):?\s' "$file" 2>/dev/null; then
            todo_files="$todo_files $file"
        fi
    done <<< "$changed_files"

    if [ -n "$todo_files" ]; then
        FAILURES+=("TODO/FIXME markers found in changed files:$todo_files")
    fi
}

# ============================================================================
# Check 2: TypeScript/JavaScript typecheck
# ============================================================================
check_typescript() {
    # Check for TypeScript config
    if [ -f "tsconfig.json" ]; then
        if [ -f "node_modules/.bin/tsc" ]; then
            if ! node_modules/.bin/tsc --noEmit 2>&1; then
                FAILURES+=("TypeScript typecheck failed")
            fi
        elif command -v tsc &> /dev/null; then
            if ! tsc --noEmit 2>&1; then
                FAILURES+=("TypeScript typecheck failed")
            fi
        else
            WARNINGS+=("tsconfig.json found but tsc not available")
        fi
    fi
}

# ============================================================================
# Check 3: Python type checking (if mypy/pyright available)
# ============================================================================
check_python_types() {
    # Check for Python type configs
    if [ -f "pyproject.toml" ] || [ -f "mypy.ini" ] || [ -f ".mypy.ini" ]; then
        if command -v mypy &> /dev/null; then
            if ! mypy . --ignore-missing-imports 2>&1 | grep -q "Success"; then
                # mypy found issues, but don't fail - just warn
                WARNINGS+=("mypy reported type issues")
            fi
        fi
    fi
}

# ============================================================================
# Check 4: Run tests
# ============================================================================
check_tests() {
    local test_ran=false

    # Node.js projects
    if [ -f "package.json" ]; then
        # Check if test script exists and isn't just "echo 'Error: no test'"
        local test_script=$(jq -r '.scripts.test // empty' package.json 2>/dev/null)
        if [ -n "$test_script" ] && ! echo "$test_script" | grep -q "no test"; then
            if [ -f "node_modules/.bin/jest" ] || [ -f "node_modules/.bin/vitest" ] || [ -f "node_modules/.bin/mocha" ]; then
                if ! npm test 2>&1; then
                    FAILURES+=("npm test failed")
                fi
                test_ran=true
            fi
        fi
    fi

    # Python projects
    if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || [ -d "tests" ] && [ -f "requirements.txt" ]; then
        if command -v pytest &> /dev/null; then
            if ! pytest --tb=short 2>&1; then
                FAILURES+=("pytest failed")
            fi
            test_ran=true
        fi
    fi

    # Ruby projects
    if [ -f "Gemfile" ]; then
        if [ -f "Rakefile" ] && grep -q "test" Rakefile 2>/dev/null; then
            if command -v bundle &> /dev/null; then
                if ! bundle exec rake test 2>&1; then
                    FAILURES+=("rake test failed")
                fi
                test_ran=true
            fi
        fi
    fi

    # Go projects
    if [ -f "go.mod" ]; then
        if command -v go &> /dev/null; then
            if ! go test ./... 2>&1; then
                FAILURES+=("go test failed")
            fi
            test_ran=true
        fi
    fi

    # Rust projects
    if [ -f "Cargo.toml" ]; then
        if command -v cargo &> /dev/null; then
            if ! cargo test 2>&1; then
                FAILURES+=("cargo test failed")
            fi
            test_ran=true
        fi
    fi
}

# ============================================================================
# Main execution
# ============================================================================

# Run all checks
check_todos
check_typescript
check_python_types
check_tests

# Build response
if [ ${#FAILURES[@]} -gt 0 ]; then
    # Join failures into a single message
    REASON=$(printf '%s; ' "${FAILURES[@]}")
    # Remove trailing semicolon and space
    REASON=${REASON%; }
    echo "{\"decision\": \"block\", \"reason\": \"Cannot finish: $REASON\"}"
    exit 0
fi

if [ ${#WARNINGS[@]} -gt 0 ]; then
    REASON=$(printf '%s; ' "${WARNINGS[@]}")
    REASON=${REASON%; }
    echo "{\"decision\": \"approve\", \"reason\": \"Warnings: $REASON\"}"
    exit 0
fi

echo '{"decision": "approve"}'
