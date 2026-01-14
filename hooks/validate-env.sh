#!/bin/bash

# Andrews Plugin - Environment Validation
# Validates environment variables before MCP servers launch
# Can be run manually to diagnose issues: ./validate-env.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Environment variable requirements
# Format: "VAR_NAME:SERVER_NAME:required|optional"
ENV_VARS=(
    # Required for core functionality
    "THINGS_AUTH_TOKEN:SuperThings:required"
    "HUNTER_API_KEY:Hunter:required"
    "TAVILY_API_KEY:Tavily:required"

    # Optional - servers will fail gracefully if missing
    "BROWSERBASE_API_KEY:Browserbase:optional"
    "BROWSERBASE_PROJECT_ID:Browserbase:optional"
    "ZAPIER_MCP_TOKEN:Zapier:optional"
    "LINEAR_ACCESS_TOKEN:Linear:optional"
    "UNIFI_HOST:Unifi:optional"
    "UNIFI_USERNAME:Unifi:optional"
    "UNIFI_PASSWORD:Unifi:optional"
    "GITHUB_PERSONAL_ACCESS_TOKEN:GitHub:optional"
    "SUPABASE_ACCESS_TOKEN:Supabase:optional"
    "VERCEL_API_TOKEN:Vercel:optional"
)

# Track results
MISSING_REQUIRED=()
MISSING_OPTIONAL=()
EMPTY_VARS=()
VALID_VARS=()

check_env_vars() {
    for entry in "${ENV_VARS[@]}"; do
        local var_name="${entry%%:*}"
        local rest="${entry#*:}"
        local server="${rest%%:*}"
        local requirement="${rest#*:}"

        # Check if variable is set
        if [ -z "${!var_name+x}" ]; then
            # Variable is not set at all
            if [ "$requirement" = "required" ]; then
                MISSING_REQUIRED+=("$var_name ($server)")
            else
                MISSING_OPTIONAL+=("$var_name ($server)")
            fi
        elif [ -z "${!var_name}" ]; then
            # Variable is set but empty
            EMPTY_VARS+=("$var_name ($server)")
        else
            # Variable is set and non-empty
            VALID_VARS+=("$var_name ($server)")
        fi
    done
}

# Check for CLAUDE_PLUGIN_ROOT
check_plugin_root() {
    if [ -z "${CLAUDE_PLUGIN_ROOT+x}" ]; then
        echo -e "${YELLOW}Warning: CLAUDE_PLUGIN_ROOT not set${NC}"
        echo "  This is set automatically by Claude Code when loading plugins."
        echo "  If you're running this manually, some paths may not resolve."
        echo ""
        return 1
    fi
    return 0
}

# Check for deep-env
check_deep_env() {
    if command -v deep-env &>/dev/null || [ -f "$HOME/.local/bin/deep-env" ]; then
        return 0
    fi
    return 1
}

print_report() {
    echo ""
    echo -e "${BLUE}======================================================================${NC}"
    echo -e "${BLUE}  Andrews Plugin - Environment Check${NC}"
    echo -e "${BLUE}======================================================================${NC}"
    echo ""

    # Check CLAUDE_PLUGIN_ROOT
    check_plugin_root

    # Required missing (critical)
    if [ ${#MISSING_REQUIRED[@]} -gt 0 ]; then
        echo -e "${RED}Missing Required Variables:${NC}"
        for var in "${MISSING_REQUIRED[@]}"; do
            echo -e "  ${RED}x${NC} $var"
        done
        echo ""
    fi

    # Empty variables (warning)
    if [ ${#EMPTY_VARS[@]} -gt 0 ]; then
        echo -e "${YELLOW}Empty Variables (set but no value):${NC}"
        for var in "${EMPTY_VARS[@]}"; do
            echo -e "  ${YELLOW}!${NC} $var"
        done
        echo ""
    fi

    # Optional missing (info)
    if [ ${#MISSING_OPTIONAL[@]} -gt 0 ]; then
        echo -e "${YELLOW}Missing Optional Variables:${NC}"
        for var in "${MISSING_OPTIONAL[@]}"; do
            echo -e "  ${YELLOW}-${NC} $var"
        done
        echo ""
    fi

    # Valid variables
    if [ ${#VALID_VARS[@]} -gt 0 ]; then
        echo -e "${GREEN}Configured Variables:${NC}"
        for var in "${VALID_VARS[@]}"; do
            echo -e "  ${GREEN}+${NC} $var"
        done
        echo ""
    fi

    # Summary
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    local total=$((${#VALID_VARS[@]} + ${#MISSING_REQUIRED[@]} + ${#MISSING_OPTIONAL[@]} + ${#EMPTY_VARS[@]}))
    echo "  Total: $total variables"
    echo -e "  ${GREEN}Configured: ${#VALID_VARS[@]}${NC}"
    if [ ${#MISSING_REQUIRED[@]} -gt 0 ]; then
        echo -e "  ${RED}Missing Required: ${#MISSING_REQUIRED[@]}${NC}"
    fi
    if [ ${#EMPTY_VARS[@]} -gt 0 ]; then
        echo -e "  ${YELLOW}Empty: ${#EMPTY_VARS[@]}${NC}"
    fi
    echo -e "  ${YELLOW}Missing Optional: ${#MISSING_OPTIONAL[@]}${NC}"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    echo ""

    # Suggestions
    if [ ${#MISSING_REQUIRED[@]} -gt 0 ] || [ ${#EMPTY_VARS[@]} -gt 0 ]; then
        echo -e "${YELLOW}To fix missing variables:${NC}"
        if check_deep_env; then
            echo "  1. Store credentials: deep-env store VAR_NAME \"value\""
            echo "  2. Export to shell: eval \"\$(deep-env export)\""
            echo "  3. Or add to ~/.zshrc: eval \"\$(deep-env export 2>/dev/null)\""
        else
            echo "  1. Install deep-env (credential manager)"
            echo "  2. Or set variables in ~/.zshrc manually"
        fi
        echo ""
    fi

    # Return code based on missing required
    if [ ${#MISSING_REQUIRED[@]} -gt 0 ]; then
        return 1
    fi
    return 0
}

main() {
    check_env_vars
    print_report
}

main "$@"
