#!/bin/bash

# claudesync - Setup Wizard
# Runs on SessionStart to ensure everything is configured correctly
# Works on fresh installs AND existing configurations

PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$0")")}"
SETUP_STATE_FILE="$HOME/.claude/.claudesync-setup-state"
FIRST_RUN_FLAG="$HOME/.claude/.claudesync-first-run"
LOCK_FILE="$HOME/.claude/.claudesync-setup.lock"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Track issues found
ISSUES=()
AUTO_FIXES=()
BUILD_FAILURES=()

# Track current build directory for cleanup on interrupt
BUILDING_DIR=""

# ============================================================================
#  ASCII Art Banner
# ============================================================================

show_banner() {
    echo ""
    echo -e "${CYAN}"
    cat << 'EOF'
   _____ _                 _      _____
  / ____| |               | |    / ____|
 | |    | | __ _ _   _  __| | ___| (___  _   _ _ __   ___
 | |    | |/ _` | | | |/ _` |/ _ \\___ \| | | | '_ \ / __|
 | |____| | (_| | |_| | (_| |  __/____) | |_| | | | | (__
  \_____|_|\__,_|\__,_|\__,_|\___|_____/ \__, |_| |_|\___|
                                          __/ |
                                         |___/
EOF
    echo -e "${NC}"
    echo -e "  ${BLUE}Sync Claude Code across all your Macs${NC}"
    echo ""
}

# ============================================================================
#  Progress Indicators
# ============================================================================

step_ok() {
    echo -e "  ${GREEN}[✓]${NC} $1"
}

step_fail() {
    echo -e "  ${RED}[✗]${NC} $1"
}

step_warn() {
    echo -e "  ${YELLOW}[!]${NC} $1"
}

step_progress() {
    echo -e "  ${BLUE}[⟳]${NC} $1"
}

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
#  Clean Install (--clean flag)
# ============================================================================

do_clean_install() {
    show_banner

    echo -e "${YELLOW}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│  Fresh Install Mode                                             │${NC}"
    echo -e "${YELLOW}│  This will remove ~/.claude/ and start fresh.                   │${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    echo -e "${BLUE}The following will be removed:${NC}"
    echo "  - ~/.claude/ (settings, caches, plugins)"
    echo ""
    echo -e "${GREEN}The following will be preserved:${NC}"
    echo "  - Keychain credentials (deep-env)"
    echo "  - iCloud backup (deep-env push)"
    echo ""

    # Check if deep-env is available
    if command -v deep-env &> /dev/null || [ -f "$HOME/.local/bin/deep-env" ]; then
        step_progress "Backing up credentials to iCloud..."
        if deep-env push 2>/dev/null; then
            step_ok "Credentials backed up to iCloud"
        else
            step_warn "Credentials backup skipped (may already be synced)"
        fi
    fi

    echo ""
    read -p "Are you sure you want to continue? [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Cancelled.${NC}"
        exit 0
    fi

    echo ""
    step_progress "Removing ~/.claude/..."
    rm -rf "$HOME/.claude"
    step_ok "Removed ~/.claude/"

    step_progress "Creating fresh ~/.claude/..."
    mkdir -p "$HOME/.claude"
    step_ok "Created ~/.claude/"

    # If deep-env was available, pull credentials back
    if command -v deep-env &> /dev/null || [ -f "$HOME/.local/bin/deep-env" ]; then
        step_progress "Restoring credentials from iCloud..."
        if deep-env pull 2>/dev/null; then
            step_ok "Credentials restored"
        else
            step_warn "Credentials restore skipped (enter sync password manually later)"
        fi
    fi

    echo ""
    echo -e "${GREEN}Fresh install complete! Now running normal setup...${NC}"
    echo ""

    # Continue with normal setup
    CLEAN_MODE=true
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

check_marketplace() {
    # Check if claudesync is enabled in settings
    if [ -f "$HOME/.claude/settings.json" ]; then
        if grep -q '"claudesync@Folly"' "$HOME/.claude/settings.json" 2>/dev/null; then
            return 0
        fi
    fi
    add_issue "MARKETPLACE_NOT_REGISTERED"
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

build_superthings() {
    local server_dir="$PLUGIN_DIR/servers/super-things"
    local original_dir
    original_dir=$(pwd)

    step_progress "Building SuperThings MCP server..."

    if [ ! -d "$server_dir" ]; then
        step_fail "Server directory not found: $server_dir"
        add_build_failure "SuperThings: directory not found"
        return 1
    fi

    cd "$server_dir" || {
        step_fail "Cannot access server directory"
        add_build_failure "SuperThings: cannot access directory"
        cd "$original_dir"
        return 1
    }

    # Check Node.js version
    if ! check_node_version; then
        add_build_failure "SuperThings: Node.js 18+ required"
        cd "$original_dir"
        return 1
    fi

    BUILDING_DIR="$server_dir"

    # npm install
    local npm_output
    if ! npm_output=$(npm install 2>&1); then
        step_fail "npm install failed"
        echo "$npm_output" | tail -5 | sed 's/^/     /'
        add_build_failure "SuperThings: npm install failed"
        BUILDING_DIR=""
        cd "$original_dir"
        return 1
    fi

    # npm run build
    local build_output
    if ! build_output=$(npm run build 2>&1); then
        step_fail "Build failed"
        echo "$build_output" | tail -5 | sed 's/^/     /'
        add_build_failure "SuperThings: build failed"
        BUILDING_DIR=""
        cd "$original_dir"
        return 1
    fi

    BUILDING_DIR=""

    if [ ! -f "$server_dir/dist/index.js" ]; then
        step_fail "Build output missing (dist/index.js)"
        add_build_failure "SuperThings: dist/index.js missing after build"
        cd "$original_dir"
        return 1
    fi

    step_ok "SuperThings built successfully"
    cd "$original_dir"
    return 0
}

build_unifi_venv() {
    local server_dir="$PLUGIN_DIR/servers/unifi"
    local original_dir
    original_dir=$(pwd)

    step_progress "Setting up Unifi MCP server..."

    if [ ! -d "$server_dir" ]; then
        step_fail "Server directory not found: $server_dir"
        add_build_failure "Unifi: directory not found"
        return 1
    fi

    if ! check_python_version; then
        add_build_failure "Unifi: Python 3.10+ required"
        return 1
    fi

    cd "$server_dir" || {
        step_fail "Cannot access server directory"
        add_build_failure "Unifi: cannot access directory"
        cd "$original_dir"
        return 1
    }

    # Create venv
    if [ -d "venv" ] && [ ! -f "venv/bin/python" ]; then
        rm -rf venv
    fi

    if [ ! -d "venv" ]; then
        local venv_output
        if ! venv_output=$(python3 -m venv venv 2>&1); then
            step_fail "Failed to create venv"
            add_build_failure "Unifi: venv creation failed"
            cd "$original_dir"
            return 1
        fi
    fi

    # Install dependencies
    local pip_output
    if ! pip_output=$(./venv/bin/pip install fastmcp 2>&1); then
        step_fail "pip install failed"
        add_build_failure "Unifi: pip install failed"
        cd "$original_dir"
        return 1
    fi

    if ! ./venv/bin/python -c "import fastmcp" 2>/dev/null; then
        step_fail "fastmcp not importable after install"
        add_build_failure "Unifi: fastmcp import failed"
        cd "$original_dir"
        return 1
    fi

    step_ok "Unifi venv created successfully"
    cd "$original_dir"
    return 0
}

# ============================================================================
#  Run Checks
# ============================================================================

run_checks() {
    check_deep_env
    check_credentials
    check_marketplace
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
    echo -e "${BLUE}Building MCP servers...${NC}"
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
    if [ -d "$PLUGIN_DIR/servers/super-things" ] && [ ! -f "$PLUGIN_DIR/servers/super-things/dist/index.js" ]; then
        return 1
    fi

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
        echo -e "${RED}Build Failures:${NC}"
        for failure in "${BUILD_FAILURES[@]}"; do
            step_fail "$failure"
        done
        echo ""
    fi

    # Write state file if critical builds succeeded
    if critical_builds_ok; then
        mkdir -p "$(dirname "$SETUP_STATE_FILE")"
        echo "$(date +%Y-%m-%d)" > "$SETUP_STATE_FILE"

        # Create first-run flag for plugin recommendations
        if [ "$CLEAN_MODE" = true ] || [ ! -f "$FIRST_RUN_FLAG.done" ]; then
            touch "$FIRST_RUN_FLAG"
        fi
    fi

    if [ ${#ISSUES[@]} -eq 0 ]; then
        echo ""
        echo -e "${GREEN}============================================${NC}"
        echo -e "${GREEN}  claudesync is ready!${NC}"
        echo -e "${GREEN}============================================${NC}"
        echo ""
        exit 0
    fi

    echo ""
    echo -e "${YELLOW}Some components need attention:${NC}"
    echo ""

    for issue in "${ISSUES[@]}"; do
        case "$issue" in
            DEEP_ENV_MISSING)
                step_fail "deep-env not found (credential manager)"
                echo -e "       ${YELLOW}-> Install from another Mac or set up fresh${NC}"
                ;;
            DEEP_ENV_AVAILABLE)
                step_warn "deep-env available in iCloud but not installed"
                echo -e "       ${GREEN}-> Run: mkdir -p ~/.local/bin && cp ~/Library/Mobile\\ Documents/com~apple~CloudDocs/.deep-env/deep-env ~/.local/bin/ && chmod +x ~/.local/bin/deep-env${NC}"
                ;;
            CREDENTIALS_MISSING:*)
                local creds="${issue#CREDENTIALS_MISSING:}"
                step_warn "Missing credentials: $creds"
                echo -e "       ${GREEN}-> Attempting to pull from iCloud...${NC}"

                # Try to pull credentials automatically
                if deep-env pull 2>&1 | grep -q "Pulled [1-9]"; then
                    step_ok "Credentials synced successfully"

                    # Verify specific credentials are now available
                    local still_missing=()
                    for key in $creds; do
                        if ! deep-env get "$key" &>/dev/null; then
                            still_missing+=("$key")
                        fi
                    done

                    if [ ${#still_missing[@]} -gt 0 ]; then
                        step_warn "Some credentials still missing: ${still_missing[*]}"
                        echo -e "       ${GREEN}-> Run: deep-env store KEY VALUE${NC}"
                    fi
                else
                    step_warn "Auto-sync failed - manual setup required"
                    echo -e "       ${GREEN}-> Try: deep-env pull${NC}"
                    echo -e "       ${GREEN}-> Or: deep-env store KEY VALUE${NC}"
                fi
                ;;
            MARKETPLACE_NOT_REGISTERED)
                step_warn "claudesync not registered in settings"
                echo -e "       ${GREEN}-> Run: /plugin marketplace add Folly-Partners/claudesync${NC}"
                echo -e "       ${GREEN}-> Then: /plugin install claudesync@Folly${NC}"
                ;;
            SUPERTHINGS_BUILD_FAILED)
                step_fail "SuperThings build failed"
                echo -e "       ${YELLOW}-> Run manually: cd $PLUGIN_DIR/servers/super-things && npm install && npm run build${NC}"
                ;;
            UNIFI_SETUP_FAILED)
                step_fail "Unifi setup failed"
                echo -e "       ${YELLOW}-> Run manually: cd $PLUGIN_DIR/servers/unifi && python3 -m venv venv && ./venv/bin/pip install fastmcp${NC}"
                ;;
        esac
        echo ""
    done
}

# ============================================================================
#  Skip Logic
# ============================================================================

should_skip() {
    # NEVER skip if critical builds are missing
    if ! critical_builds_ok; then
        return 1
    fi

    # Only skip if already checked today
    if [ -f "$SETUP_STATE_FILE" ]; then
        local last_check
        last_check=$(cat "$SETUP_STATE_FILE" 2>/dev/null)
        local today
        today=$(date +%Y-%m-%d)
        if [ "$last_check" = "$today" ]; then
            return 0
        fi
    fi

    return 1
}

# ============================================================================
#  Main
# ============================================================================

main() {
    acquire_lock

    # Handle --clean flag
    if [ "$1" = "--clean" ]; then
        do_clean_install
    fi

    # Allow forcing a full check
    if [ "$1" = "--force" ]; then
        show_banner
        run_checks
        run_auto_fixes
        report_status
        return
    fi

    # Smart skip: always check builds, skip other checks if done today
    if should_skip; then
        exit 0
    fi

    # Show banner on first run or if issues found
    if [ ! -f "$SETUP_STATE_FILE" ] || ! critical_builds_ok; then
        show_banner
    fi

    run_checks
    run_auto_fixes
    report_status
}

main "$@"
