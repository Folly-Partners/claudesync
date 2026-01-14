#!/bin/bash

# Andrews Plugin - Smart Setup Wizard
# Runs on SessionStart to ensure everything is configured correctly
# Works on fresh installs AND existing configurations

PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$0")")}"
SETUP_STATE_FILE="$HOME/.claude/.andrews-plugin-setup-state"
LOCK_FILE="$HOME/.claude/.andrews-plugin-setup.lock"
LAUNCHD_PLIST="$HOME/Library/LaunchAgents/com.claude.config-sync.plist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track issues found
ISSUES=()
AUTO_FIXES=()
BUILD_FAILURES=()

# Track current build directory for cleanup on interrupt
BUILDING_DIR=""

# ============================================================================
#  Lock File Management (prevent concurrent runs)
# ============================================================================

acquire_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local lock_pid
        lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
            # Another setup is actually running
            exit 0
        fi
        # Stale lock file from crashed process, remove it
        rm -f "$LOCK_FILE"
    fi
    mkdir -p "$(dirname "$LOCK_FILE")"
    echo $$ > "$LOCK_FILE"
}

release_lock() {
    rm -f "$LOCK_FILE"
}

# ============================================================================
#  Interrupt Handler (clean up partial builds)
# ============================================================================

cleanup_on_interrupt() {
    echo ""
    echo -e "${YELLOW}Interrupted! Cleaning up...${NC}"
    if [ -n "$BUILDING_DIR" ] && [ -d "$BUILDING_DIR" ]; then
        echo -e "  Removing partial build in $BUILDING_DIR"
        rm -rf "$BUILDING_DIR/node_modules" "$BUILDING_DIR/dist" 2>/dev/null
    fi
    release_lock
    exit 130
}

cleanup_on_exit() {
    release_lock
}

# Set up traps
trap cleanup_on_interrupt INT TERM
trap cleanup_on_exit EXIT

# ============================================================================
#  Helper Functions
# ============================================================================

add_issue() {
    ISSUES+=("$1")
}

add_auto_fix() {
    AUTO_FIXES+=("$1")
}

add_build_failure() {
    BUILD_FAILURES+=("$1")
}

# ============================================================================
#  Check Functions
# ============================================================================

check_deep_env() {
    if command -v deep-env &> /dev/null || [ -f "$HOME/.local/bin/deep-env" ]; then
        return 0
    fi

    # Check if available in iCloud
    if [ -f "$HOME/Library/Mobile Documents/com~apple~CloudDocs/.deep-env/deep-env" ]; then
        add_issue "DEEP_ENV_AVAILABLE"
    else
        add_issue "DEEP_ENV_MISSING"
    fi
    return 1
}

check_launchd() {
    if [ -f "$LAUNCHD_PLIST" ]; then
        # Check if loaded
        if launchctl list | grep -q "com.claude.config-sync"; then
            return 0
        fi
        add_issue "LAUNCHD_NOT_LOADED"
        return 1
    fi
    add_issue "LAUNCHD_MISSING"
    return 1
}

check_credentials() {
    if [ -f "$HOME/.local/bin/deep-env" ] || command -v deep-env &> /dev/null; then
        local missing_creds=()

        for key in HUNTER_API_KEY TAVILY_API_KEY THINGS_AUTH_TOKEN; do
            if ! deep-env get "$key" &>/dev/null; then
                missing_creds+=("$key")
            fi
        done

        if [ ${#missing_creds[@]} -gt 0 ]; then
            add_issue "CREDENTIALS_MISSING:${missing_creds[*]}"
        fi
    fi
}

check_shell_config() {
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "deep-env export" "$HOME/.zshrc" 2>/dev/null; then
            add_issue "SHELL_NOT_CONFIGURED"
        fi
    fi
}

check_marketplace() {
    local marketplace_file="$HOME/.claude/plugins/marketplaces/andrews-plugin.json"
    if [ ! -f "$marketplace_file" ]; then
        add_issue "MARKETPLACE_NOT_REGISTERED"
    fi
}

check_every_marketplace() {
    if ! ls "$HOME/.claude/plugins/marketplaces/"*every* &>/dev/null 2>&1; then
        if command -v claude &>/dev/null; then
            if ! claude plugin marketplace list 2>/dev/null | grep -qi "every"; then
                add_issue "EVERY_MARKETPLACE_MISSING"
            fi
        else
            add_issue "EVERY_MARKETPLACE_MISSING"
        fi
    fi
}

check_compound_engineering() {
    if ! ls "$HOME/.claude/plugins/cache/"*every*"/compound-engineering" &>/dev/null 2>&1; then
        add_issue "COMPOUND_ENGINEERING_MISSING"
    fi
}

# Check if SuperThings needs building
check_superthings_build() {
    local server_dir="$PLUGIN_DIR/servers/super-things"
    if [ -d "$server_dir" ]; then
        if [ ! -f "$server_dir/dist/index.js" ]; then
            add_auto_fix "SUPERTHINGS_NOT_BUILT"
        fi
    fi
}

# Check if Unifi venv exists
check_unifi_venv() {
    local server_dir="$PLUGIN_DIR/servers/unifi"
    if [ -d "$server_dir" ]; then
        if [ ! -d "$server_dir/venv" ]; then
            add_auto_fix "UNIFI_VENV_MISSING"
        fi
    fi
}

# ============================================================================
#  Version Check Functions
# ============================================================================

# Check Node.js version for SuperThings
check_node_version() {
    local version
    version=$(node --version 2>/dev/null | sed 's/^v//')

    if [ -z "$version" ]; then
        echo -e "  ${RED}Node.js not found${NC}"
        return 1
    fi

    local major
    major=$(echo "$version" | cut -d. -f1)

    if [ "$major" -lt 18 ]; then
        echo -e "  ${RED}Node.js 18+ required (found v$version)${NC}"
        return 1
    fi

    return 0
}

# Check Python version for Unifi
check_python_version() {
    local version
    version=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)

    if [ -z "$version" ]; then
        echo -e "  ${RED}Python 3 not found${NC}"
        return 1
    fi

    local major minor
    major=$(echo "$version" | cut -d. -f1)
    minor=$(echo "$version" | cut -d. -f2)

    if [ "$major" -lt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -lt 10 ]; }; then
        echo -e "  ${RED}Python 3.10+ required (found $version)${NC}"
        return 1
    fi

    return 0
}

# ============================================================================
#  Build Functions (with proper error handling)
# ============================================================================

# Build SuperThings with step-by-step error handling
build_superthings() {
    local server_dir="$PLUGIN_DIR/servers/super-things"
    local original_dir
    original_dir=$(pwd)

    echo -e "${YELLOW}Building SuperThings MCP server...${NC}"

    # Step 0: Verify directory exists
    if [ ! -d "$server_dir" ]; then
        echo -e "  ${RED}Server directory not found: $server_dir${NC}"
        add_build_failure "SuperThings: directory not found"
        return 1
    fi

    cd "$server_dir" || {
        echo -e "  ${RED}Cannot access server directory${NC}"
        add_build_failure "SuperThings: cannot access directory"
        cd "$original_dir"
        return 1
    }

    # Step 1: Check Node.js version
    echo -e "  ${BLUE}-> Checking Node.js version...${NC}"
    if ! check_node_version; then
        add_build_failure "SuperThings: Node.js 18+ required"
        cd "$original_dir"
        return 1
    fi

    # Mark this directory as being built (for interrupt cleanup)
    BUILDING_DIR="$server_dir"

    # Step 2: npm install
    echo -e "  ${BLUE}-> Installing dependencies...${NC}"
    local npm_output
    if ! npm_output=$(npm install 2>&1); then
        echo -e "  ${RED}npm install failed${NC}"
        echo "$npm_output" | tail -5 | sed 's/^/     /'
        echo -e "  ${YELLOW}-> Run manually: cd $server_dir && npm install${NC}"
        add_build_failure "SuperThings: npm install failed"
        BUILDING_DIR=""
        cd "$original_dir"
        return 1
    fi

    # Step 3: npm run build
    echo -e "  ${BLUE}-> Compiling TypeScript...${NC}"
    local build_output
    if ! build_output=$(npm run build 2>&1); then
        echo -e "  ${RED}Build failed${NC}"
        echo "$build_output" | tail -5 | sed 's/^/     /'
        echo -e "  ${YELLOW}-> Run manually: cd $server_dir && npm run build${NC}"
        add_build_failure "SuperThings: build failed"
        BUILDING_DIR=""
        cd "$original_dir"
        return 1
    fi

    # Clear building marker
    BUILDING_DIR=""

    # Step 4: Verify output exists
    if [ ! -f "$server_dir/dist/index.js" ]; then
        echo -e "  ${RED}Build output missing (dist/index.js)${NC}"
        echo -e "  ${YELLOW}Build completed but output not created${NC}"
        add_build_failure "SuperThings: dist/index.js missing after build"
        cd "$original_dir"
        return 1
    fi

    echo -e "  ${GREEN}SuperThings built successfully${NC}"
    cd "$original_dir"
    return 0
}

# Build Unifi venv with step-by-step error handling
build_unifi_venv() {
    local server_dir="$PLUGIN_DIR/servers/unifi"
    local original_dir
    original_dir=$(pwd)

    echo -e "${YELLOW}Setting up Unifi MCP server...${NC}"

    # Step 0: Verify directory exists
    if [ ! -d "$server_dir" ]; then
        echo -e "  ${RED}Server directory not found: $server_dir${NC}"
        add_build_failure "Unifi: directory not found"
        return 1
    fi

    # Step 1: Check Python version
    echo -e "  ${BLUE}-> Checking Python version...${NC}"
    if ! check_python_version; then
        add_build_failure "Unifi: Python 3.10+ required"
        return 1
    fi

    cd "$server_dir" || {
        echo -e "  ${RED}Cannot access server directory${NC}"
        add_build_failure "Unifi: cannot access directory"
        cd "$original_dir"
        return 1
    }

    # Step 2: Create venv (clean up old one if it exists but is broken)
    echo -e "  ${BLUE}-> Creating virtual environment...${NC}"
    if [ -d "venv" ] && [ ! -f "venv/bin/python" ]; then
        echo -e "  ${YELLOW}Cleaning up broken venv...${NC}"
        rm -rf venv
    fi

    if [ ! -d "venv" ]; then
        local venv_output
        if ! venv_output=$(python3 -m venv venv 2>&1); then
            echo -e "  ${RED}Failed to create venv${NC}"
            echo "$venv_output" | tail -3 | sed 's/^/     /'
            add_build_failure "Unifi: venv creation failed"
            cd "$original_dir"
            return 1
        fi
    fi

    # Step 3: Install dependencies
    echo -e "  ${BLUE}-> Installing fastmcp...${NC}"
    local pip_output
    if ! pip_output=$(./venv/bin/pip install fastmcp 2>&1); then
        echo -e "  ${RED}pip install failed${NC}"
        echo "$pip_output" | tail -5 | sed 's/^/     /'
        echo -e "  ${YELLOW}-> Run manually: cd $server_dir && ./venv/bin/pip install fastmcp${NC}"
        add_build_failure "Unifi: pip install failed"
        cd "$original_dir"
        return 1
    fi

    # Step 4: Verify installation
    if ! ./venv/bin/python -c "import fastmcp" 2>/dev/null; then
        echo -e "  ${RED}fastmcp not importable after install${NC}"
        add_build_failure "Unifi: fastmcp import failed"
        cd "$original_dir"
        return 1
    fi

    echo -e "  ${GREEN}Unifi venv created successfully${NC}"
    cd "$original_dir"
    return 0
}

# ============================================================================
#  Run Checks
# ============================================================================

run_checks() {
    check_deep_env
    check_launchd
    check_credentials
    check_shell_config
    check_marketplace
    check_every_marketplace
    check_compound_engineering
    check_superthings_build
    check_unifi_venv
}

# ============================================================================
#  Auto-Fix (Build servers)
# ============================================================================

run_auto_fixes() {
    if [ ${#AUTO_FIXES[@]} -eq 0 ]; then
        return
    fi

    echo ""
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    echo -e "${BLUE}  Andrews Plugin - Auto-Setup${NC}"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    echo ""

    for fix in "${AUTO_FIXES[@]}"; do
        case "$fix" in
            SUPERTHINGS_NOT_BUILT)
                if ! build_superthings; then
                    add_issue "SUPERTHINGS_BUILD_FAILED"
                fi
                ;;
            UNIFI_VENV_MISSING)
                if ! build_unifi_venv; then
                    add_issue "UNIFI_SETUP_FAILED"
                fi
                ;;
        esac
    done
    echo ""
}

# ============================================================================
#  Check if critical builds are OK
# ============================================================================

critical_builds_ok() {
    # Check SuperThings
    if [ -d "$PLUGIN_DIR/servers/super-things" ] && [ ! -f "$PLUGIN_DIR/servers/super-things/dist/index.js" ]; then
        return 1
    fi

    # Check Unifi
    if [ -d "$PLUGIN_DIR/servers/unifi" ] && [ ! -d "$PLUGIN_DIR/servers/unifi/venv" ]; then
        return 1
    fi

    return 0
}

# ============================================================================
#  Report Status
# ============================================================================

report_status() {
    # Report build failures first
    if [ ${#BUILD_FAILURES[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}----------------------------------------------------------------------${NC}"
        echo -e "${RED}  Build Failures${NC}"
        echo -e "${RED}----------------------------------------------------------------------${NC}"
        echo ""
        for failure in "${BUILD_FAILURES[@]}"; do
            echo -e "  ${RED}x${NC} $failure"
        done
        echo ""
    fi

    # Write state file if critical builds succeeded (even if other issues exist)
    # This prevents re-running full checks every session for non-critical issues
    if critical_builds_ok; then
        mkdir -p "$(dirname "$SETUP_STATE_FILE")"
        echo "$(date +%Y-%m-%d)" > "$SETUP_STATE_FILE"
    fi

    if [ ${#ISSUES[@]} -eq 0 ]; then
        # All good - silent exit
        exit 0
    fi

    echo ""
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    echo -e "${BLUE}  Andrews Plugin Setup${NC}"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    echo ""
    echo -e "${YELLOW}Some components need attention:${NC}"
    echo ""

    for issue in "${ISSUES[@]}"; do
        case "$issue" in
            DEEP_ENV_MISSING)
                echo -e "  ${RED}x${NC} deep-env not found (credential manager)"
                echo -e "    ${YELLOW}-> Install from another Mac or set up fresh${NC}"
                ;;
            DEEP_ENV_AVAILABLE)
                echo -e "  ${YELLOW}!${NC} deep-env available in iCloud but not installed"
                echo -e "    ${GREEN}-> Run: mkdir -p ~/.local/bin && cp ~/Library/Mobile\\ Documents/com~apple~CloudDocs/.deep-env/deep-env ~/.local/bin/ && chmod +x ~/.local/bin/deep-env${NC}"
                ;;
            LAUNCHD_MISSING)
                echo -e "  ${RED}x${NC} Sync agent not installed (auto-sync disabled)"
                echo -e "    ${YELLOW}-> Run: ~/.claude/plugins/andrews-plugin/scripts/setup.sh${NC}"
                ;;
            LAUNCHD_NOT_LOADED)
                echo -e "  ${YELLOW}!${NC} Sync agent installed but not running"
                echo -e "    ${GREEN}-> Run: launchctl load ~/Library/LaunchAgents/com.claude.config-sync.plist${NC}"
                ;;
            CREDENTIALS_MISSING:*)
                local creds="${issue#CREDENTIALS_MISSING:}"
                echo -e "  ${YELLOW}!${NC} Missing credentials: $creds"
                echo -e "    ${GREEN}-> Run: deep-env pull (if synced) or deep-env store KEY VALUE${NC}"
                ;;
            SHELL_NOT_CONFIGURED)
                echo -e "  ${YELLOW}!${NC} Shell not configured for deep-env"
                echo -e "    ${GREEN}-> Add to ~/.zshrc: eval \"\$(deep-env export 2>/dev/null)\"${NC}"
                ;;
            MARKETPLACE_NOT_REGISTERED)
                echo -e "  ${YELLOW}!${NC} Andrews marketplace not registered"
                echo -e "    ${GREEN}-> Run: claude plugin marketplace add https://raw.githubusercontent.com/Folly-Partners/andrews-plugin/main/marketplace.json${NC}"
                ;;
            EVERY_MARKETPLACE_MISSING)
                echo -e "  ${YELLOW}!${NC} Every Inc marketplace not registered"
                echo -e "    ${GREEN}-> Run: claude plugin marketplace add https://github.com/EveryInc/every-marketplace${NC}"
                ;;
            COMPOUND_ENGINEERING_MISSING)
                echo -e "  ${YELLOW}!${NC} Compound Engineering plugin not installed"
                echo -e "    ${GREEN}-> Run: claude plugin install compound-engineering${NC}"
                ;;
            SUPERTHINGS_BUILD_FAILED)
                echo -e "  ${RED}x${NC} SuperThings build failed"
                echo -e "    ${YELLOW}-> Run manually: cd $PLUGIN_DIR/servers/super-things && npm install && npm run build${NC}"
                ;;
            UNIFI_SETUP_FAILED)
                echo -e "  ${RED}x${NC} Unifi setup failed"
                echo -e "    ${YELLOW}-> Run manually: cd $PLUGIN_DIR/servers/unifi && python3 -m venv venv && ./venv/bin/pip install fastmcp${NC}"
                ;;
        esac
        echo ""
    done

    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    echo -e "  Run ${GREEN}/setup${NC} for interactive setup, or fix issues manually above."
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    echo ""
}

# ============================================================================
#  Skip Logic (CRITICAL: Always check builds even if skipping other checks)
# ============================================================================

should_skip() {
    # NEVER skip if critical builds are missing
    if ! critical_builds_ok; then
        return 1  # Don't skip - need to build
    fi

    # Only skip non-critical checks if already checked today
    if [ -f "$SETUP_STATE_FILE" ]; then
        local last_check
        last_check=$(cat "$SETUP_STATE_FILE" 2>/dev/null)
        local today
        today=$(date +%Y-%m-%d)
        if [ "$last_check" = "$today" ]; then
            return 0  # Skip - already checked today and builds are present
        fi
    fi

    return 1  # Don't skip - need to check
}

# ============================================================================
#  Main
# ============================================================================

main() {
    # Acquire lock to prevent concurrent runs
    acquire_lock

    # Allow forcing a full check
    if [ "$1" = "--force" ]; then
        run_checks
        run_auto_fixes
        report_status
        return
    fi

    # Smart skip: always check builds, skip other checks if done today
    if should_skip; then
        exit 0
    fi

    run_checks
    run_auto_fixes
    report_status
}

main "$@"
