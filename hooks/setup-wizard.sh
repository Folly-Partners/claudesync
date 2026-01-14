#!/bin/bash

# Andrews Plugin - Smart Setup Wizard
# Runs on SessionStart to ensure everything is configured correctly
# Works on fresh installs AND existing configurations

PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$0")")}"
SETUP_STATE_FILE="$HOME/.claude/.andrews-plugin-setup-state"
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

# Helper to add issue
add_issue() {
    ISSUES+=("$1")
}

# Helper to add auto-fixable issue
add_auto_fix() {
    AUTO_FIXES+=("$1")
}

# Check deep-env installation
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

# Check launchd sync agent
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

# Check if credentials are synced
check_credentials() {
    if [ -f "$HOME/.local/bin/deep-env" ] || command -v deep-env &> /dev/null; then
        # Check for key credentials
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

# Check .zshrc has deep-env
check_shell_config() {
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "deep-env export" "$HOME/.zshrc" 2>/dev/null; then
            add_issue "SHELL_NOT_CONFIGURED"
        fi
    fi
}

# Check marketplace is registered
check_marketplace() {
    local marketplace_file="$HOME/.claude/plugins/marketplaces/andrews-plugin.json"
    if [ ! -f "$marketplace_file" ]; then
        add_issue "MARKETPLACE_NOT_REGISTERED"
    fi
}

# Check Every Inc marketplace is registered
check_every_marketplace() {
    # Check if every-marketplace exists (could be named differently)
    if ! ls "$HOME/.claude/plugins/marketplaces/"*every* &>/dev/null 2>&1; then
        # Also check via claude CLI if available
        if command -v claude &>/dev/null; then
            if ! claude plugin marketplace list 2>/dev/null | grep -qi "every"; then
                add_issue "EVERY_MARKETPLACE_MISSING"
            fi
        else
            add_issue "EVERY_MARKETPLACE_MISSING"
        fi
    fi
}

# Check Compound Engineering plugin is installed
check_compound_engineering() {
    # Check if plugin is installed
    if ! ls "$HOME/.claude/plugins/cache/"*every*"/compound-engineering" &>/dev/null 2>&1; then
        add_issue "COMPOUND_ENGINEERING_MISSING"
    fi
}

# Check if SuperThings MCP server is built
check_superthings_build() {
    local server_dir="$PLUGIN_DIR/servers/super-things"
    if [ -d "$server_dir" ]; then
        if [ ! -f "$server_dir/dist/index.js" ]; then
            add_auto_fix "SUPERTHINGS_NOT_BUILT"
        fi
    fi
}

# Check if Unifi MCP server venv exists
check_unifi_venv() {
    local server_dir="$PLUGIN_DIR/servers/unifi"
    if [ -d "$server_dir" ]; then
        if [ ! -d "$server_dir/venv" ]; then
            add_auto_fix "UNIFI_VENV_MISSING"
        fi
    fi
}

# Run all checks
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

# Auto-fix issues that can be fixed automatically
run_auto_fixes() {
    if [ ${#AUTO_FIXES[@]} -eq 0 ]; then
        return
    fi

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Andrews Plugin - Auto-Setup${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    for fix in "${AUTO_FIXES[@]}"; do
        case "$fix" in
            SUPERTHINGS_NOT_BUILT)
                echo -e "${YELLOW}Building SuperThings MCP server...${NC}"
                local server_dir="$PLUGIN_DIR/servers/super-things"
                if cd "$server_dir" && npm install --silent 2>/dev/null && npm run build --silent 2>/dev/null; then
                    echo -e "  ${GREEN}✅ SuperThings built successfully${NC}"
                else
                    echo -e "  ${RED}✗ SuperThings build failed${NC}"
                    echo -e "    ${YELLOW}→ Run manually: cd $server_dir && npm install && npm run build${NC}"
                    add_issue "SUPERTHINGS_BUILD_FAILED"
                fi
                ;;
            UNIFI_VENV_MISSING)
                echo -e "${YELLOW}Setting up Unifi MCP server...${NC}"
                local server_dir="$PLUGIN_DIR/servers/unifi"
                if cd "$server_dir" && python3 -m venv venv 2>/dev/null && ./venv/bin/pip install -q fastmcp 2>/dev/null; then
                    echo -e "  ${GREEN}✅ Unifi venv created successfully${NC}"
                else
                    echo -e "  ${RED}✗ Unifi setup failed${NC}"
                    echo -e "    ${YELLOW}→ Run manually: cd $server_dir && python3 -m venv venv && ./venv/bin/pip install fastmcp${NC}"
                    add_issue "UNIFI_SETUP_FAILED"
                fi
                ;;
        esac
    done
    echo ""
}

# Report status
report_status() {
    if [ ${#ISSUES[@]} -eq 0 ]; then
        # All good - silent exit
        # Update state file to skip checks for today
        echo "$(date +%Y-%m-%d)" > "$SETUP_STATE_FILE"
        exit 0
    fi

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Andrews Plugin Setup${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Some components need attention:${NC}"
    echo ""

    for issue in "${ISSUES[@]}"; do
        case "$issue" in
            DEEP_ENV_MISSING)
                echo -e "  ${RED}✗${NC} deep-env not found (credential manager)"
                echo -e "    ${YELLOW}→ Install from another Mac or set up fresh${NC}"
                ;;
            DEEP_ENV_AVAILABLE)
                echo -e "  ${YELLOW}!${NC} deep-env available in iCloud but not installed"
                echo -e "    ${GREEN}→ Run: mkdir -p ~/.local/bin && cp ~/Library/Mobile\\ Documents/com~apple~CloudDocs/.deep-env/deep-env ~/.local/bin/ && chmod +x ~/.local/bin/deep-env${NC}"
                ;;
            LAUNCHD_MISSING)
                echo -e "  ${RED}✗${NC} Sync agent not installed (auto-sync disabled)"
                echo -e "    ${YELLOW}→ Run: ~/.claude/plugins/andrews-plugin/scripts/setup.sh${NC}"
                ;;
            LAUNCHD_NOT_LOADED)
                echo -e "  ${YELLOW}!${NC} Sync agent installed but not running"
                echo -e "    ${GREEN}→ Run: launchctl load ~/Library/LaunchAgents/com.claude.config-sync.plist${NC}"
                ;;
            CREDENTIALS_MISSING:*)
                local creds="${issue#CREDENTIALS_MISSING:}"
                echo -e "  ${YELLOW}!${NC} Missing credentials: $creds"
                echo -e "    ${GREEN}→ Run: deep-env pull (if synced) or deep-env store KEY VALUE${NC}"
                ;;
            SHELL_NOT_CONFIGURED)
                echo -e "  ${YELLOW}!${NC} Shell not configured for deep-env"
                echo -e "    ${GREEN}→ Add to ~/.zshrc: eval \"\$(deep-env export 2>/dev/null)\"${NC}"
                ;;
            MARKETPLACE_NOT_REGISTERED)
                echo -e "  ${YELLOW}!${NC} Andrews marketplace not registered"
                echo -e "    ${GREEN}→ Run: claude plugin marketplace add https://raw.githubusercontent.com/Folly-Partners/andrews-plugin/main/marketplace.json${NC}"
                ;;
            EVERY_MARKETPLACE_MISSING)
                echo -e "  ${YELLOW}!${NC} Every Inc marketplace not registered"
                echo -e "    ${GREEN}→ Run: claude plugin marketplace add https://github.com/EveryInc/every-marketplace${NC}"
                ;;
            COMPOUND_ENGINEERING_MISSING)
                echo -e "  ${YELLOW}!${NC} Compound Engineering plugin not installed"
                echo -e "    ${GREEN}→ Run: claude plugin install compound-engineering${NC}"
                ;;
        esac
        echo ""
    done

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  Run ${GREEN}/setup${NC} for interactive setup, or fix issues manually above."
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Check if we should skip (already checked today)
should_skip() {
    if [ -f "$SETUP_STATE_FILE" ]; then
        local last_check=$(cat "$SETUP_STATE_FILE" 2>/dev/null)
        local today=$(date +%Y-%m-%d)
        if [ "$last_check" = "$today" ]; then
            return 0
        fi
    fi
    return 1
}

# Main
main() {
    # Skip if already checked today (unless forced)
    if [ "$1" != "--force" ] && should_skip; then
        exit 0
    fi

    run_checks
    run_auto_fixes
    report_status
}

main "$@"
